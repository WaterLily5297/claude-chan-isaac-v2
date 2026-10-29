"""Derive tainted art for the nine newer roster families by deepening colours.

Usage: python3 tools/make_roster_tainted_art.py [--check | --skins-only]

No pixels are drawn and no shapes change: every output keeps its normal
counterpart's outline, alpha and frame placement, so walk-cycle and hurt-pose
packing carry over. Hue is kept so each tainted form still reads as the
selected identity; colour and pale cloth get darker and skin slightly greyer.
Run it after any change to the normal sheets (e.g. tools/animate_roster_walk.py).

Outputs per family (sizes identical to the inputs):
  resources/gfx/characters/costumes/character_<key>chan_b.png
  resources/gfx/ui/stage/playerportrait_<key>chan_b.png
  resources/gfx/ui/dossiers/<key>_b.png and <key>_b.anm2
  content/gfx/ai_portraits_b.png   (menu cells at the normal sheet's column)
Hashes are recorded in docs/tainted-roster-art-manifest.json; --check only
verifies the recorded hashes against the files on disk.
"""

import colorsys
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "docs/tainted-roster-art-manifest.json"
# Column order of content/gfx/ai_portraits.png (see characterportraits.anm2).
MENU_ORDER = ["claude", "deepseek", "gpt", "gemini", "grok", "qwen", "llama",
              "mistral", "doubao", "kimi", "glm"]
FAMILIES = MENU_ORDER[2:]
CELL = 64


def role(h, s, v):
    if v < 0.18:
        return "outline"
    if 0.02 <= h <= 0.12 and 0.12 <= s <= 0.5 and v >= 0.65:
        return "skin"
    if s < 0.14 and v >= 0.6:
        return "pale"
    return "colour"


def deepen(image):
    out = image.copy()
    px = out.load()
    cache = {}
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            key = (r, g, b)
            if key not in cache:
                h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                kind = role(h, s, v)
                if kind == "skin":
                    s, v = s * 0.75, v * 0.9
                elif kind == "pale":
                    v = v * 0.64
                elif kind == "colour":
                    s, v = min(1.0, s * 1.2), v * 0.62
                nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
                cache[key] = (round(nr * 255), round(ng * 255), round(nb * 255))
            px[x, y] = cache[key] + (a,)
    return out


def outputs():
    pairs = []
    for key in FAMILIES:
        pairs += [
            (f"resources/gfx/characters/costumes/character_{key}chan.png",
             f"resources/gfx/characters/costumes/character_{key}chan_b.png"),
            (f"resources/gfx/ui/stage/playerportrait_{key}chan.png",
             f"resources/gfx/ui/stage/playerportrait_{key}chan_b.png"),
            (f"resources/gfx/ui/dossiers/{key}.png", f"resources/gfx/ui/dossiers/{key}_b.png"),
        ]
    return pairs


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def generate(skins_only=False):
    from PIL import Image
    records = json.loads(MANIFEST.read_text(encoding='utf-8'))['files'] if skins_only else {}
    for src, dst in outputs():
        if skins_only and '/characters/costumes/' not in src:
            continue
        deepen(Image.open(ROOT / src).convert("RGBA")).save(ROOT / dst)
        records[dst] = {"source": src, "source_sha256": sha(ROOT / src), "sha256": sha(ROOT / dst)}
        print(f"wrote {dst}")
    if skins_only:
        MANIFEST.write_text(json.dumps({"tool": "tools/make_roster_tainted_art.py", "files": records},
                                      indent=2) + "\n", encoding='utf-8')
        print('Updated skin hashes; menu and portrait bytes preserved')
        return
    for key in FAMILIES:
        anm2 = (ROOT / f"resources/gfx/ui/dossiers/{key}.anm2").read_text(encoding="utf-8")
        old = f'Path="{key}.png"'
        assert old in anm2, key
        (ROOT / f"resources/gfx/ui/dossiers/{key}_b.anm2").write_text(
            anm2.replace(old, f'Path="{key}_b.png"'), encoding="utf-8")
    # Menu cells: keep the hand-approved tainted Claude/DeepSeek cells untouched.
    menu = Image.open(ROOT / "content/gfx/ai_portraits.png").convert("RGBA")
    alt_path = ROOT / "content/gfx/ai_portraits_b.png"
    alt = Image.open(alt_path).convert("RGBA")
    width = max(alt.width, CELL * len(MENU_ORDER))
    sheet = Image.new("RGBA", (width, alt.height), (0, 0, 0, 0))
    sheet.paste(alt, (0, 0))
    for key in FAMILIES:
        x = MENU_ORDER.index(key) * CELL
        box = (x, 0, x + CELL, CELL)
        sheet.paste(Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0)), box[:2])
        sheet.paste(deepen(menu.crop(box)), box[:2])
    sheet.save(alt_path)
    records["content/gfx/ai_portraits_b.png"] = {"source": "content/gfx/ai_portraits.png",
                                                 "source_sha256": sha(ROOT / "content/gfx/ai_portraits.png"),
                                                 "sha256": sha(alt_path)}
    print("wrote content/gfx/ai_portraits_b.png")
    MANIFEST.write_text(json.dumps({"tool": "tools/make_roster_tainted_art.py", "files": records},
                                   indent=2) + "\n", encoding="utf-8")
    print(f"wrote {MANIFEST.relative_to(ROOT)}")


def check():
    records = json.loads(MANIFEST.read_text(encoding="utf-8"))["files"]
    for dst, record in records.items():
        assert sha(ROOT / record["source"]) == record["source_sha256"], \
            f"{record['source']} changed: rerun tools/make_roster_tainted_art.py"
        assert sha(ROOT / dst) == record["sha256"], f"{dst} differs from its manifest hash"
    print(f"  OK: {len(records)} tainted roster images match their sources and manifest")


if __name__ == "__main__":
    check() if "--check" in sys.argv else generate(skins_only='--skins-only' in sys.argv)
