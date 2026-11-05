"""Pack image-tool-generated frames into engine cells without drawing new art.

Usage: python tools/pack_selected_sprites.py SOURCE_DIRECTORY
Inputs are the thirteen selected square PNG atlases. Coordinates are reviewed at
1254x1254. This performs cropping, nearest-neighbor sizing and atlas packing;
it does not establish correct engine animation or weapon compatibility.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image
from clean_pose_cells import clean as clean_pose_cells
from fix_character_cells import main_component

ROOT = Path(__file__).resolve().parent.parent
KEYS = ('claude', 'deepseek', 'claude_b', 'deepseek_b',
        'gpt', 'gemini', 'grok', 'qwen', 'llama', 'mistral', 'doubao', 'kimi', 'glm')
ORIGINALS = KEYS[:4]
HEADS = {
    'claude': ([0, 96, 188, 283, 382, 487], [0, 1, 3, 3, 4, 4]),
    'deepseek': ([0, 100, 200, 300, 395, 495, 595], [0, 1, 2, 3, 4, 5]),
    'claude_b': ([0, 105, 209, 315, 418, 523, 630], [0, 1, 2, 2, 4, 5]),
    'deepseek_b': ([0, 100, 199, 301, 400, 498, 597], [0, 1, 2, 2, 4, 5]),
}


def pack(source, key):
    source = source.convert('RGBA').resize((1254, 1254), Image.Resampling.NEAREST)
    # Pixel sprites use binary coverage. Generated files contain near-invisible
    # alpha=1 matte specks that some atlas previews incorrectly display brightly.
    source.putalpha(source.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    source = Image.alpha_composite(Image.new('RGBA', source.size), source)
    out = source.resize((512, 512), Image.Resampling.NEAREST)
    out.paste(Image.new('RGBA', (512, 320)), (0, 0))

    def frame(box, position, cell=32, limit=28, bottom=None):
        piece = main_component(source.crop(tuple(round(v) for v in box)))
        bounds = piece.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
        assert bounds, (key, box)
        piece = piece.crop(bounds)
        size = (limit, limit) if isinstance(limit, int) else limit
        piece.thumbnail(size, Image.Resampling.NEAREST)
        target = Image.new('RGBA', (cell, cell))
        y = (cell-piece.height)//2 if bottom is None else bottom-piece.height
        target.alpha_composite(piece, ((cell-piece.width)//2, y))
        out.paste(target, position)
        return target

    step = 1254/16
    for i in range(6):
        if key in HEADS:
            cuts, mapping = HEADS[key]
            j = mapping[i]
            box = (cuts[j], 0, cuts[j+1], 98)
        elif key == 'llama':
            cuts = [0, 104, 211, 313, 408, 512, 616]
            j = [0, 1, 2, 2, 4, 5][i]
            box = (cuts[j], 0, cuts[j+1], 115)
        else:
            box = (i*step, 0, (i+1)*step, step)
        # Match the reviewed head envelope and chin baseline. Costumes keep
        # engine pivots; pushing the head down to row 30 misaligns that anchor.
        frame(box, (i*32, 0), limit=(28, 26), bottom=27)
    # The alternate front head must not become a body or a rear view.
    out.paste(out.crop((0, 0, 32, 32)), (256, 0))
    for row in (1, 2):
        for column in range(16):
            if key == 'llama':
                j = column % 14
                y0, y1 = ((123, 211) if row == 1 else (216, 299))
                box = (j*1254/14, y0, (j+1)*1254/14, y1)
            elif key in ORIGINALS:
                y0, y1 = ((103, 178) if row == 1 else (181, 264))
                if key == 'deepseek_b':
                    y0, y1 = ((99, 161) if row == 1 else (165, 239))
                if key == 'claude_b':
                    j = column % 14
                    box = (j*1254/14, y0, (j+1)*1254/14, y1)
                elif key == 'deepseek' and row == 1 and column < 8:
                    j = column % 7
                    box = (j*80, y0, (j+1)*80, y1)
                else:
                    box = (column*step, y0, (column+1)*step, y1)
            else:
                box = (column*step, row*step, (column+1)*step, (row+1)*step)
            frame(box, (column*32, row*32), limit=20, bottom=26)
    for column in (0, 1, 8, 9):
        if key in ('llama', 'glm') or key in ORIGINALS:
            out.paste(out.crop((column*32, 64, (column+1)*32, 96)), (column*32, 96))
        else:
            frame((column*step, 3*step, (column+1)*step, 4*step),
                  (column*32, 96), limit=20, bottom=26)
    for column in (6, 7, 14, 15):
        out.paste(out.crop(((column%2)*32, 32, (column%2+1)*32, 64)), (column*32, 0))
    for row in range(3):
        for column in range(5 if row == 0 else 4):
            y0, y1 = ((4+row*2)*step, (6+row*2)*step)
            if key in ORIGINALS:
                y0, y1 = [(335, 510), (512, 655), (657, 808)][row]
            # Hit uses a complete pose at (128,192), pivot (32,56).
            # A 64px storage cell is not a 64px character: the measured vanilla
            # pose is 28x32, with its visible bottom at 55 before squash/stretch.
            hit = row == 1 and column == 2
            death_upright = column == 0 and row in (0, 1)
            death_fallen = row == 0 and column == 3
            if key == 'llama' and row == 1 and column in (0, 2):
                # This source row sits below the nominal grid; the generic
                # crop stops through the face and discards the hands/feet.
                y0, y1 = 490, 654
            # Death mixes the corrected Hit cell with two upright cells and
            # a fallen cell. Match their own measured envelopes, not Hit's.
            # The fallen animation crops at y=130, two below its storage row.
            limit, bottom = 58, None
            if hit:
                limit, bottom = (28, 32), 55
            elif death_upright:
                limit, bottom = (28, 33), 57
            elif death_fallen:
                limit, bottom = (36, 27), 61
            frame((column*2*step, y0, (column+1)*2*step, y1),
                  (column*64, 128+row*64), cell=64,
                  limit=limit, bottom=bottom)
    # PickupWalk crops a head at (256,128), pivot (32,44), rather than a
    # complete character. Preserve the same chin offset as the 32px head.
    carry_head = Image.new('RGBA', (64, 64))
    carry_head.alpha_composite(out.crop((0, 0, 32, 32)), (16, 16))
    out.paste(carry_head, (256, 128))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--movement-source', type=Path,
                        help='Reviewed four-character movement revisions')
    args = parser.parse_args()
    manifest_path = ROOT/'docs/roster-art-manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    revised = [r for r in manifest if r.get('movement_source_sha256')]
    if revised and not args.movement_source:
        parser.error('--movement-source is required to preserve the original-character revisions')
    # Validate every private atlas before any write; never adopt a different
    # source merely because it has the expected filename.
    for record in manifest:
        path = args.source / (record['key'] + '.png')
        if hashlib.sha256(path.read_bytes()).hexdigest() != record['sprite_sha256']:
            parser.error(f"Selected source hash mismatch: {record['key']}")
    if revised:
        from pack_original_movement import pack as pack_movement
        for record in revised:
            path = args.movement_source / (record['key'] + '.png')
            if hashlib.sha256(path.read_bytes()).hexdigest() != record['movement_source_sha256']:
                parser.error(f"Movement source hash mismatch: {record['key']}")
    for key in KEYS:
        record = next(e for e in manifest if e['key'] == key)
        source = args.source/(key+'.png')
        atlas = pack(Image.open(source), key)
        if revised and key in ORIGINALS:
            atlas = pack_movement(atlas, Image.open(args.movement_source / (key + '.png')), key)
        if record.get('walk_cycle') == 'tools/animate_roster_walk.py':
            from animate_roster_walk import animate
            atlas = animate(atlas)
        from pack_profile_poses import apply as apply_profile_poses
        atlas = apply_profile_poses(atlas, key)
        # Last step: drop neighbour slivers and stray lines caught by pose crops.
        clean_pose_cells(atlas)
        gamekey = key.replace('_b', 'chan_b') if key.endswith('_b') else key+'chan'
        target = ROOT/f'resources/gfx/characters/costumes/character_{gamekey}.png'
        atlas.save(target, optimize=True)
        record['sprite_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        record['packed_sprite_sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
    manifest_path.write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print('Packed thirteen selected portrait identities; engine animation acceptance remains pending.')


if __name__ == '__main__':
    main()
