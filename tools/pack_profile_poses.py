"""Pack reviewed image-tool side/carry/fallen parts without drawing new pixels.

Run after the legacy walk pass. --check re-packs the published sources in memory;
--before-ref also proves every registered skin is unchanged outside the repair
cells (and unchanged entirely for other families). Requires Pillow, offline only.
"""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / 'docs/profile-pose-repairs.json'


def records():
    return json.loads(REGISTRY.read_text(encoding='utf-8'))['repairs']


def side_position(index, carry=False):
    x, y = (index * 32, 64) if index < 8 else ((index - 8) * 32, 96)
    return x + (256 if carry else 0), y


def regions(record):
    cells = [(x, y, x + 32, y + 32)
            for carry in (False, True) for i in range(10)
            for x, y in [side_position(i, carry)]]
    return cells + ([(192, 128, 256, 192)] if 'fallen' in record else [])


def source_image(record, expected_size):
    path = ROOT / record['path']
    if hashlib.sha256(path.read_bytes()).hexdigest() != record['sha256']:
        raise ValueError(f'Source hash mismatch: {record["path"]}')
    image = Image.open(path).convert('RGBA')
    if image.size != tuple(expected_size):
        raise ValueError(f'Unexpected source dimensions: {record["path"]}')
    # Same binary pixel coverage as pack_selected_sprites; do not retain matte
    # specks at alpha=1. Preserve the source PNG unchanged in docs/art.
    image.putalpha(image.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    return Image.alpha_composite(Image.new('RGBA', image.size), image)


def apply(atlas, key):
    record = next((r for r in records() if r['key'] == key), None)
    if record is None:
        return atlas
    if atlas.size != (512, 512):
        raise ValueError(f'{key}: expected 512x512 atlas')
    out = atlas.convert('RGBA').copy()
    cfg = record['side']
    source = source_image(record['sources'][0], cfg['size'])
    step = cfg['cell_size']
    factor = cfg['scale'][0] / cfg['scale'][1]
    for row, anchors in enumerate(cfg['collar_x']):
        frames = []
        for col, collar in enumerate(anchors):
            source_box = (cfg['source_cells'][row][col] if 'source_cells' in cfg else
                          (col*step, row*step, (col+1)*step, (row+1)*step))
            if not (0 <= source_box[0] < source_box[2] <= source.width
                    and 0 <= source_box[1] < source_box[3] <= source.height):
                raise ValueError(f'{key}: source crop outside image at {row},{col}')
            part = source.crop(source_box)
            box = part.getbbox()
            if (not box or min(box[:2]) <= 0
                    or box[2] >= part.width or box[3] >= part.height):
                raise ValueError(f'{key}: missing transparent source gutter at {row},{col}')
            part = part.crop(box)
            part = part.resize(tuple(round(n*factor) for n in part.size), Image.Resampling.NEAREST)
            # Tail and raised arms must not move the collar off the native head
            # pivot. Use a reviewed collar anchor and one scale across both rows.
            x, y = 16-round((collar-box[0])*factor), cfg['ground']-part.height
            if x <= 0 or y <= 0 or x+part.width >= 32 or y+part.height >= 32:
                raise ValueError(f'{key}: packed part touches cell edge at {row},{col}')
            cell = Image.new('RGBA', (32, 32))
            cell.alpha_composite(part, (x, y))
            frames.append(cell)
        for i, phase in enumerate(cfg['cycle']):
            out.paste(frames[phase], side_position(i, bool(row)))
    if 'fallen' in record:
        cfg = record['fallen']
        part = source_image(record['sources'][1], cfg['size'])
        part = part.crop(part.getbbox())
        part.thumbnail(tuple(cfg['maximum']), Image.Resampling.NEAREST)
        cell = Image.new('RGBA', (64, 64))
        cell.alpha_composite(part, ((64-part.width)//2, cfg['bottom']-part.height))
        out.paste(cell, (192, 128))
    return out


def verify_isolation(before_ref, keys=None):
    repaired = {r['key']: r for r in records() if keys is None or r['key'] in keys}
    players = ET.parse(ROOT / 'content/players.xml').getroot()
    for player in players:
        path = ROOT / 'resources' / players.get('root') / player.get('skin')
        rel = path.relative_to(ROOT).as_posix()
        old = Image.open(BytesIO(subprocess.check_output(
            ['git', 'show', f'{before_ref}:{rel}'], cwd=ROOT))).convert('RGBA')
        new = Image.open(path).convert('RGBA')
        if new.size != old.size:
            raise ValueError(f'{rel}: atlas dimensions changed')
        key = path.stem.removeprefix('character_').removesuffix('_b').removesuffix('chan')
        if key in repaired:
            for box in regions(repaired[key]):
                new.paste(old.crop(box), box[:2])
        if old.tobytes() != new.tobytes():
            raise ValueError(f'{rel}: pixels changed outside allowed profile/fallen cells')
    print(f'PASS: {len(players)} skins retain every pixel outside the repair scope')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--before-ref')
    parser.add_argument('--key', action='append', choices=[r['key'] for r in records()],
                        help='Limit writes and allowed change regions to these families; repeatable')
    args = parser.parse_args()
    manifest_path = ROOT / 'docs/roster-art-manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    for record in records():
        key = record['key']
        if args.key is not None and key not in args.key:
            continue
        target = ROOT / f'resources/gfx/characters/costumes/character_{key}chan.png'
        current = Image.open(target).convert('RGBA')
        rebuilt = apply(current, key)
        if args.check:
            if current.tobytes() != rebuilt.tobytes():
                raise ValueError(f'{key}: packed cells differ from published sources')
        else:
            rebuilt.save(target, optimize=True)
            entry = next(r for r in manifest if r['key'] == key)
            entry['profile_poses'] = 'tools/pack_profile_poses.py'
            entry['packed_sprite_sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
    if not args.check:
        manifest_path.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
        print('Updated normal sheets; regenerate existing tainted skins with --skins-only.')
    if args.before_ref:
        verify_isolation(args.before_ref, args.key)
    print('PASS: reviewed profile/carry/fallen source packing; offline only')


if __name__ == '__main__':
    main()
