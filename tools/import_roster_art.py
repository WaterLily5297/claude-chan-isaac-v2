"""Mechanically size generated art for engine cells; never generate replacement art.

Usage: python tools/import_roster_art.py --portraits DIR --sprites DIR
Portrait inputs: claude.png, deepseek.png, and each key in portrait-prompts.json.
Sprite inputs: the nine new model keys, each a square transparent atlas.
Requires Pillow for development only. Existing four gameplay skins are preserved.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent

# Reviewed generated-frame boundaries, in the 1254px source coordinate system.
# Generated atlases do not reliably preserve a uniform grid. Remap complete
# cutouts instead of shrinking the entire sheet and clipping neighboring frames.
HEAD_CUTS={
    'gpt':[0,78,156,235,313,391,479],
    'gemini':[0,80,160,240,320,400,480],
    'grok':[0,101,194,285,373,466,562],
    'llama':[0,80,160,240,320,400,480],
    'mistral':[0,90,174,250,327,412,498],
    'qwen':[0,91,175,257,342,437,532],
    'doubao':[0,99,185,277,369,461,553],
    'hunyuan':[0,89,175,259,344,438,532],
}

def sprite_sheet(source,key):
    source=source.resize((1254,1254),Image.Resampling.NEAREST)
    out=source.resize((512,512),Image.Resampling.NEAREST)
    out.paste(Image.new('RGBA',(512,128)),(0,0))
    def place(box,position,cell=(32,32),limit=(28,28),bottom=None):
        cut=source.crop(box)
        bounds=cut.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        assert bounds, (key,box)
        cut=cut.crop(bounds)
        cut.thumbnail(limit,Image.Resampling.NEAREST)
        frame=Image.new('RGBA',cell)
        y=(cell[1]-cut.height)//2 if bottom is None else bottom-cut.height
        frame.alpha_composite(cut,((cell[0]-cut.width)//2,y))
        out.paste(frame,position)
        return frame
    cuts=HEAD_CUTS.get(key,[0,80,160,240,320,400,480])
    for i in range(6):
        place((cuts[i],0,cuts[i+1],92),(i*32,0),bottom=30)
    out.paste(out.crop((0,0,32,32)),(256,0))
    count=7 if key in ('qwen','doubao','hunyuan') else 8
    body_rows=[(104,174),(190,265)] if key=='hunyuan' else [(96,170),(176,250)]
    for row,(y0,y1) in enumerate(body_rows,1):
        for i in range(8):
            column=i%count
            box=(round(column*632/count),y0,round((column+1)*632/count),y1)
            body=place(box,(i*32,row*32),limit=(20,18),bottom=26)
            out.paste(body,(256+i*32,row*32))
    for i in range(2):
        y0,y1=(302,350) if key=='qwen' else (275,350) if key=='hunyuan' else (254,322)
        box=(i*80,y0,(i+1)*80,y1)
        body=place(box,(i*32,96),limit=(20,18),bottom=26)
        out.paste(body,(256+i*32,96))
    # Reuse this character's own headless bodies for raised-arm alternate cells.
    # This sacrifices arm-pose detail without introducing a second head.
    for i in (6,7,14,15): out.paste(out.crop(((i%2)*32,32,(i%2+1)*32,64)),(i*32,0))
    rows=[(350,518),(520,685),(690,832)] if key=='qwen' else [(324,510),(514,658),(660,818)]
    if key=='hunyuan': rows=[(360,537),(540,705),(708,860)]
    for row,(y0,y1) in enumerate(rows):
        count=5 if row==0 else 4
        for column in range(count):
            place((column*160,y0,(column+1)*160,y1),(column*64,128+row*64),
                  cell=(64,64),limit=(58,58))
    lower_y=835 if key=='qwen' else 818 if key=='doubao' else 800
    if key=='hunyuan': lower_y=870
    out.paste(source.crop((0,lower_y,320,lower_y+310)).resize((128,128),Image.Resampling.NEAREST),(0,320))
    return out

def fitted(image, size):
    bounds = image.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert bounds, 'Expected visible art'
    image = image.crop(bounds)
    image.thumbnail(size, Image.Resampling.LANCZOS)
    out = Image.new('RGBA', size)
    out.alpha_composite(image, ((size[0]-image.width)//2, (size[1]-image.height)//2))
    return out

def png(source):
    image=Image.open(source).convert('RGBA')
    assert image.getextrema()[3][0] == 0, f'No transparency: {source}'
    return image

def repair_mimo(atlas,parts):
    def part(column,row):
        cut=parts.crop((round(column*parts.width/4),round(row*parts.height/2),
                        round((column+1)*parts.width/4),round((row+1)*parts.height/2)))
        bounds=cut.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        assert bounds
        cut=cut.crop(bounds)
        cut.thumbnail((20,18),Image.Resampling.NEAREST)
        cell=Image.new('RGBA',(32,32))
        cell.alpha_composite(cut,((32-cut.width)//2,26-cut.height))
        return cell
    for row in (1,2):
        for column in range(8):
            atlas.paste(part(column%2+(0 if row==1 else 2),0),(column*32,row*32))
            atlas.paste(part(2,1),(256+column*32,row*32))
    for column in range(2):
        atlas.paste(part(column,1),(column*32,96))
        atlas.paste(part(3,1),(256+column*32,96))
    for column in (6,7,14,15): atlas.paste(part(2,1),(column*32,0))

def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--portraits',required=True,type=Path)
    parser.add_argument('--sprites',required=True,type=Path)
    args=parser.parse_args()
    entries=json.loads((ROOT/'docs/portrait-prompts.json').read_text(encoding='utf-8'))['entries']
    menu=Image.new('RGBA',(64*len(entries),64))
    labels=Image.new('RGBA',(256,32*len(entries)))
    font=ImageFont.load_default()
    players=ET.parse(ROOT/'content/players.xml')
    proot=players.getroot()
    manifest=[]
    for index,entry in enumerate(entries):
        key,name=entry['key'],entry['name']
        source=args.portraits/(key+'.png')
        image=png(source)
        full=fitted(image,(384,576))
        save(full,ROOT/f'resources/gfx/ui/dossiers/{key}.png')
        # The top portion is a menu bust, preserving face detail at 64 pixels.
        bust=image.crop((0,0,image.width,int(image.height*0.45)))
        menu.alpha_composite(fitted(bust,(60,60)),(index*64+2,2))
        gamekey=key+'chan'
        save(fitted(image,(144,144)),ROOT/f'resources/gfx/ui/stage/playerportrait_{gamekey}.png')
        draw=ImageDraw.Draw(labels)
        draw.text((4,index*32+8),name.upper(),font=font,fill=(32,20,20,255))
        save(labels.crop((0,index*32,128,index*32+32)),ROOT/f'resources/gfx/ui/boss/playername_{gamekey}.png')
        # Clone the known valid one-frame structure for each dossier.
        actor=ET.parse(ROOT/'content/gfx/characterportraits.anm2').getroot()
        actor.find('./Content/Spritesheets/Spritesheet').set('Path',f'{key}.png')  # relative to the .anm2 folder
        animations=actor.find('Animations')
        first=copy.deepcopy(animations[0])
        animations.clear(); animations.set('DefaultAnimation','Idle')
        first.set('Name','Idle'); animations.append(first)
        f=first.find('./LayerAnimations/LayerAnimation/Frame')
        f.attrib.update(XCrop='0',YCrop='0',Width='384',Height='576',XPivot='192',YPivot='288')
        ET.indent(actor)
        ET.ElementTree(actor).write(ROOT/f'resources/gfx/ui/dossiers/{key}.anm2',encoding='utf-8',xml_declaration=True)
        record={'key':key,'portrait_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
        if index>=2:
            atlas_path=args.sprites/(key+'.png')
            atlas=png(atlas_path)
            assert atlas.width==atlas.height, atlas_path
            atlas=sprite_sheet(atlas,key)
            if key=='mimo':
                parts_path=args.sprites/'mimo-bodies.png'
                repair_mimo(atlas,png(parts_path))
                record['body_parts_sha256']=hashlib.sha256(parts_path.read_bytes()).hexdigest()
            save(atlas,ROOT/f'resources/gfx/characters/costumes/character_{gamekey}.png')
            record['sprite_sha256']=hashlib.sha256(atlas_path.read_bytes()).hexdigest()
            if not any(p.get('name')==name for p in proot):
                ET.SubElement(proot,'player',name=name,skin=f'character_{gamekey}.png',skinColor='-1',
                    hp='4',armor='2',black='0',coins='0',bombs='1',keys='0',
                    portrait=f'playerportrait_{gamekey}.png',bigportrait=f'playerportrait_{gamekey}.png',
                    nameimage=f'playername_{gamekey}.png')
        manifest.append(record)
    save(menu,ROOT/'content/gfx/ai_portraits.png')
    save(labels,ROOT/'content/gfx/ai_names.png')
    tainted_menu=Image.new('RGBA',(256,128))
    for index,key in enumerate(['claude','deepseek']):
        source=args.portraits/(key+'_b.png')
        image=png(source)
        save(fitted(image,(384,576)),ROOT/f'resources/gfx/ui/dossiers/{key}_b.png')
        save(fitted(image,(144,144)),ROOT/f'resources/gfx/ui/stage/playerportrait_{key}chan_b.png')
        tainted_menu.alpha_composite(fitted(image.crop((0,0,image.width,int(image.height*0.45))),(60,60)),(index*64+2,2))
        tree=ET.parse(ROOT/f'resources/gfx/ui/dossiers/{key}.anm2')
        tree.find('./Content/Spritesheets/Spritesheet').set('Path',f'gfx/ui/dossiers/{key}_b.png')
        tree.write(ROOT/f'resources/gfx/ui/dossiers/{key}_b.anm2',encoding='utf-8',xml_declaration=True)
        manifest.append({'key':key+'_b','portrait_sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
    save(tainted_menu,ROOT/'content/gfx/ai_portraits_b.png')
    for filename,portrait in [('characterportraits.anm2',True),('charactermenu.anm2',False)]:
        tree=ET.parse(ROOT/'content/gfx'/filename)
        animations=tree.getroot().find('Animations')
        template=copy.deepcopy(animations[0])
        animations.clear(); animations.set('DefaultAnimation','Claude-chan')
        for index,entry in enumerate(entries):
            animation=copy.deepcopy(template); animation.set('Name',entry['name'])
            frame=animation.find('./LayerAnimations/LayerAnimation/Frame')
            frame.set('XCrop',str(index*64 if portrait else 0))
            frame.set('YCrop',str(0 if portrait else index*32))
            animations.append(animation)
        ET.indent(tree)
        tree.write(ROOT/'content/gfx'/filename,encoding='utf-8',xml_declaration=True)
    ET.indent(players)
    players.write(ROOT/'content/players.xml',encoding='utf-8',xml_declaration=True)
    (ROOT/'docs/roster-art-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(f'Imported {len(entries)} portraits and {len(entries)-2} new gameplay skins.')

if __name__=='__main__':
    main()
