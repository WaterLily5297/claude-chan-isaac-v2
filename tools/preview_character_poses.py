"""Render all registered skins at native keyframe transforms (requires Pillow).

Supply a privately extracted base player ANM2. Optional --reference-skin adds
geometry measurements only; its pixels are never rendered or copied. Outputs
are review artifacts, not shipped assets or evidence of engine acceptance.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
NAMES = ('Hit', 'Death', 'WalkLeft', 'WalkRight', 'HeadLeft', 'HeadRight')
SIZE = (96, 80)
ORIGIN = (40, 64)
TILE = (96, 100)


def bounds(im):
    return im.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()


def load_animation(path, names=NAMES, hold_static_layers=()):
    root = ET.parse(path).getroot()
    sheets = {l.get('Id'): l.get('SpritesheetId') for l in root.findall('Content/Layers/Layer')}
    animations = {}
    for animation in root.findall('Animations/Animation'):
        name = animation.get('Name')
        if name not in names:
            continue
        # Fail explicitly on an unsupported root rather than silently misalign.
        for f in animation.findall('RootAnimation/Frame'):
            for k, expected in [('XPosition', 0), ('YPosition', 0), ('XPivot', 0),
                                ('YPivot', 0), ('XScale', 100), ('YScale', 100),
                                ('Rotation', 0), ('AlphaTint', 255), ('RedTint', 255),
                                ('GreenTint', 255), ('BlueTint', 255), ('RedOffset', 0),
                                ('GreenOffset', 0), ('BlueOffset', 0)]:
                if float(f.get(k, expected)) != expected or f.get('Visible') != 'true':
                    raise ValueError(f'{name}: unsupported root transform')
        layers = []
        for layer in animation.findall('LayerAnimations/LayerAnimation'):
            if layer.get('Visible') != 'true':
                continue
            if not any(f.get('Visible') == 'true' for f in layer.findall('Frame')):
                continue
            elapsed, frames = 0, []
            for f in layer.findall('Frame'):
                data = dict(f.attrib)
                delay = int(data['Delay'])
                if delay <= 0:
                    raise ValueError(f'{name}: nonpositive frame delay')
                frames.append((elapsed, data))
                elapsed += delay
            held = ((name, layer.get('LayerId')) in hold_static_layers
                    and len(frames) == 1 and elapsed <= int(animation.get('FrameNum')))
            if elapsed != int(animation.get('FrameNum')) and not held:
                raise ValueError(f'{name}: frame coverage mismatch')
            layers.append({'id': layer.get('LayerId'), 'sheet': sheets[layer.get('LayerId')],
                           'frames': frames})
        animations[name] = layers
    if set(animations) != set(names):
        raise ValueError('Missing required animation')
    return animations


def active_frames(layers, time):
    for layer in layers:
        # Native ghost sheet is deliberately excluded, not replaced by mod art.
        if layer['sheet'] != '0':
            continue
        candidates = [f for start, f in layer['frames'] if start <= time]
        if candidates and candidates[-1].get('Visible') == 'true':
            yield candidates[-1]


def crop_box(f):
    x, y, w, h = (int(f[k]) for k in ('XCrop', 'YCrop', 'Width', 'Height'))
    return x, y, x + w, y + h


def render(atlas, frames):
    out = Image.new('RGBA', SIZE)
    for f in frames:
        box = crop_box(f)
        if box[0] < 0 or box[1] < 0 or box[2] > atlas.width or box[3] > atlas.height:
            raise ValueError(f'Crop outside atlas: {box}')
        cell = atlas.crop(box)
        sx, sy = float(f['XScale']) / 100, float(f['YScale']) / 100
        if not sx or not sy:
            continue
        # Inverse of translation * clockwise rotation * scale * pivot offset.
        angle = math.radians(float(f['Rotation']))
        c, s = math.cos(angle), math.sin(angle)
        tx = ORIGIN[0] + float(f['XPosition'])
        ty = ORIGIN[1] + float(f['YPosition'])
        matrix = (c / sx, s / sx, float(f['XPivot']) - (c * tx + s * ty) / sx,
                  -s / sy, c / sy, float(f['YPivot']) + (s * tx - c * ty) / sy)
        out.alpha_composite(cell.transform(SIZE, Image.Transform.AFFINE, matrix,
                                           resample=Image.Resampling.NEAREST))
    return out


def samples(animations):
    result = []
    for name in ('Hit', 'Death', 'WalkLeft', 'WalkRight'):
        layers = animations[name]
        times = sorted({t for layer in layers if layer['sheet'] == '0'
                        for t, f in layer['frames'] if f.get('Visible') == 'true'})
        for time in times:
            frames = list(active_frames(layers, time))
            if name.startswith('Walk'):
                frames += list(active_frames(animations[name.replace('Walk', 'Head')], 0))
            result.append((name, time, frames))
    for direction in ('Left', 'Right'):
        result.append(('Fire' + direction, 2,
                       list(active_frames(animations['Walk' + direction], 0)) +
                       list(active_frames(animations['Head' + direction], 2))))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--animation-reference', type=Path, required=True)
    parser.add_argument('--reference-skin', type=Path)
    args = parser.parse_args()
    animations = load_animation(args.animation_reference)
    poses = samples(animations)
    players = ET.parse(ROOT / 'content/players.xml').getroot()
    reference = Image.open(args.reference_skin).convert('RGBA') if args.reference_skin else None
    if len(players) != 22 or len({p.get('skin') for p in players}) != 22:
        raise ValueError('Expected all 22 distinct registered skins')
    output = args.output.resolve()
    if output.is_relative_to((ROOT / 'resources').resolve()) or output.is_relative_to((ROOT / 'content').resolve()):
        raise ValueError('Preview output must not be inside shipped assets')
    output.mkdir(parents=True, exist_ok=True)
    panel = Image.new('RGB', (160 + len(poses) * TILE[0], 110 + len(players) * TILE[1]), '#152030')
    draw = ImageDraw.Draw(panel)
    draw.text((12, 10), '22-form keyframe review: original sprite pixels; geometry only; no engine acceptance', fill='white')
    draw.text((12, 28), 'Identity roots; nearest sampling; tint, interpolation, costumes and native ghost omitted. Cross = player origin.', fill='#c6d5e7')
    draw.text((12, 46), 'Hit and Death: every skin-layer keyframe. Walk: ten bodies with idle side head; Fire: firing head sample.', fill='#c6d5e7')
    for col, (name, time, _) in enumerate(poses):
        draw.text((160 + col * TILE[0], 78), f'{name} {time}', fill='white')
    records = []
    for row, p in enumerate(players):
        name = ('Tainted ' if p.get('bSkinParent') else '') + p.get('name')
        path = ROOT / 'resources' / players.get('root') / p.get('skin')
        atlas = Image.open(path).convert('RGBA')
        rendered = [render(atlas, frames) for _, _, frames in poses]
        cells, warnings = {}, []
        for _, _, frames in poses:
            for f in frames:
                box = crop_box(f)
                key = ','.join(map(str, box))
                if key in cells:
                    continue
                visible = bounds(atlas.crop(box))
                ref = bounds(reference.crop(box)) if reference else None
                cells[key] = {'bounds': visible, 'reference_bounds': ref}
                if visible is None:
                    warnings.append(f'Empty sampled cell {key}')
                elif visible[0] == 0 or visible[1] == 0 or visible[2] == box[2] - box[0] or visible[3] == box[3] - box[1]:
                    warnings.append(f'Alpha touches crop edge {key}; inspect possible clipping')
        hit = cells['128,192,192,256']['bounds']
        hit_ok = bool(hit and hit[2] - hit[0] <= 28 and hit[3] - hit[1] <= 32
                      and hit[3] == 55 and abs(hit[0] + hit[2] - 64) <= 1)
        left = [im for im, (n, _, _) in zip(rendered, poses) if n == 'WalkLeft']
        right = [im for im, (n, _, _) in zip(rendered, poses) if n == 'WalkRight']
        # Reflect about the actual player origin, not the center of the tile.
        mirror_ok = all(all(high == 0 for _, high in ImageChops.difference(a, b.transform(SIZE, Image.Transform.AFFINE,
                            (-1, 0, 2 * ORIGIN[0], 0, 1, 0))).getextrema())
                        for a, b in zip(left, right))
        y = 110 + row * TILE[1]
        draw.text((12, y + 30), name, fill='white')
        draw.text((12, y + 48), 'Hit geometry OK' if hit_ok else 'CHECK HIT', fill='#a4deb4' if hit_ok else '#ffb28b')
        for col, im in enumerate(rendered):
            tile = Image.new('RGBA', SIZE, '#293950')
            guide = ImageDraw.Draw(tile)
            guide.line((0, ORIGIN[1], SIZE[0]-1, ORIGIN[1]), fill='#526477')
            guide.line((ORIGIN[0], 0, ORIGIN[0], SIZE[1]-1), fill='#3c4b60')
            tile.alpha_composite(im)
            panel.paste(tile.convert('RGB'), (160 + col * TILE[0], y))
        records.append({'name': name, 'skin': path.relative_to(ROOT).as_posix(),
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                        'hit_geometry_ok': hit_ok, 'side_mirror_equal': mirror_ok,
                        'warnings': warnings, 'cells': cells})
        records[-1]['side_unique_bodies'] = len({atlas.crop(crop_box(f)).tobytes()
            for layer in animations['WalkRight'] if layer['sheet'] == '0' for _, f in layer['frames']})
    panel.save(output / 'all-character-poses.png')
    selected = [('Hit', 6), ('Death', 0), ('Death', 4), ('Death', 8),
                ('Death', 12), ('Death', 21), ('WalkLeft', 0), ('WalkRight', 0),
                ('FireLeft', 2), ('FireRight', 2)]
    summary = Image.new('RGB', (160 + len(selected) * TILE[0], panel.height), '#152030')
    summary.paste(panel.crop((0, 110, 160, panel.height)), (0, 110))
    sd = ImageDraw.Draw(summary)
    sd.text((12, 10), '22 forms / selected keyframes / offline geometry only', fill='white')
    sd.text((12, 28), 'Full 45-sample sheet and measurements accompany this overview. Cross = player origin.', fill='#c6d5e7')
    sd.text((12, 46), 'Native ghost, tint, interpolation, costumes and engine effects are not simulated.', fill='#c6d5e7')
    for col, sample in enumerate(selected):
        i = next(i for i, (name, time, _) in enumerate(poses) if (name, time) == sample)
        x = 160 + i * TILE[0]
        summary.paste(panel.crop((x, 70, x + TILE[0], panel.height)), (160 + col * TILE[0], 70))
    summary.save(output / 'selected-character-poses.png')
    # The smaller per-family sheets are easier to inspect without downscaling.
    for row, record in enumerate(records):
        review = Image.new('RGB', (TILE[0] * 16, 440), '#152030')
        rd = ImageDraw.Draw(review)
        rd.text((8, 8), record['name'] + ' / offline geometry only', fill='white')
        indexes = [[i for i, (n, _, _) in enumerate(poses) if n == group]
                   for group in ('Hit', 'Death', 'WalkLeft', 'WalkRight')]
        indexes[0] += [len(poses)-2, len(poses)-1]
        for line, indices in enumerate(indexes):
            for col, i in enumerate(indices):
                x, y = 160 + i * TILE[0], 110 + row * TILE[1]
                review.paste(panel.crop((x, y, x + TILE[0], y + 80)), (col * TILE[0], 50 + line * 96))
                rd.text((col * TILE[0], 34 + line * 96), f'{poses[i][0]} {poses[i][1]}', fill='white')
        review.save(output / (Path(record['skin']).stem + '-poses.png'))
    report = {'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'working_tree_changes': subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines(),
              'animation_sha256': hashlib.sha256(args.animation_reference.read_bytes()).hexdigest(),
              'reference_skin_sha256': hashlib.sha256(args.reference_skin.read_bytes()).hexdigest() if reference else None,
              'scope': 'Offline keyframe geometry only. No native pixels, tint, interpolation, ghost, costumes or engine acceptance.',
              'samples_per_form': len(poses), 'records': records}
    (output / 'pose-review.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'Rendered {len(records)} forms x {len(poses)} poses; {sum(r["hit_geometry_ok"] for r in records)} Hit envelopes OK')
    print(output / 'all-character-poses.png')


if __name__ == '__main__':
    main()
