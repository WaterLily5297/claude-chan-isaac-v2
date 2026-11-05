"""Approved tainted designs feed the dossier, stage and menu art of their family."""
import json
from pathlib import Path
import sys
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import make_roster_tainted_art as tainted


class ApprovedTaintedTests(unittest.TestCase):
    def setUp(self):
        self.records = json.loads(tainted.MANIFEST.read_text(encoding='utf-8'))['files']
        self.sources = tainted.approved_sources()

    def test_all_nine_families_approved(self):
        self.assertEqual(sorted(self.sources), sorted(tainted.FAMILIES))

    def test_portraits_come_from_approved_sources(self):
        for key, source in self.sources.items():
            rel = source.relative_to(ROOT).as_posix()
            for dst, size in ((f'resources/gfx/ui/dossiers/{key}_b.png', (384, 576)),
                              (f'resources/gfx/ui/stage/playerportrait_{key}chan_b.png', (144, 144))):
                self.assertEqual(self.records[dst]['source'], rel, dst)
                self.assertEqual(Image.open(ROOT / dst).size, size, dst)

    def test_menu_cells_from_approved_sources(self):
        record = self.records['content/gfx/ai_portraits_b.png']
        self.assertEqual(sorted(record['cells_from']),
                         sorted(p.relative_to(ROOT).as_posix() for p in self.sources.values()))
        sheet = Image.open(ROOT / 'content/gfx/ai_portraits_b.png').convert('RGBA')
        for key in tainted.FAMILIES:
            x = tainted.MENU_ORDER.index(key) * tainted.CELL
            self.assertIsNotNone(sheet.crop((x, 0, x + tainted.CELL, tainted.CELL)).getbbox(), key)

    def test_gameplay_skins_untouched_by_approval(self):
        # Full-body illustrations are not sprite sheets: skins stay derived from the normal sheet.
        for key in tainted.FAMILIES:
            dst = f'resources/gfx/characters/costumes/character_{key}chan_b.png'
            self.assertEqual(self.records[dst]['source'],
                             f'resources/gfx/characters/costumes/character_{key}chan.png')

    def test_dossier_wrappers_point_at_tainted_png(self):
        for key in tainted.FAMILIES:
            text = (ROOT / f'resources/gfx/ui/dossiers/{key}_b.anm2').read_text(encoding='utf-8')
            self.assertIn(f'Path="ui/dossiers/{key}_b.png"', text)


if __name__ == '__main__':
    unittest.main()
