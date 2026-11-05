"""Check measured Hit/Death cell envelopes using only the standard library.

These limits describe individual complete-pose cells, not all 64px cells or
anatomical proportions. They do not establish in-engine visual acceptance.
"""
from pathlib import Path
import struct
import hashlib
import json
import xml.etree.ElementTree as ET
import zlib

from clean_pose_cells import leftovers

ROOT = Path(__file__).resolve().parent.parent
# Crop x/y/w/h, maximum visible w/h, exclusive visible bottom within crop.
# Death's last crop starts two rows below the packed 64px cell.
CONTRACTS = {
    'Hit': ((128, 192, 64, 64), (28, 32), 55),
    'Death start': ((0, 192, 64, 64), (28, 33), 57),
    'Death recoil': ((0, 128, 64, 64), (28, 33), 57),
    'Death fallen': ((192, 130, 64, 64), (36, 27), 59),
}


def read_rgba(path):
    """Decode only the noninterlaced RGBA8 PNGs used by our skin assets."""
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError(f'{path.name}: not PNG')
    pos, chunks, header = 8, [], None
    while pos < len(data):
        size = struct.unpack_from('>I', data, pos)[0]
        tag = data[pos+4:pos+8]
        payload = data[pos+8:pos+8+size]
        crc = struct.unpack_from('>I', data, pos+8+size)[0]
        if zlib.crc32(tag + payload) != crc:
            raise ValueError(f'{path.name}: bad PNG CRC')
        if tag == b'IHDR':
            header = struct.unpack('>IIBBBBB', payload)
        if tag == b'IDAT':
            chunks.append(payload)
        pos += size + 12
        if tag == b'IEND':
            break
    if header is None or header[2:] != (8, 6, 0, 0, 0):
        raise ValueError(f'{path.name}: expected noninterlaced RGBA8')
    width, height = header[:2]
    raw = zlib.decompress(b''.join(chunks))
    stride = width * 4
    if len(raw) != height * (stride + 1):
        raise ValueError(f'{path.name}: wrong decompressed length')
    previous, rows = bytearray(stride), []
    for y in range(height):
        start = y * (stride + 1)
        kind = raw[start]
        row = bytearray(raw[start+1:start+1+stride])
        if kind not in range(5):
            raise ValueError(f'{path.name}: unknown PNG row filter')
        for x in range(stride):
            left = row[x-4] if x >= 4 else 0
            up = previous[x]
            corner = previous[x-4] if x >= 4 else 0
            if kind == 0:
                predictor = 0
            elif kind == 1:
                predictor = left
            elif kind == 2:
                predictor = up
            elif kind == 3:
                predictor = (left + up) // 2
            else:
                p = left + up - corner
                distances = (abs(p-left), abs(p-up), abs(p-corner))
                predictor = (left, up, corner)[distances.index(min(distances))]
            row[x] = (row[x] + predictor) & 255
        rows.append(row)
        previous = row
    return width, height, rows


def alpha_bounds(rows, crop):
    x0, y0, width, height = crop
    points = [(x, y) for y in range(height) for x in range(width)
              if rows[y0+y][4*(x0+x)+3] >= 128]
    if not points:
        return None
    xs, ys = zip(*points)
    return min(xs), min(ys), max(xs)+1, max(ys)+1


def main():
    players = ET.parse(ROOT / 'content/players.xml').getroot()
    failures = []
    profiles = json.loads((ROOT / 'docs/profile-pose-repairs.json').read_text(encoding='utf-8'))['repairs']
    for profile in profiles:
        for source in profile['sources']:
            if hashlib.sha256((ROOT / source['path']).read_bytes()).hexdigest() != source['sha256']:
                failures.append(f'{source["path"]}: profile source hash mismatch')
    for player in players:
        path = ROOT / 'resources' / players.get('root') / player.get('skin')
        width, height, rows = read_rgba(path)
        for name, (crop, maximum, bottom) in CONTRACTS.items():
            assert crop[0]+crop[2] <= width and crop[1]+crop[3] <= height
            box = alpha_bounds(rows, crop)
            if not (box and box[2]-box[0] <= maximum[0] and box[3]-box[1] <= maximum[1]
                    and box[3] == bottom and abs(box[0]+box[2]-crop[2]) <= 1):
                failures.append(f'{path.name} {name}: {box}; limit={maximum}, bottom={bottom}, centered')
        found = leftovers(lambda x, y: rows[y][4*x+3] >= 128)
        if found:
            cells = ', '.join(f'{cell} {len(points)}px' for cell, points in found)
            failures.append(f'{path.name} crop leftovers in pose cells: {cells}; run tools/clean_pose_cells.py')
        key = path.stem.removeprefix('character_').removesuffix('_b').removesuffix('chan')
        profile = next((p for p in profiles if p['key'] == key), None)
        if profile:
            groups = [(False, False), (True, False)]
            if 'carry' in profile:
                groups.append((True, True))
            for carry, front in groups:
                wide = carry and 'carry' in profile
                cfg = profile['carry'] if wide else profile['side']
                cycle = cfg['cycle']
                if len(cycle) != 10 or set(cycle) != {0, 1, 2}:
                    failures.append(f'{key}: expected ten frames using three reviewed phases')
                    continue
                phases = {}
                for i, phase in enumerate(cycle):
                    if front:
                        x, y = (256+i*32, 32) if i < 8 else (448+(i-8)*32, 0)
                    else:
                        x, y = (i*32, 64) if i < 8 else ((i-8)*32, 96)
                        x += 256 if carry else 0
                    box = alpha_bounds(rows, (x, y, 32, 32))
                    if not (box and box[0] > 0 and box[1] > 0 and box[2] < 32
                            and box[3] == 26 and box[2]-box[0] <= (26 if wide else 20)
                            and box[3]-box[1] <= (18 if wide or not carry else 22)
                            and (not wide or abs(box[0]+box[2]-32) <= 1)):
                        failures.append(f'{path.name}: profile cell {i}, carry={carry}, front={front}: {box}')
                    if carry and not wide and box and box[1] < cfg.get('carry_min_y', 0):
                        failures.append(f'{path.name}: carry cell {i} enters the reviewed face clearance')
                    if wide:
                        # Foreground carry arms flank the head. Protect the
                        # central face, while permitting hands over side hair.
                        if alpha_bounds(rows, (x+9, y, 14, 13)):
                            failures.append(f'{path.name}: carry cell {i}, front={front} covers the central face')
                        if not all(alpha_bounds(rows, (x+edge, y, 8, 13))
                                   for edge in (1, 23)):
                            failures.append(f'{path.name}: carry cell {i}, front={front} loses a raised hand')
                    pixels = b''.join(row[x*4:(x+32)*4] for row in rows[y:y+32])
                    if phase in phases and phases[phase] != pixels:
                        failures.append(f'{path.name}: inconsistent repeated profile phase {phase}')
                    phases[phase] = pixels
                if len(set(phases.values())) != 3:
                    failures.append(f'{path.name}: profile stride lost one of three source phases')
            if 'fallen' in profile:
                box = alpha_bounds(rows, (192, 130, 64, 64))
                if not box or box[2]-box[0] < 1.6*(box[3]-box[1]):
                    failures.append(f'{path.name}: repaired fallen silhouette is no longer horizontal')
    if failures:
        raise SystemExit('\n'.join(failures))
    print(f'  OK: {len(players)} skins retain measured Hit/Death envelopes and anchors, with no crop leftovers')


if __name__ == '__main__':
    main()
