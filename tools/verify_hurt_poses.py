"""Verify atlas hurt geometry and make an offline comparison (requires Pillow).

No game assets are changed. Inputs are the reviewed generated source atlases,
the four movement revisions, and an earlier Git revision of this repository.
The measured vanilla Hit contract is documented in MOD_CHARACTER_REFERENCES.md.
This does not simulate costume overlays or establish engine acceptance.
"""
import argparse
from io import BytesIO
import hashlib
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw
from pack_selected_sprites import pack, ORIGINALS
from pack_original_movement import pack as movement
from animate_roster_walk import KEYS as WALK_KEYS, animate

ROOT = Path(__file__).resolve().parent.parent
HIT = (128, 192, 192, 256)


def bounds(image):
    return image.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()


def verify_unchanged(before_ref):
    """Check all 22 Hit cells without the historical thirteen-source rebuild.

    This mode is for non-Hit repairs: it requires byte-identical decoded Hit
    cells and their existing measured geometry. It does not waive the legacy
    mode's outside-Hit isolation assertion or claim a complete atlas rebuild.
    """
    players = ET.parse(ROOT / 'content/players.xml').getroot()
    for player in players:
        path = ROOT / 'resources' / players.get('root') / player.get('skin')
        rel = path.relative_to(ROOT).as_posix()
        old = Image.open(BytesIO(subprocess.check_output(
            ['git', 'show', f'{before_ref}:{rel}'], cwd=ROOT))).convert('RGBA')
        current = Image.open(path).convert('RGBA')
        if old.size != current.size or old.crop(HIT).tobytes() != current.crop(HIT).tobytes():
            raise ValueError(f'{rel}: Hit pixels or atlas size changed')
        box = bounds(current.crop(HIT))
        if not (box and box[2]-box[0] <= 28 and box[3]-box[1] <= 32
                and box[3] == 55 and abs(box[0]+box[2]-64) <= 1):
            raise ValueError(f'{rel}: Hit envelope/anchor changed: {box}')
    print(f'PASS: {len(players)} unchanged Hit cells, envelopes and anchors; no engine acceptance')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path, nargs='?')
    parser.add_argument('movement_source', type=Path, nargs='?')
    parser.add_argument('output', type=Path, nargs='?')
    parser.add_argument('--before-ref')
    parser.add_argument('--unchanged-since', help='Verify all current Hit cells are identical to this ref')
    args = parser.parse_args()
    legacy = (args.source, args.movement_source, args.output, args.before_ref)
    if args.unchanged_since:
        if any(legacy):
            parser.error('--unchanged-since cannot be combined with historical rebuild inputs')
        verify_unchanged(args.unchanged_since)
        return
    if not all(legacy):
        parser.error('Historical mode requires source, movement_source, output and --before-ref')
    manifest = json.loads((ROOT / 'docs/roster-art-manifest.json').read_text())
    players = ET.parse(ROOT / 'content/players.xml').getroot()
    skins = {p.get('skin') for p in players}
    assert len(skins) == len(manifest), 'Every registered skin needs a review record'
    records, failures, pictures = [], [], []
    for record in manifest:
        key = record['key']
        gamekey = key.replace('_b', 'chan_b') if key.endswith('_b') else key + 'chan'
        rel = f'resources/gfx/characters/costumes/character_{gamekey}.png'
        assert Path(rel).name in skins, key
        old_raw = subprocess.check_output(['git', 'show', f'{args.before_ref}:{rel}'], cwd=ROOT)
        raw = (ROOT / rel).read_bytes()
        old = Image.open(BytesIO(old_raw)).convert('RGBA')
        current = Image.open(BytesIO(raw)).convert('RGBA')
        visible = bounds(current.crop(HIT))
        if not visible or visible[2] - visible[0] > 28 or visible[3] - visible[1] > 32:
            failures.append(f'{key}: hurt pose exceeds measured 28x32 envelope: {visible}')
        if visible and (visible[3] != 55 or abs(visible[0] + visible[2] - 64) > 1):
            failures.append(f'{key}: hurt pose misses center/ground anchor: {visible}')
        if key in WALK_KEYS and old.crop((0, 32, 512, 128)).tobytes() != current.crop((0, 32, 512, 128)).tobytes():
            old = animate(old)  # before-ref predates the walk pass; compare the Hit cell only
        restored = current.copy()
        restored.paste(old.crop(HIT), HIT[:2])
        assert restored.tobytes() == old.tobytes(), f'{key}: changed outside Hit cell'
        source = args.source / (key + '.png')
        assert hashlib.sha256(source.read_bytes()).hexdigest() == record['sprite_sha256'], key
        rebuilt = pack(Image.open(source), key)
        if key in ORIGINALS:
            source = args.movement_source / (key + '.png')
            assert hashlib.sha256(source.read_bytes()).hexdigest() == record['movement_source_sha256'], key
            rebuilt = movement(rebuilt, Image.open(source), key)
        elif key in WALK_KEYS:
            rebuilt = animate(rebuilt)
        blob = BytesIO()
        rebuilt.save(blob, format='PNG', optimize=True)
        assert blob.getvalue() == raw, f'{key}: exact atlas rebuild differs'
        assert hashlib.sha256(raw).hexdigest() == record['packed_sprite_sha256'], key
        records.append({'key': key, 'before_bounds': bounds(old.crop(HIT)),
                        'after_bounds': visible, 'only_hit_cell_changed': True,
                        'exact_rebuild': True, 'sha256': record['packed_sprite_sha256']})
        pictures.append((key, old, current))
    assert not failures, '\n'.join(failures)

    args.output.mkdir(parents=True, exist_ok=True)
    # Engineering comparison only. These crops are not new gameplay artwork.
    panel = Image.new('RGB', (840, 70 + len(pictures) * 150), '#172030')
    draw = ImageDraw.Draw(panel)
    draw.text((12, 10), 'Hurt pose: same crop, pivot and zoom; offline only', fill='white')
    for x, title in [(150, 'Before'), (380, 'Corrected'), (610, 'Corrected: 80% x 120%')]:
        draw.text((x, 40), title, fill='#d7e2ef')
    for row, (key, old, current) in enumerate(pictures):
        y = 70 + row * 150
        draw.text((12, y + 60), key, fill='white')
        for column, (atlas, scale) in enumerate([(old, (1, 1)), (current, (1, 1)), (current, (.8, 1.2))]):
            tile = Image.new('RGBA', (96, 72), '#293950')
            guide = ImageDraw.Draw(tile)
            guide.line((0, 60, 95, 60), fill='#718198')
            guide.line((48, 0, 48, 71), fill='#41506a')
            crop = atlas.crop(HIT)
            w, h = round(64 * scale[0]), round(64 * scale[1])
            crop = crop.resize((w, h), Image.Resampling.NEAREST)
            # Hit root: origin + (0,1), crop pivot (32,56), then frame scaling.
            tile.alpha_composite(crop, (48 - round(32 * scale[0]), 61 - round(56 * scale[1])))
            panel.paste(tile.resize((192, 144), Image.Resampling.NEAREST).convert('RGB'), (150 + column * 230, y))
    panel.save(args.output / 'hurt-pose-review.png')
    (args.output / 'hurt-pose-verification.json').write_text(json.dumps({
        'before_ref': args.before_ref, 'scope': 'All registered skins; only Hit cell',
        'evidence': 'Offline alpha bounds, ground anchor, change isolation and exact rebuild; no engine acceptance',
        'records': records}, indent=2) + '\n', encoding='utf-8')
    print(f'PASS: {len(records)} hurt poses, unchanged surrounding pixels and exact rebuilds')


if __name__ == '__main__':
    main()
