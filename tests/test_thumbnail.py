"""Check the real thumbnail export, registry boundary and read-only behavior."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import make_item_art as art
import make_thumb as thumb


class ThumbnailTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'content').mkdir()
        (self.root / 'docs/art').mkdir(parents=True)
        (self.root / 'content/items.xml').write_text(
            '<items gfxroot="gfx/items/"><active name="Ban Hammer" '
            'gfx="ban_hammer.png" /></items>', encoding='utf-8')
        (self.root / 'content/itempools.xml').write_text(
            '<ItemPools><Pool Name="treasure"><Item Name="Ban Hammer" /></Pool></ItemPools>', encoding='utf-8')
        self.entry = deepcopy(art.registry(ROOT)[thumb.GFX])
        self.manifest = self.root / art.MANIFEST
        self.save_entry(self.entry)
        self.source = self.root / art.ICON_ROOT / thumb.GFX
        self.source.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / art.ICON_ROOT / thumb.GFX, self.source)
        shutil.copyfile(ROOT / self.entry['contact_sheet'], self.root / self.entry['contact_sheet'])

    def save_entry(self, entry):
        self.manifest.write_text(json.dumps({'schema_version':1, 'entries':[entry]}), encoding='utf-8')

    def cli(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'tools/make_thumb.py'), *args],
                              cwd=self.root, capture_output=True, text=True, encoding='utf-8')

    def test_current_design_scale_colours_and_determinism(self):
        original = self.source.read_bytes()
        output = self.root / 'preview.png'
        thumb.export(output, self.root)
        self.assertEqual(output.read_bytes(), thumb.render(self.root))
        w, h, rows = art.read_rgba(output)
        self.assertEqual((w, h), (512, 512))
        self.assertTrue(all(row[i] == 255 for row in rows for i in range(3, len(row), 4)))
        _, _, source = art.read_rgba(self.source)
        samples = [(x, y) for y in range(32) for x in range(32) if source[y][4*x+3]]
        for x, y in (samples[0], samples[len(samples)//2], samples[-1], (0, 0), (31, 31)):
            pixel = tuple(source[y][4*x:4*x+4])
            expected = pixel if pixel[3] else thumb.BG
            for dx, dy in ((0, 0), (7, 9), (15, 15)):
                xx, yy = x*16+dx, y*16+dy
                self.assertEqual(tuple(rows[yy][4*xx:4*xx+4]), expected)
        self.assertEqual(self.source.read_bytes(), original)

    def test_cli_export_and_read_only_check(self):
        output = self.root / 'nested/preview.png'
        self.assertEqual(self.cli('--out', str(output)).returncode, 0)
        before = output.read_bytes()
        self.assertEqual(self.cli('--out', str(output), '--check').returncode, 0)
        self.assertEqual(output.read_bytes(), before)
        output.write_bytes(b'unchanged sentinel')
        self.assertNotEqual(self.cli('--out', str(output), '--check').returncode, 0)
        self.assertEqual(output.read_bytes(), b'unchanged sentinel')
        missing = self.root / 'missing/preview.png'
        self.assertNotEqual(self.cli('--out', str(missing), '--check').returncode, 0)
        self.assertFalse(missing.parent.exists())

    def test_import_and_missing_output_are_inert(self):
        before = (ROOT / 'thumb.png').read_bytes()
        files = set(self.root.rglob('*'))
        result = subprocess.run([sys.executable, '-c',
            'import sys; sys.path.insert(0, '+repr(str(ROOT / 'tools'))+'); import make_thumb'],
            cwd=self.root, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(self.cli().returncode, 0)
        self.assertEqual(set(self.root.rglob('*')), files)
        self.assertEqual((ROOT / 'thumb.png').read_bytes(), before)

    def test_stale_manifest_or_source_rejected_before_write(self):
        output = self.root / 'existing.png'
        output.write_bytes(b'keep this output')
        entry = deepcopy(self.entry); entry['drawing']['version'] += 1
        self.save_entry(entry)
        with self.assertRaisesRegex(ValueError, 'metadata is stale'):
            thumb.export(output, self.root)
        self.save_entry(self.entry); self.source.write_bytes(b'not the canonical icon')
        with self.assertRaisesRegex(ValueError, 'source icon differs'):
            thumb.export(output, self.root)
        self.assertEqual(output.read_bytes(), b'keep this output')

    def test_output_cannot_overwrite_input_assets_or_use_other_suffix(self):
        source = self.source.read_bytes()
        for path in (self.source, self.root / 'content/example.png',
                     self.root / self.entry['contact_sheet'], self.root / 'example.py'):
            with self.subTest(path=path), self.assertRaises(ValueError):
                thumb.export(path, self.root)
        self.assertEqual(self.source.read_bytes(), source)
        self.assertFalse((self.root / 'content/example.png').exists())
        self.assertFalse((self.root / 'example.py').exists())

    def test_explicit_placeholder_status_uses_its_registered_pixels(self):
        designed = thumb.render(self.root)
        entry = deepcopy(self.entry); entry['status'] = 'placeholder'
        self.save_entry(entry); art.write(self.root)
        placeholder = thumb.render(self.root)
        self.assertNotEqual(placeholder, designed)
        self.assertEqual(art.check(self.root), {'placeholder':1})


if __name__ == '__main__':
    unittest.main()
