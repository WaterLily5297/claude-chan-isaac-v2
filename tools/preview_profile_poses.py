"""Render a compact before/after repair review using private native transforms.

Only mod pixels are rendered. Native animation input stays private; the report
records its hash. No native carried-item artwork, tint or overlays are rendered.
"""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw
from preview_character_poses import ROOT, NAMES, load_animation, active_frames, render

CARRY = ('PickupWalkLeft', 'PickupWalkRight')
SELECTED = (('WalkLeft', 4), ('WalkRight', 4), ('WalkRight', 14),
            ('PickupWalkLeft', 4), ('PickupWalkRight', 14), ('Death', 21), ('Hit', 6))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--animation-reference', type=Path, required=True)
    parser.add_argument('--before-ref', required=True)
    parser.add_argument('--key', default='glm')
    args = parser.parse_args()
    output = args.output.resolve()
    if any(output.is_relative_to(ROOT / p) for p in ('resources', 'content')):
        parser.error('Review output must stay outside shipped assets')
    repairs = json.loads((ROOT / 'docs/profile-pose-repairs.json').read_text())['repairs']
    if args.key not in {r['key'] for r in repairs}:
        parser.error('Select a family with a registered profile repair')
    # The supplied native carry head has one two-tick key. Hold only that
    # explicitly identified static layer; retain strict coverage elsewhere.
    animations = load_animation(args.animation_reference, NAMES + CARRY,
                                hold_static_layers=tuple((name, '4') for name in CARRY))
    output.mkdir(parents=True, exist_ok=True)
    panel = Image.new('RGB', (128 + 192*len(SELECTED), 1150), '#202b3a')
    draw = ImageDraw.Draw(panel)
    draw.text((12, 8), f'{args.key.upper()} profile/carry/fallen repair / mod pixels only / native keyframe transforms', fill='white')
    draw.text((12, 26), 'Native size above; nearest 2x below. Offline only: no item, ghost, tint, costumes or engine effects.', fill='#d2dde8')
    report = {'before_ref': args.before_ref,
              'animation_sha256': hashlib.sha256(args.animation_reference.read_bytes()).hexdigest(),
              'evidence': 'Offline keyframe composition; single carry-head key held for the cycle; not engine acceptance', 'skins': []}
    for form, suffix in enumerate(('', '_b')):
        rel = f'resources/gfx/characters/costumes/character_{args.key}chan{suffix}.png'
        raw_old = subprocess.check_output(['git', 'show', f'{args.before_ref}:{rel}'], cwd=ROOT)
        raw_new = (ROOT / rel).read_bytes()
        report['skins'].append({'path': rel, 'before_sha256': hashlib.sha256(raw_old).hexdigest(),
                               'after_sha256': hashlib.sha256(raw_new).hexdigest()})
        for version, raw in enumerate((raw_old, raw_new)):
            atlas = Image.open(BytesIO(raw)).convert('RGBA')
            row = form*2 + version
            y = 70 + row*270
            draw.text((8, y+48), ('Normal' if not suffix else 'Legacy tainted'), fill='white')
            draw.text((8, y+66), 'Before' if version == 0 else 'After', fill='white')
            for col, (name, time) in enumerate(SELECTED):
                frames = list(active_frames(animations[name], time))
                if name.startswith('Walk'):
                    frames += list(active_frames(animations[name.replace('Walk', 'Head')], 0))
                # Fixed viewport includes the complete mod silhouette for all
                # selected keys; no separate recentering hides anchor changes.
                cell = render(atlas, frames)
                x = 128 + col*192
                if row == 0:
                    draw.text((x, 48), f'{name.replace("PickupWalk", "Carry")} {time}', fill='white')
                panel.paste(cell, (x+48, y), cell)
                zoom = cell.resize((192, 160), Image.Resampling.NEAREST)
                panel.paste(zoom, (x, y+80), zoom)
    panel.save(output / 'glm-profile-review.png')
    (output / 'glm-profile-review.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print('Rendered normal and legacy tainted before/after at native transforms; offline only')


if __name__ == '__main__':
    main()
