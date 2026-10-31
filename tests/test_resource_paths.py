"""Regression tests for resource roots and path-specific resolution rules."""

import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_resource_paths", ROOT / "tools/check_resource_paths.py")
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class ResourcePathTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def put(self, relative, text="asset"):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def test_player_root_attributes_resolve_under_resources(self):
        self.put("content/players.xml", '''<players root="gfx/characters/costumes/" portraitroot="gfx/ui/stage/"
            bigportraitroot="gfx/ui/stage/" nameimageroot="gfx/ui/boss/">
            <player name="Example" skin="body.png" portrait="portrait.png"
                bigportrait="portrait.png" nameimage="name.png" />
        </players>''')
        for path in ("resources/gfx/characters/costumes/body.png", "resources/gfx/ui/stage/portrait.png",
                     "resources/gfx/ui/boss/name.png"):
            self.put(path)
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["player_xml"], 4)

    def test_entity_anm2_path_uses_documented_xml_root(self):
        self.put("content/entities2.xml", '<entities anm2root="gfx/"><entity name="E" anm2path="e.anm2" /></entities>')
        self.put("resources/gfx/e.anm2", '<AnimatedActor><Content><Spritesheets /></Content></AnimatedActor>')
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["rooted_anm2_xml"], 1)

    def test_entity_path_without_root_is_not_guessed(self):
        self.put("content/entities2.xml", '<entities><entity name="E" anm2path="e.anm2" /></entities>')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "has no anm2root"):
            AUDIT.audit(self.root)

    def test_costume_anm2_path_fails_closed_without_a_documented_base(self):
        self.put("content/costumes2.xml", '<costumes anm2root="gfx/"><costume name="C" anm2path="c.anm2" /></costumes>')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "path base is undocumented"):
            AUDIT.audit(self.root)

    def test_anm2_spritesheet_is_relative_to_its_wrapper(self):
        self.put("resources/gfx/wrappers/actor.anm2", '''<AnimatedActor><Content><Spritesheets>
            <Spritesheet Path="sheet.png" Id="0" /></Spritesheets></Content></AnimatedActor>''')
        self.put("resources/gfx/wrappers/sheet.png")
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["anm2_sheets"], 1)

    def test_anm2_gfx_root_prefix_is_not_silently_accepted(self):
        self.put("resources/gfx/wrappers/actor.anm2", '''<AnimatedActor><Content><Spritesheets>
            <Spritesheet Path="gfx/wrappers/sheet.png" Id="0" /></Spritesheets></Content></AnimatedActor>''')
        self.put("resources/gfx/wrappers/sheet.png")
        with self.assertRaisesRegex(AUDIT.PathAuditError, "missing 'gfx'"):
            AUDIT.audit(self.root)

    def test_custom_card_hud_must_exist_in_front_animation(self):
        self.put("content/pocketitems.xml", '<pocketitems><card name="Card" hud="Card Front" /></pocketitems>')
        self.put("content/gfx/ui_cardfronts.anm2", '''<AnimatedActor><Content><Spritesheets /></Content>
            <Animations><Animation Name="Card Front" /></Animations></AnimatedActor>''')
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["pocketitem_links"], 2)

    def test_missing_card_animation_fails(self):
        self.put("content/pocketitems.xml", '<pocketitems><card name="Card" hud="Missing" /></pocketitems>')
        self.put("content/gfx/ui_cardfronts.anm2", '<AnimatedActor><Content><Spritesheets /></Content><Animations /></AnimatedActor>')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "absent from"):
            AUDIT.audit(self.root)

    def test_sprite_load_uses_mod_resource_root_and_case(self):
        self.put("scripts/example.lua", 'sprite:Load("gfx/ui/card.anm2", true)')
        self.put("resources/gfx/ui/card.anm2", '<AnimatedActor><Content><Spritesheets /></Content></AnimatedActor>')
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["lua_resource_loads"], 1)

    def test_replace_spritesheet_checks_second_argument(self):
        self.put("main.lua", 'sprite:ReplaceSpritesheet(0, "gfx/ui/card.png")')
        self.put("resources/gfx/ui/card.png")
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["lua_resource_loads"], 1)

    def test_multiline_load_cannot_hide_a_missing_resource(self):
        self.put("scripts/example.lua", 'sprite\n    :Load\n    (\n        "gfx/missing.anm2", true\n    )')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "missing"):
            AUDIT.audit(self.root)

    def test_concatenation_cannot_validate_only_an_existing_prefix(self):
        self.put("scripts/example.lua", 'sprite:Load("gfx/card.anm2" .. suffix, true)')
        self.put("resources/gfx/card.anm2", '<AnimatedActor />')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "dynamic resource path"):
            AUDIT.audit(self.root)

    def test_comments_and_documentation_strings_are_not_calls(self):
        self.put("scripts/example.lua", '''--[=[
            sprite:Load("missing.anm2", true)
            Isaac.GetItemConfig("not a real call")
        ]=]
        local n = 1 -- sprite:Load("missing.anm2", true)
        local help = [==[sprite:Load("missing.anm2", true)]==]
        local text = 'sprite:Load("missing.anm2", true)'
        sprite:Load(-- comment between call and argument
            "gfx/card.anm2", true)
        ''')
        self.put("resources/gfx/card.anm2", '<AnimatedActor />')
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["lua_resource_loads"], 1)
        self.assertEqual(counts["item_config_calls_without_paths"], 0)

    def test_multiline_replacement_with_comma_in_layer_expression(self):
        self.put("scripts/example.lua", '''sprite:ReplaceSpritesheet(
            chooseLayer(0, 1), -- the path is the second outer argument
            "gfx/card.png")''')
        self.put("resources/gfx/card.png")
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["lua_resource_loads"], 1)

    def test_item_config_is_an_id_api_not_a_resource_loader(self):
        self.put("scripts/config.lua", 'local config = Isaac.GetItemConfig()')
        counts = AUDIT.audit(self.root)
        self.assertEqual(counts["item_config_calls_without_paths"], 1)
        self.put("scripts/invalid.lua", 'local config = Isaac.GetItemConfig("gfx/item.png")')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "takes no path argument"):
            AUDIT.audit(self.root)

    def test_custom_eid_icon_registration_requires_an_explicit_rule(self):
        self.put("scripts/eid.lua", 'EID:addIcon("Example", "gfx/ui/example.png")')
        with self.assertRaisesRegex(AUDIT.PathAuditError, "custom EID icon registration"):
            AUDIT.audit(self.root)

    def test_unsafe_and_case_mismatched_paths_fail(self):
        self.put("resources/gfx/ui/card.anm2")
        with self.assertRaisesRegex(AUDIT.PathAuditError, "case mismatch"):
            AUDIT.require_file(self.root, "resources/Gfx/ui/card.anm2", "test")
        for invalid in ("resources/../private.png", "resources//gfx/ui/card.anm2",
                        "resources/./gfx/ui/card.anm2", "/resources/gfx/ui/card.anm2",
                        "resources/gfx/ui/card:stream.png"):
            with self.subTest(invalid=invalid), self.assertRaisesRegex(AUDIT.PathAuditError, "unsafe|relative"):
                AUDIT.require_file(self.root, invalid, "test")
        with self.assertRaisesRegex(AUDIT.PathAuditError, "relative"):
            AUDIT._joined("resources", "/gfx/ui/")


if __name__ == "__main__":
    unittest.main()
