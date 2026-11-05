"""Exercise the real item-art producer/validator with isolated registries and PNGs.

Fixtures test contract enforcement and safe regeneration, not visual quality.
The designed fixture is a simple original test shape, never shipped game art.
"""
from copy import deepcopy
from dataclasses import replace
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import make_item_art as art
import make_placeholders as legacy


def test_shape():
    pixels = [[(0, 0, 0, 0) for _ in range(32)] for _ in range(32)]
    for y in range(5, 27):
        for x in range(6, 26):
            pixels[y][x] = (8, 0, 0, 255) if x in (6, 25) or y in (5, 26) else (240, 200, 80, 255)
    return pixels


class ItemArtTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'content').mkdir()
        (self.root / 'docs/art').mkdir(parents=True)
        (self.root / 'content/items.xml').write_text('''<items gfxroot="gfx/items/">
<active name="Ban Hammer" gfx="ban_hammer.png" />
<active name="Compact" gfx="compact.png" />
<trinket name="Status Page" gfx="status_page.png" />
</items>''', encoding='utf-8')
        (self.root / 'content/itempools.xml').write_text('''<ItemPools><Pool Name="treasure">
<Item Name="Ban Hammer" /><Item Name="Compact" /></Pool></ItemPools>''', encoding='utf-8')
        self.gfx = 'collectibles/ban_hammer.png'
        self.designs = {self.gfx: art.Design(test_shape, 1, ('#080000', '#f0c850'),
            'Original rectangular test object', 'Test fixture author',
            'Original pixels drawn in test_item_art.py; no external image.', 'docs/art/test-sheet.png')}
        (self.root / 'docs/art/test-sheet.png').write_bytes(art.png_bytes(test_shape()))
        art.initialize(self.root)
        art.write(self.root)

    def load(self):
        return json.loads((self.root / art.MANIFEST).read_text(encoding='utf-8'))

    def save(self, data):
        (self.root / art.MANIFEST).write_text(json.dumps(data), encoding='utf-8')

    def designed(self):
        data = self.load()
        data['entries'][0]['status'] = 'designed'
        self.save(data)
        art.write(self.root, designs=self.designs)

    def mutate_png(self, transform):
        pixels = test_shape()
        transform(pixels)
        (self.root / art.ICON_ROOT / self.gfx).write_bytes(art.png_bytes(pixels))

    def test_repository_partition_and_read_only_check(self):
        manifest = (ROOT / art.MANIFEST).read_bytes()
        before = {p:p.read_bytes() for p in (ROOT / art.ICON_ROOT).rglob('*.png')}
        counts = art.check(ROOT)
        self.assertEqual(sum(counts.values()), len(art.registrations(ROOT)))
        self.assertEqual((ROOT / art.MANIFEST).read_bytes(), manifest)
        self.assertTrue(all(p.read_bytes() == data for p, data in before.items()))

    def test_mixed_registry_accepts_design_without_weakening_placeholders(self):
        before = (self.root / art.ICON_ROOT / 'collectibles/compact.png').read_bytes()
        old = (self.root / art.ICON_ROOT / self.gfx).read_bytes()
        self.designed()
        self.assertEqual(art.check(self.root, self.designs), {'designed': 1, 'placeholder': 2})
        self.assertNotEqual((self.root / art.ICON_ROOT / self.gfx).read_bytes(), old)
        self.assertEqual((self.root / art.ICON_ROOT / 'collectibles/compact.png').read_bytes(), before)
        # Claiming placeholder status must restore the strict legacy comparison.
        data = self.load(); data['entries'][0]['status'] = 'placeholder'; self.save(data)
        with self.assertRaisesRegex(ValueError, 'deterministic producer|Undeclared visible colour'):
            art.check(self.root, self.designs)

    def test_missing_unknown_duplicate_and_mismatched_registry_entries(self):
        original = self.load()
        changes = [
            (lambda d:d['entries'].pop(), 'missing registered'),
            (lambda d:d['entries'].append(deepcopy(d['entries'][0])), 'Duplicate manifest'),
            (lambda d:d['entries'][0].update(gfx='collectibles/not_registered.png'), 'Unknown manifest'),
            (lambda d:d['entries'][0].update(name='Other'), 'name mismatch'),
            (lambda d:d['entries'][0].update(status='approved'), 'unknown artwork status'),
            (lambda d:d.update(schema_version=2), 'Unsupported'),
        ]
        for change, error in changes:
            with self.subTest(error=error):
                data = deepcopy(original); change(data); self.save(data)
                with self.assertRaisesRegex(ValueError, error): art.check(self.root)

    def test_invalid_or_traversing_paths_never_get_written(self):
        original = self.load()
        for path in ('../escaped.png', '/abs.png', 'C:/escaped.png', 'collectibles\\bad.png',
                     'collectibles/../bad.png', 'collectibles//bad.png'):
            with self.subTest(path=path):
                data = deepcopy(original); data['entries'][0]['gfx'] = path; self.save(data)
                with self.assertRaisesRegex(ValueError, 'Invalid icon path'): art.write(self.root)

    def test_registration_duplicates_and_wrong_kind_rejected(self):
        path = self.root / 'content/items.xml'
        original = path.read_text(encoding='utf-8')
        for changed, error in (
            (original.replace('name="Compact"', 'name="Ban Hammer"'), 'Duplicate'),
            (original.replace('gfx="compact.png"', 'gfx="ban_hammer.png"'), 'Duplicate'),
            # A folder in the XML value doubles the engine's own folder.
            (original.replace('gfx="compact.png"', 'gfx="collectibles/compact.png"'), 'bare file name'),
            (original.replace('gfx="status_page.png"', 'gfx="trinkets/status_page.png"'), 'bare file name')):
            with self.subTest(error=error):
                path.write_text(changed, encoding='utf-8')
                with self.assertRaisesRegex(ValueError, error): art.check(self.root)

    def test_pool_names_must_be_registered_collectibles(self):
        path = self.root / 'content/itempools.xml'
        for name in ('Typo', 'Status Page'):
            with self.subTest(name=name):
                path.write_text(f'<ItemPools><Pool><Item Name="{name}" /></Pool></ItemPools>', encoding='utf-8')
                with self.assertRaisesRegex(ValueError, 'Undefined collectible pool'): art.check(self.root)

    def test_files_must_partition_registration(self):
        path = self.root / art.ICON_ROOT / self.gfx
        original = path.read_bytes(); path.unlink()
        with self.assertRaisesRegex(ValueError, 'Missing or unregistered'): art.check(self.root)
        path.write_bytes(original)
        (path.parent / 'unknown.png').write_bytes(original)
        with self.assertRaisesRegex(ValueError, 'Missing or unregistered'): art.check(self.root)

    def test_dimensions_and_colour_type_are_checked(self):
        self.designed()
        path = self.root / art.ICON_ROOT / self.gfx
        path.write_bytes(art.png_bytes([row[:-1] for row in test_shape()]))
        with self.assertRaisesRegex(ValueError, 'expected 32x32'): art.check(self.root, self.designs)
        data = bytearray(art.png_bytes(test_shape())); data[25] = 2; path.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'expected RGBA8'): art.check(self.root, self.designs)

    def test_empty_opaque_alpha_palette_and_margin_candidates_rejected(self):
        self.designed()
        changes = [
            (lambda p:p.__setitem__(slice(None), [[(0,0,0,0)]*32 for _ in range(32)]), 'Empty icon'),
            (lambda p:p.__setitem__(slice(None), [[(8,0,0,255)]*32 for _ in range(32)]), 'Opaque icon'),
            (lambda p:p[10].__setitem__(10, (8,0,0,128)), 'Undeclared alpha'),
            (lambda p:p[10].__setitem__(10, (255,0,0,255)), 'Undeclared visible colour'),
            (lambda p:p[0].__setitem__(16, (8,0,0,255)), 'transparent outer margin'),
        ]
        for transform, error in changes:
            with self.subTest(error=error):
                self.mutate_png(transform)
                with self.assertRaisesRegex(ValueError, error): art.check(self.root, self.designs)

    def test_stale_png_and_metadata_cannot_be_blessed_by_hash_only(self):
        self.designed()
        self.mutate_png(lambda p:p[10].__setitem__(10, (8,0,0,255)))
        data = self.load()
        data['entries'][0]['sha256'] = art.hashlib.sha256((self.root / art.ICON_ROOT / self.gfx).read_bytes()).hexdigest()
        self.save(data)
        with self.assertRaisesRegex(ValueError, 'deterministic producer'): art.check(self.root, self.designs)
        art.write(self.root, designs=self.designs)
        for field in ('sha256', 'author', 'description', 'provenance', 'license'):
            with self.subTest(field=field):
                data = self.load(); data['entries'][0][field] = 'stale'; self.save(data)
                with self.assertRaisesRegex(ValueError, 'metadata/hash'): art.check(self.root, self.designs)
                art.write(self.root, designs=self.designs)

    def test_missing_producer_provenance_palette_and_contact_fail_before_writes(self):
        data = self.load(); data['entries'][0]['status'] = 'designed'; self.save(data)
        before = {p:p.read_bytes() for p in (self.root / art.ICON_ROOT).rglob('*.png')}
        with self.assertRaisesRegex(ValueError, 'missing designed producer'): art.write(self.root, designs={})
        candidates = [
            (replace(self.designs[self.gfx], author=''), 'provenance'),
            (replace(self.designs[self.gfx], palette=('#080000',)), 'Undeclared visible colour'),
            (replace(self.designs[self.gfx], palette=('#bad',)), 'Invalid declared palette'),
            (replace(self.designs[self.gfx], palette=tuple(f'#{n:06x}' for n in range(17))), '16 declared colours'),
            (replace(self.designs[self.gfx], contact_sheet='docs/art/missing.png'), 'Missing contact sheet'),
            (replace(self.designs[self.gfx], contact_sheet='docs/art/../../secret.png'), 'repository path'),
            (replace(self.designs[self.gfx], version=0), 'drawing version'),
        ]
        for candidate, error in candidates:
            with self.subTest(error=error):
                with self.assertRaisesRegex(ValueError, error): art.write(self.root, designs={self.gfx:candidate})
                self.assertTrue(all(p.read_bytes() == data for p,data in before.items()))

    def test_export_and_reinitialization_cannot_overwrite_registry(self):
        self.designed()
        before = (self.root / art.MANIFEST).read_bytes()
        with self.assertRaisesRegex(ValueError, 'already exists'): art.initialize(self.root)
        with self.assertRaisesRegex(ValueError, 'canonical icons'):
            art.write(self.root, self.root / art.ICON_ROOT, self.designs)
        out = self.root / 'export'
        art.write(self.root, out, self.designs)
        self.assertEqual((self.root / art.MANIFEST).read_bytes(), before)
        self.assertEqual((out / self.gfx).read_bytes(), art.png_bytes(test_shape()))

    def test_legacy_default_and_explicit_canonical_export_preserve_designed_bytes(self):
        self.designed()
        before = (self.root / art.ICON_ROOT / self.gfx).read_bytes()
        for args in ([], ['--out', str(self.root / art.ICON_ROOT)]):
            with patch.object(legacy, 'ROOT', self.root), patch.object(sys, 'argv', ['make_placeholders.py', *args]), \
                    patch('builtins.print'):
                legacy.main()
            self.assertEqual((self.root / art.ICON_ROOT / self.gfx).read_bytes(), before)
            self.assertEqual(art.check(self.root, self.designs), {'designed':1,'placeholder':2})


if __name__ == '__main__':
    unittest.main()
