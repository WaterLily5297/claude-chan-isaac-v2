"""Audit mod-owned resource paths without relying on Windows case folding."""

import argparse
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET


LUA_CALL = re.compile(r"(?P<receiver>[A-Za-z_]\w*)\s*:\s*(?P<method>Load|ReplaceSpritesheet)\s*\(")
LUA_STRING = re.compile(r"\s*(['\"])([^'\"\\\r\n]*)\1\s*(?=[,)])")
LUA_NONCODE = re.compile(
    r"--\[(?P<comment_eq>=*)\[.*?\](?P=comment_eq)\]"
    r"|--[^\r\n]*"
    r'|"(?:\\.|[^"\\])*"'
    r"|'(?:\\.|[^'\\])*'"
    r"|\[(?P<string_eq>=*)\[.*?\](?P=string_eq)\]",
    re.S,
)
ITEM_CONFIG_CALL = re.compile(r"\bIsaac\s*\.\s*GetItemConfig\s*\(")


class PathAuditError(AssertionError):
    pass


def _parts(value, label, *, allow_empty=False, allow_trailing_slash=False):
    if value == "" and allow_empty:
        return ()
    if not value or "\\" in value or value.startswith("/"):
        raise PathAuditError(f"{label}: expected a non-empty relative path using '/': {value!r}")
    raw_parts = value.split("/")
    if allow_trailing_slash and raw_parts[-1] == "":
        raw_parts.pop()
    if (not raw_parts or any(part in {"", "..", "."} for part in raw_parts)
            or any(":" in part for part in raw_parts)):
        raise PathAuditError(f"{label}: unsafe or absolute path: {value!r}")
    return tuple(raw_parts)


def require_file(root, relative, label):
    """Require an exact-case file path beneath root; return its resolved Path."""
    root = Path(root).resolve()
    parts = _parts(relative, label)
    current = root
    for part in parts:
        if not current.is_dir():
            raise PathAuditError(f"{label}: parent directory is missing: {current}")
        names = {entry.name for entry in current.iterdir()}
        if part not in names:
            nearby = next((name for name in names if name.casefold() == part.casefold()), None)
            hint = f" (case mismatch: {nearby!r})" if nearby else ""
            shown = current.relative_to(root).as_posix()
            raise PathAuditError(f"{label}: missing {part!r} under {shown!r}{hint}")
        current = current / part
    resolved = current.resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise PathAuditError(f"{label}: resource resolves outside the repository: {relative!r}") from exc
    if not resolved.is_file():
        raise PathAuditError(f"{label}: not a file: {relative!r}")
    return resolved


def _joined(*values):
    parts = []
    for index, value in enumerate(values):
        if value == "" and 0 < index < len(values) - 1:
            continue
        parts.extend(_parts(value, "resource path", allow_trailing_slash=index < len(values) - 1))
    return "/".join(parts)


def _parse_xml(path, label):
    try:
        return ET.parse(path).getroot()
    except (ET.ParseError, OSError) as exc:
        raise PathAuditError(f"{label}: cannot parse XML: {exc}") from exc


def _check_players(root):
    path = root / "content" / "players.xml"
    if not path.is_file():
        return 0
    xml = _parse_xml(path, "content/players.xml")
    rules = (
        ("skin", "root"),
        ("portrait", "portraitroot"),
        ("bigportrait", "bigportraitroot"),
        ("nameimage", "nameimageroot"),
    )
    count = 0
    for player in xml.iter("player"):
        name = player.get("name", "<unnamed player>")
        for asset_attr, prefix_attr in rules:
            value = player.get(asset_attr)
            if value is None:
                continue
            prefix = xml.get(prefix_attr)
            if prefix is None:
                raise PathAuditError(f"content/players.xml: {asset_attr} on {name} has no {prefix_attr}")
            require_file(root, _joined("resources", prefix, value), f"players.xml {asset_attr} ({name})")
            count += 1
        extra = player.get("extraportrait")
        if extra:
            raise PathAuditError(
                f"players.xml extraportrait ({name}): the path base is undocumented; add an explicit rule first"
            )
    return count


def _check_rooted_anm2_xml(root, filename, entry_path):
    path = root / "content" / filename
    if not path.is_file():
        return 0
    xml = _parse_xml(path, f"content/{filename}")
    prefix = xml.get("anm2root")
    count = 0
    for element in xml.iter():
        value = element.get(entry_path)
        if value:
            if prefix is None:
                raise PathAuditError(f"content/{filename}: {entry_path} has no anm2root")
            label = element.get("name") or element.tag
            require_file(root, _joined("resources", prefix, value), f"{filename} {entry_path} ({label})")
            count += 1
    return count


def _check_unrooted_xml_paths(root, filename, entry_path):
    path = root / "content" / filename
    if not path.is_file():
        return 0
    xml = _parse_xml(path, f"content/{filename}")
    if any(element.get(entry_path) for element in xml.iter()):
        raise PathAuditError(
            f"content/{filename}: {entry_path} path base is undocumented; add an explicit rule after verification"
        )
    return 0


def _check_pocketitems(root):
    path = root / "content" / "pocketitems.xml"
    if not path.is_file():
        return 0
    xml = _parse_xml(path, "content/pocketitems.xml")
    cards = list(xml.iter("card"))
    if not cards:
        return 0
    wrapper_rel = "content/gfx/ui_cardfronts.anm2"
    wrapper = require_file(root, wrapper_rel, "custom card HUD wrapper")
    actor = _parse_xml(wrapper, wrapper_rel)
    animations = {animation.get("Name") for animation in actor.findall("./Animations/Animation")}
    count = 1
    for card in cards:
        hud = card.get("hud")
        if not hud:
            raise PathAuditError(f"pocketitems.xml: custom card {card.get('name')!r} has no hud animation name")
        if hud not in animations:
            raise PathAuditError(f"pocketitems.xml: HUD animation {hud!r} is absent from {wrapper_rel}")
        count += 1
    return count


def _is_skipped(relative, prefixes):
    return any(relative == prefix or relative.startswith(prefix.rstrip("/") + "/") for prefix in prefixes)


def _check_anm2(root, skip_prefixes):
    count = skipped = 0
    for area in ("content", "resources"):
        for path in sorted((root / area).rglob("*.anm2")):
            relative = path.relative_to(root).as_posix()
            if _is_skipped(relative, skip_prefixes):
                skipped += 1
                continue
            actor = _parse_xml(path, relative)
            for sheet in actor.findall("./Content/Spritesheets/Spritesheet"):
                value = sheet.get("Path")
                if not value:
                    raise PathAuditError(f"{relative}: Spritesheet is missing Path")
                # The project audit plan treats each spritesheet path as relative
                # to its own ANM2 file, unlike the published gfx/-root rule.
                # This is an offline existence candidate, not engine acceptance.
                # Defer v2 PR #2 dossiers until the rule is reconciled and tested.
                base = path.parent.relative_to(root).as_posix()
                require_file(root, _joined(base, value), f"{relative} Spritesheet Path")
                count += 1
    return count, skipped


def _check_font_candidates(path, source):
    block = re.search(r"local\s+FONT_CANDIDATES\s*=\s*\{(.*?)\}", source, re.S)
    if not block:
        raise PathAuditError(f"{path}: dynamic Font:Load candidate list is not recognized")
    candidates = re.findall(r"['\"]([^'\"]+)['\"]", block.group(1))
    if not candidates:
        raise PathAuditError(f"{path}: no font candidates found")
    for candidate in candidates:
        parts = _parts(candidate, "Font:Load candidate")
        if not parts or parts[0] != "font" or not candidate.endswith(".fnt"):
            raise PathAuditError(f"{path}: unexpected game-resource font path: {candidate!r}")
    return len(candidates)


def _check_dossier_load(root, source_path, argument):
    if not re.match(r"\s*['\"]gfx/ui/dossiers/['\"]\s*\.\.\s*def\s*\.\s*key\s*\.\.\s*['\"]\.anm2['\"]\s*(?=[,)])", argument):
        raise PathAuditError(f"{source_path}: dynamic dossier Sprite:Load path is not recognized")
    manifest = root / "docs" / "portrait-prompts.json"
    entries = json.loads(manifest.read_text(encoding="utf-8"))["entries"]
    keys = {entry["key"] for entry in entries}
    expected = keys | {key + "_b" for key in keys}
    for key in expected:
        require_file(root, f"resources/gfx/ui/dossiers/{key}.anm2", f"dossier Sprite:Load ({key})")
    return len(expected)


def _lua_source_views(source):
    """Keep offsets/newlines while masking comments, then comments and strings."""
    clean, code = [], []
    offset = 0
    for match in LUA_NONCODE.finditer(source):
        clean.append(source[offset:match.start()])
        code.append(source[offset:match.start()])
        value = match.group(0)
        blank = re.sub(r"[^\r\n]", " ", value)
        clean.append(blank if value.startswith("--") else value)
        code.append(blank)
        offset = match.end()
    clean.append(source[offset:])
    code.append(source[offset:])
    return "".join(clean), "".join(code)


def _next_lua_argument(code, offset, label):
    """Find the next outer argument, ignoring nested layer-index expressions."""
    closers = {"(": ")", "[": "]", "{": "}"}
    stack = []
    for index in range(offset, len(code)):
        char = code[index]
        if char in closers:
            stack.append(closers[char])
        elif char in ")]}":
            if not stack or stack.pop() != char:
                break
        elif char == "," and not stack:
            return index + 1
    raise PathAuditError(f"{label}: missing spritesheet path argument")


def _check_lua_calls(root):
    checked = external_fonts = dossier_sprites = item_config_calls = 0
    lua_paths = ([root / "main.lua"] if (root / "main.lua").is_file() else [])
    lua_paths.extend(sorted((root / "scripts").rglob("*.lua")))
    for path in lua_paths:
        relative = path.relative_to(root).as_posix()
        source = path.read_text(encoding="utf-8")
        clean, code = _lua_source_views(source)
        for match in ITEM_CONFIG_CALL.finditer(code):
            if not re.match(r"\s*\)", clean[match.end():]):
                raise PathAuditError(f"{relative}: Isaac.GetItemConfig takes no path argument")
            item_config_calls += 1
        for match in LUA_CALL.finditer(code):
            receiver, method = match.group("receiver"), match.group("method")
            if receiver == "Risk" and method == "Load":
                continue  # Risk:Load restores saved state; it is not a graphics loader.
            line_number = source.count("\n", 0, match.start()) + 1
            label = f"{relative}:{line_number} {receiver}:{method}"
            offset = match.end()
            if method == "ReplaceSpritesheet":
                offset = _next_lua_argument(code, offset, label)
            argument = clean[offset:]
            literal = LUA_STRING.match(argument)
            is_dossier = (relative == "scripts/characters/dossiers.lua" and receiver == "sprite"
                          and method == "Load")
            if literal:
                resource = literal.group(2)
                require_file(root, _joined("resources", resource), label)
                checked += 1
            elif is_dossier:
                dossier_sprites += _check_dossier_load(root, relative, argument)
            elif relative == "scripts/hud_text.lua" and receiver == "f" and method == "Load":
                external_fonts += _check_font_candidates(relative, clean)
            else:
                raise PathAuditError(f"{label}: dynamic resource path needs an explicit rule")
    return checked, external_fonts, dossier_sprites, item_config_calls


def _check_eid_icon_paths(root):
    path = root / "scripts" / "eid.lua"
    if not path.is_file():
        return 0
    _, source = _lua_source_views(path.read_text(encoding="utf-8"))
    icon_registrations = re.findall(
        r"\bEID\s*[:.]\s*(?:add|register|set)[A-Za-z_]*[Ii]con\s*\(", source
    )
    if icon_registrations:
        raise PathAuditError(
            "scripts/eid.lua: custom EID icon registration needs an explicit path rule"
        )
    return len(icon_registrations)


def audit(root, skip_prefixes=()):
    root = Path(root).resolve()
    player_refs = _check_players(root)
    rooted_refs = _check_rooted_anm2_xml(root, "entities2.xml", "anm2path")
    _check_unrooted_xml_paths(root, "costumes2.xml", "anm2path")
    pocket_refs = _check_pocketitems(root)
    anm2_refs, skipped = _check_anm2(root, skip_prefixes)
    lua_refs, fonts, dossiers, item_config_calls = _check_lua_calls(root)
    eid_icons = _check_eid_icon_paths(root)
    return {
        "player_xml": player_refs,
        "rooted_anm2_xml": rooted_refs,
        "pocketitem_links": pocket_refs,
        "anm2_sheets": anm2_refs,
        "lua_resource_loads": lua_refs,
        "engine_font_candidates": fonts,
        "dossier_load_targets": dossiers,
        "item_config_calls_without_paths": item_config_calls,
        "eid_custom_icon_registrations": eid_icons,
        "skipped_anm2": skipped,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--skip-prefix", action="append", default=[],
                        help="defer an ANM2 subtree owned by an open PR; repeat as needed")
    args = parser.parse_args()
    try:
        counts = audit(args.root, args.skip_prefix)
    except (PathAuditError, KeyError, json.JSONDecodeError) as exc:
        print(f"Resource path audit failed: {exc}")
        return 1
    print("Resource path audit passed:")
    for key, value in counts.items():
        print(f"  {key}: {value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
