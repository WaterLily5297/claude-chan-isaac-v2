"""The install package carries every file the game loads and nothing else."""
import os
from pathlib import Path
import re
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import package_mod as pkg

INCLUDE = re.compile(r'''\binclude\(\s*["']([A-Za-z0-9_.]+)["']\s*\)''')


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = pkg.package_files()
        cls.set = set(cls.files)

    def test_folder_name_matches_installed_mod(self):
        self.assertEqual(pkg.folder_name(), 'claude-chan-isaac')

    def test_runtime_entry_points_present(self):
        for path in ('main.lua', 'metadata.xml', 'LICENSE', 'resources/ART_LICENSE.md',
                     'content/items.xml', 'content/players.xml'):
            self.assertIn(path, self.set)

    def test_development_files_left_out(self):
        for path in self.files:
            self.assertFalse(path.startswith(('docs/', 'tools/', '.github/')), path)
            if path.startswith('tests/'):
                self.assertEqual(path, 'tests/runtime_probe.lua')
            self.assertNotIn('__pycache__', path)

    def test_every_include_resolves_inside_package(self):
        lua = [p for p in self.files if p.endswith('.lua')]
        seen = 0
        for path in lua:
            source = (ROOT / path).read_text(encoding='utf-8')
            for module in INCLUDE.findall(source):
                seen += 1
                self.assertIn(module.replace('.', '/') + '.lua', self.set, f'{path} includes {module}')
        self.assertGreater(seen, 100)

    def test_player_sheets_resolve_inside_package(self):
        players = ET.parse(ROOT / 'content/players.xml').getroot()
        roots = {'skin': players.get('root'), 'portrait': players.get('portraitroot'),
                 'bigportrait': players.get('bigportraitroot'), 'nameimage': players.get('nameimageroot')}
        for player in players:
            for attr, base in roots.items():
                name = player.get(attr)
                if name:
                    self.assertIn('resources/' + base + name, self.set, f'{player.get("name")} {attr}')

    def test_item_icons_inside_package(self):
        # Either gfx form (category-relative or with the category folder) must
        # name a packaged PNG under the category folder the engine routes to.
        items = ET.parse(ROOT / 'content/items.xml').getroot()
        for el in items:
            gfx = el.get('gfx')
            if gfx:
                folder = 'trinkets' if el.tag == 'trinket' else 'collectibles'
                path = f'resources/gfx/items/{folder}/{os.path.basename(gfx)}'
                self.assertIn(path, self.set, el.get('name'))

    def test_zip_is_reproducible_and_rooted(self):
        with tempfile.TemporaryDirectory() as temp:
            a = pkg.write_zip(os.path.join(temp, 'a.zip'))
            b = pkg.write_zip(os.path.join(temp, 'b.zip'))
            self.assertEqual(Path(a).read_bytes(), Path(b).read_bytes())
            with zipfile.ZipFile(a) as zf:
                names = zf.namelist()
            self.assertEqual(len(names), len(self.files))
            self.assertTrue(all(n.startswith('claude-chan-isaac/') for n in names))
            self.assertIn('claude-chan-isaac/main.lua', names)
            out = pkg.write_dir(os.path.join(temp, 'claude-chan-isaac'))
            self.assertTrue(os.path.isfile(os.path.join(out, 'tests', 'runtime_probe.lua')))


if __name__ == '__main__':
    unittest.main()
