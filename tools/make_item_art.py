"""Produce and check registered item icons without replacing character artwork.

Standard library only. The manifest explicitly partitions placeholder and
designed icons. --write regenerates from drawing code, never from an edited PNG;
--check is read-only. Native presentation and aesthetic quality require review.
"""
import argparse
from collections import Counter
from dataclasses import dataclass
import hashlib
import json
import math
from pathlib import Path, PurePosixPath
import re
import struct
from typing import Callable
import xml.etree.ElementTree as ET
import zlib

import make_placeholders as legacy
from check_pose_geometry import read_rgba

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = 'docs/item-art-manifest.json'
ICON_ROOT = 'resources/gfx/items'
SCHEMA_VERSION = 1


@dataclass(frozen=True)
class Design:
    draw: Callable
    version: int
    palette: tuple
    description: str
    author: str
    provenance: str
    contact_sheet: str
    palette_exception: str = ''


# Original 32px object drawings. Shared ramps run shadow -> body -> light.
# These shapes are authored here; no native or third-party image is sampled.
INK = '#080000'
STEEL = ('#4e4955', '#96929b', '#d9d4cf')
WOOD = ('#684033', '#a76b43', '#e0a66b')
ORANGE = ('#96382d', '#e16c3c', '#ffb66b')
PAPER = ('#9f896a', '#d9c9a4', '#fff1d0')
BLUE = ('#285362', '#4c9ba8', '#a0dfd6')
GOLD = ('#8e5c27', '#d5a044', '#ffe091')
PINK = ('#874155', '#d28289', '#ffbdaf')
PURPLE = ('#44324e', '#826b93', '#c4abc9')
YELLOW = ('#9c682e', '#f5c84a', '#fff1a5')
GREEN = ('#2f5b3a', '#5f9a4f', '#b5d98a')
RED = ('#7a1f2b', '#c83a3f', '#f08a7a')


class Canvas:
    def __init__(self):
        self.grid = legacy.clear()

    def rect(self, x0, y0, x1, y1, colour):
        legacy.rect(self.grid, x0, y0, x1, y1, colour)

    def poly(self, points, colour):
        legacy.poly(self.grid, points, colour)

    def line(self, x0, y0, x1, y1, colour, width=1):
        legacy.line(self.grid, x0, y0, x1, y1, colour, width)

    def oval(self, cx, cy, rx, ry, colour):
        legacy.ellipse(self.grid, cx, cy, rx, ry, colour)

    def finish(self):
        # Outline only the exterior, not every material patch. Interior edges
        # are drawn deliberately so adjacent layers do not acquire double ink.
        grid = [row[:] for row in self.grid]
        for y in range(32):
            for x in range(32):
                if self.grid[y][x] == '.' and any(
                    0 <= x+dx < 32 and 0 <= y+dy < 32 and self.grid[y+dy][x+dx] != '.'
                    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))):
                    grid[y][x] = INK
        return legacy.rgba(grid)


def hammer_art():
    c = Canvas()
    c.poly([(8,26),(18,12),(22,15),(12,29)], WOOD[0])
    c.poly([(8,26),(18,12),(20,13),(10,28)], WOOD[1])
    c.line(10,25,18,14,WOOD[2])
    c.line(11,24,14,26,INK)
    c.poly([(6,9),(11,3),(27,12),(22,19)], STEEL[0])
    c.poly([(7,8),(11,3),(27,12),(25,14)], STEEL[2])
    c.poly([(9,9),(12,5),(25,12),(22,16)], ORANGE[1])
    c.poly([(9,9),(22,16),(21,18),(8,11)], ORANGE[0])
    c.line(12,6,22,11,ORANGE[2])
    c.poly([(6,9),(8,6),(11,8),(8,12)], STEEL[1])
    c.poly([(23,12),(26,13),(23,17),(21,16)], STEEL[1])
    c.line(8,7,9,7,STEEL[2])
    c.line(23,13,24,13,STEEL[2])
    return c.finish()


def compact_art():
    c = Canvas()
    c.rect(4,7,7,26,STEEL[0]); c.rect(25,7,27,26,STEEL[0])
    c.rect(4,7,5,25,STEEL[2]); c.rect(25,7,25,24,STEEL[1])
    c.poly([(8,11),(21,9),(25,12),(25,22),(9,24)], PAPER[0])
    c.poly([(8,11),(21,9),(24,11),(10,13)], PAPER[2])
    c.poly([(9,13),(24,11),(24,21),(9,23)], PAPER[1])
    for y in (15,18,21): c.line(10,y,22,y-2,PAPER[0])
    c.line(11,14,22,12,PAPER[2]); c.line(10,17,16,16,PAPER[2])
    c.poly([(16,11),(19,10),(19,22),(16,22)], BLUE[0])
    c.rect(16,12,17,21,BLUE[1]); c.line(16,12,17,11,BLUE[2])
    c.poly([(3,4),(25,4),(28,6),(28,9),(3,9)], STEEL[0])
    c.rect(4,5,25,6,STEEL[2]); c.rect(4,7,26,8,STEEL[1])
    c.rect(3,25,28,27,STEEL[0]); c.rect(4,25,27,25,STEEL[2])
    c.rect(6,28,9,28,STEEL[0]); c.rect(23,28,26,28,STEEL[0])
    return c.finish()


def stapler_art():
    c = Canvas()
    c.poly([(5,24),(22,21),(27,23),(27,27),(5,28)], STEEL[0])
    c.poly([(6,24),(23,22),(26,24),(6,26)], STEEL[2])
    c.line(7,27,25,25,STEEL[1])
    c.poly([(22,16),(26,17),(26,23),(22,22)], STEEL[0])
    c.rect(23,18,24,21,STEEL[1])
    for x,y in ((8,21),(12,20),(16,19)):
        c.oval(x,y,2,3,BLUE[0]); c.oval(x-0.5,y-0.5,1.5,2,BLUE[1]); c.rect(x-1,y-2,x-1,y-1,BLUE[2])
    c.poly([(4,7),(7,4),(25,11),(27,15),(24,18),(5,12)], ORANGE[0])
    c.poly([(4,7),(7,4),(25,11),(23,13)], ORANGE[2])
    c.poly([(5,8),(23,14),(24,17),(5,11)], ORANGE[1])
    c.line(7,13,21,17,STEEL[0]); c.line(8,13,20,16,STEEL[2])
    c.oval(24,15,1.5,1.5,STEEL[0]); c.rect(23,14,23,14,STEEL[2])
    return c.finish()


def ultrathink_art():
    c = Canvas()
    c.poly([(11,20),(22,20),(21,26),(13,27)], GOLD[0])
    c.rect(12,23,21,25,GOLD[1]); c.line(13,23,20,23,GOLD[2])
    c.line(13,25,21,25,INK); c.rect(14,27,19,28,STEEL[0])
    c.rect(15,27,18,27,STEEL[2])
    c.oval(16,13,11,10,PINK[0])
    for cx,cy,rx,ry in ((10,9,4,4),(16,7,4,4),(22,10,4,4),(9,15,4,4),(16,15,6,7),(23,15,4,4)):
        c.oval(cx,cy,rx,ry,PINK[1])
    c.line(7,10,8,7,PINK[2]); c.line(8,7,11,6,PINK[2])
    c.line(14,5,18,5,PINK[2]); c.line(21,7,23,9,PINK[2])
    c.line(13,7,13,11,PINK[0]); c.line(13,11,10,12,PINK[0])
    c.line(18,8,18,12,PINK[0]); c.line(18,12,22,13,PINK[0])
    c.line(8,17,12,17,PINK[0]); c.line(12,17,12,20,PINK[0])
    c.line(16,14,16,19,PINK[0]); c.line(19,17,22,17,PINK[0])
    c.line(19,17,19,20,PINK[0]); c.rect(14,15,14,17,PINK[2])
    c.rect(3,7,3,9,GOLD[2]); c.rect(27,5,28,5,GOLD[1])
    return c.finish()


def swarm_art():
    c = Canvas()
    c.line(15,19,8,14,BLUE[0],2); c.line(18,18,23,13,BLUE[0],2)
    c.line(8,14,7,11,BLUE[2]); c.line(22,14,24,11,BLUE[1])
    for x,y in ((7,5),(25,3)):
        c.poly([(x,y),(x-3,y+5),(x-2,y+8),(x+2,y+8),(x+3,y+5)],ORANGE[0])
        c.poly([(x,y),(x-2,y+5),(x-1,y+7),(x+1,y+7),(x+2,y+4)],ORANGE[1])
        c.line(x-1,y+3,x-1,y+5,ORANGE[2])
    c.poly([(16,13),(10,22),(10,25),(13,28),(19,28),(22,25),(22,22)],ORANGE[0])
    c.poly([(16,14),(11,22),(12,25),(15,27),(18,26),(20,22)],ORANGE[1])
    c.line(14,19,12,23,ORANGE[2]); c.rect(13,24,14,24,ORANGE[2])
    return c.finish()


def constitution_art():
    c = Canvas()
    c.poly([(7,3),(25,6),(25,28),(6,26),(4,23),(4,6)],WOOD[0])
    c.poly([(7,5),(24,8),(24,26),(8,24)],PAPER[0])
    c.line(8,24,24,26,PAPER[2]); c.line(9,26,23,28,PAPER[0])
    c.poly([(7,3),(25,6),(24,24),(7,22)],PAPER[1])
    c.poly([(7,3),(25,6),(24,8),(8,6)],PAPER[2])
    c.poly([(5,6),(7,3),(9,6),(8,23),(6,25),(4,22)],WOOD[1])
    c.line(6,7,6,21,WOOD[2]); c.line(9,7,8,22,WOOD[0])
    c.poly([(14,9),(21,10),(21,15),(17,19),(13,15)],GOLD[0])
    c.poly([(14,10),(20,11),(19,15),(17,17),(14,14)],GOLD[1])
    c.line(14,10,19,11,GOLD[2]); c.line(14,11,14,14,GOLD[2])
    c.poly([(15,23),(14,28),(17,27),(19,29),(20,24)],PINK[0])
    c.oval(17,22,4,4,PINK[0]); c.oval(16,21,3,3,PINK[1])
    c.line(14,20,16,19,PINK[2]); c.rect(17,22,18,23,PINK[0])
    return c.finish()


def lunch_art():
    c = Canvas()
    c.poly([(7,25),(23,25),(26,28),(9,28)],PINK[0])
    c.line(10,27,22,27,PINK[1])
    c.line(20,3,28,12,WOOD[0],2); c.line(18,5,25,13,WOOD[0],2)
    c.line(20,3,27,11,WOOD[2]); c.line(18,5,24,12,WOOD[1])
    c.oval(16,15,12,5,BLUE[0])
    c.oval(16,13,10,5,PAPER[0])
    for x,y in ((9,11),(13,9),(18,9),(22,11),(13,13),(18,13)):
        c.oval(x,y,3,2.5,PAPER[1]); c.line(x-1,y-1,x,y-1,PAPER[2])
    c.poly([(4,15),(27,15),(25,22),(21,26),(10,26),(6,22)],BLUE[0])
    c.poly([(5,16),(24,16),(23,22),(19,24),(10,24),(7,21)],BLUE[1])
    c.poly([(5,16),(10,17),(10,22),(8,21)],BLUE[2])
    c.line(5,15,26,15,PAPER[2]); c.line(7,16,24,16,BLUE[2])
    c.rect(12,26,20,27,BLUE[0]); c.line(13,26,18,26,BLUE[1])
    return c.finish()


def cooker_art():
    c = Canvas()
    c.line(10,3,9,4,PAPER[1]); c.line(9,4,11,6,PAPER[2])
    c.line(20,2,19,4,PAPER[1]); c.line(19,4,20,6,PAPER[2])
    c.rect(9,27,12,28,STEEL[0]); c.rect(21,27,24,28,STEEL[0])
    c.rect(3,15,6,20,STEEL[0]); c.rect(26,15,28,20,STEEL[0])
    c.rect(3,15,5,16,STEEL[1]); c.rect(27,16,28,17,STEEL[1])
    c.poly([(6,12),(25,12),(27,16),(26,25),(23,27),(8,27),(5,24),(5,16)],PAPER[0])
    c.poly([(6,14),(24,14),(24,25),(9,26),(6,23)],PAPER[1])
    c.poly([(6,14),(10,14),(9,23),(7,22)],PAPER[2])
    c.oval(16,12,11,4,STEEL[0]); c.oval(15,11,10,3,STEEL[1])
    c.line(7,10,21,9,STEEL[2]); c.rect(12,7,21,9,STEEL[0])
    c.rect(13,7,20,7,STEEL[2]); c.rect(13,8,15,8,STEEL[1])
    c.rect(11,18,21,23,STEEL[0]); c.rect(12,19,20,22,BLUE[0])
    c.rect(12,19,18,20,BLUE[1]); c.line(12,19,15,19,BLUE[2])
    c.rect(23,19,24,21,ORANGE[0]); c.rect(23,19,23,20,ORANGE[2])
    return c.finish()


def recall_art():
    c = Canvas()
    c.poly([(13,8),(21,7),(27,13),(27,22),(22,28),(13,28),(8,23),(8,14)],GOLD[0])
    c.poly([(13,8),(21,8),(26,13),(25,22),(21,26),(13,26),(9,22),(9,14)],GOLD[1])
    c.line(13,9,20,9,GOLD[2]); c.line(11,11,9,16,GOLD[2])
    c.poly([(15,13),(21,12),(23,16),(22,22),(16,23),(13,19)],PURPLE[0])
    c.poly([(16,14),(20,14),(21,17),(20,21),(16,21),(14,18)],PURPLE[1])
    c.line(16,14,19,14,PURPLE[2])
    c.line(17,18,11,18,BLUE[0],3); c.line(11,18,6,14,BLUE[0],3)
    c.line(6,14,7,9,BLUE[0],3)
    c.line(16,17,11,17,BLUE[2]); c.line(11,17,7,13,BLUE[1])
    c.poly([(9,4),(6,8),(7,11),(10,12),(12,9)],BLUE[0])
    c.poly([(9,5),(7,8),(8,10),(10,10),(11,8)],BLUE[1])
    c.rect(8,7,8,8,BLUE[2]); c.rect(3,6,3,7,BLUE[1])
    c.rect(4,4,4,4,BLUE[2])
    return c.finish()


def delve_art():
    c = Canvas()
    c.poly([(5,26),(9,23),(15,26),(15,29),(4,29)],WOOD[0])
    c.poly([(6,26),(10,24),(14,27),(7,28)],WOOD[1])
    c.rect(7,25,8,25,WOOD[2])
    c.line(12,10,23,21,WOOD[0],4); c.line(12,10,22,20,WOOD[1],2)
    c.line(12,10,22,20,WOOD[2])
    c.poly([(4,4),(11,2),(17,8),(12,13),(7,11),(3,7)],WOOD[0])
    c.poly([(4,4),(10,3),(15,8),(12,11),(8,10),(4,7)],WOOD[1])
    c.line(5,4,10,3,WOOD[2]); c.line(10,3,14,7,WOOD[2])
    # The D handle's opening is transparent, not a painted rectangle.
    c.poly([(6,5),(10,5),(13,8),(11,10),(8,8)],'.')
    c.poly([(18,15),(27,19),(27,24),(21,29),(14,25),(13,20)],STEEL[0])
    c.poly([(18,16),(25,19),(24,23),(20,27),(15,24),(15,20)],STEEL[1])
    c.poly([(18,17),(21,18),(18,25),(15,23)],STEEL[2])
    c.line(22,19,20,25,STEEL[0]); c.line(17,17,20,19,INK)
    c.rect(18,18,19,18,STEEL[2])
    return c.finish()


def injection_art():
    c = Canvas()
    c.poly([(5,8),(17,5),(23,11),(22,26),(6,28)], PAPER[0])
    c.poly([(5,8),(17,5),(17,12),(22,11),(21,25),(6,26)], PAPER[1])
    c.line(6,9,14,7,PAPER[2]); c.line(7,10,7,23,PAPER[2])
    c.poly([(18,7),(22,11),(18,11)], PAPER[2])
    c.line(9,15,15,14,PAPER[0]); c.line(9,19,12,18,PAPER[0])
    c.line(8,26,14,20,STEEL[1]); c.line(8,25,13,20,STEEL[2])
    c.poly([(12,19),(22,8),(26,12),(16,23)], STEEL[0])
    c.poly([(13,19),(22,9),(25,12),(16,22)], BLUE[1])
    c.poly([(13,19),(17,15),(20,18),(16,22)], PINK[1])
    c.line(14,19,22,10,BLUE[2]); c.line(16,21,18,19,PINK[2])
    c.line(22,9,25,6,STEEL[1],2)
    c.line(23,4,28,9,STEEL[0],2); c.line(23,4,27,8,STEEL[2])
    c.line(12,17,18,23,STEEL[0]); c.line(13,17,18,22,STEEL[2])
    return c.finish()


def residential_art():
    c = Canvas()
    c.line(6,25,4,27,BLUE[0],2); c.line(4,27,25,27,BLUE[0],2)
    c.line(6,26,24,26,BLUE[1]); c.line(25,26,27,22,BLUE[0],2)
    c.poly([(7,13),(15,6),(24,13),(24,24),(7,24)], PAPER[0])
    c.rect(8,13,21,23,PAPER[1]); c.rect(8,13,9,22,PAPER[2])
    c.poly([(4,13),(15,3),(27,13),(25,16),(15,8),(6,16)], BLUE[0])
    c.poly([(4,13),(15,3),(26,13),(24,13),(15,6),(6,14)], BLUE[1])
    c.line(6,12,15,4,BLUE[2])
    c.rect(12,16,16,23,WOOD[0]); c.rect(13,17,15,23,WOOD[1])
    c.rect(19,16,21,19,GOLD[0]); c.rect(19,16,20,18,GOLD[2])
    c.rect(24,18,28,22,BLUE[0]); c.rect(24,18,27,20,BLUE[1])
    c.rect(25,16,25,17,PAPER[2]); c.rect(28,16,28,17,PAPER[2])
    return c.finish()


def relay_art():
    c = Canvas()
    c.poly([(11,14),(15,12),(28,25),(25,28)], GOLD[0])
    c.poly([(12,14),(15,13),(27,25),(25,26)], GOLD[1])
    c.line(14,15,24,25,GOLD[2])
    c.poly([(18,21),(21,24),(18,27),(16,25)], GOLD[0])
    c.poly([(18,22),(20,24),(18,26),(17,25)], GOLD[1])
    c.line(17,24,18,23,GOLD[2])
    c.poly([(22,25),(24,27),(22,29),(20,27)], GOLD[0])
    c.line(21,27,22,26,GOLD[1])
    c.oval(10,10,7,7,ORANGE[0]); c.oval(9,9,6,6,ORANGE[1])
    c.line(5,7,8,4,ORANGE[2]); c.line(8,4,11,4,ORANGE[2])
    c.oval(9,8,3,3,INK); c.oval(9,8,2,2,STEEL[0]); c.line(8,7,9,6,STEEL[2])
    c.poly([(4,12),(6,10),(15,14),(13,17)], PAPER[0])
    c.poly([(5,12),(6,11),(14,14),(13,16)], PAPER[1])
    c.line(7,12,12,14,PAPER[2]); c.line(11,11,13,12,INK)
    c.line(13,12,12,14,INK)
    return c.finish()


def silent_art():
    c = Canvas()
    for x,y,w,h in ((21,3,3,3),(26,5,3,3),(26,10,3,3),(18,6,4,3)):
        c.rect(x,y,x+w-1,y+h-1,STEEL[0])
    c.oval(23,9,5,5,STEEL[0]); c.oval(22,8,4,4,STEEL[1])
    c.line(20,6,23,5,STEEL[2]); c.oval(23,8,1,1,INK)
    c.poly([(3,13),(20,9),(26,15),(24,26),(5,28)], PAPER[0])
    c.poly([(4,14),(20,10),(25,15),(23,25),(6,27)], PAPER[1])
    c.poly([(4,14),(16,21),(24,15),(20,10)], PAPER[2])
    c.line(6,25,11,19,PAPER[0]); c.line(18,21,23,24,PAPER[0])
    c.line(5,15,15,22,PAPER[0]); c.line(16,22,24,16,PAPER[0])
    c.oval(16,21,3,3,PURPLE[0]); c.oval(15,20,2,2,PURPLE[1])
    c.line(14,19,16,19,PURPLE[2])
    return c.finish()


def opus_art():
    c = Canvas()
    c.poly([(8,9),(22,7),(27,12),(25,27),(8,28),(5,22)], GOLD[0])
    c.poly([(9,10),(22,9),(25,13),(23,25),(9,26),(7,22)], GOLD[1])
    c.line(9,11,9,23,GOLD[2]); c.line(10,10,21,9,GOLD[2])
    c.poly([(11,13),(21,12),(23,15),(21,24),(12,24),(9,21)], PURPLE[0])
    c.poly([(12,14),(20,13),(22,15),(20,22),(12,22),(10,20)], PURPLE[1])
    c.line(12,15,13,21,PURPLE[2])
    c.oval(17,6,5,4,GOLD[0]); c.oval(16,5,4,3,GOLD[1])
    c.line(13,4,16,3,GOLD[2]); c.rect(13,9,21,10,INK)
    c.poly([(17,14),(14,19),(14,21),(16,23),(19,23),(21,20)], BLUE[0])
    c.poly([(17,15),(15,19),(15,21),(17,22),(19,21),(20,20)], BLUE[1])
    c.line(16,18,17,16,BLUE[2]); c.rect(9,27,11,29,GOLD[0]); c.rect(22,26,24,28,GOLD[0])
    return c.finish()


def reset_art():
    c = Canvas()
    c.rect(6,4,9,28,GOLD[0]); c.rect(23,4,26,28,GOLD[0])
    c.rect(6,5,7,27,GOLD[2]); c.rect(23,5,24,27,GOLD[1])
    c.poly([(10,7),(22,7),(21,12),(18,16),(21,20),(22,25),(10,25),(11,20),(14,16),(11,12)], BLUE[0])
    c.poly([(11,8),(21,8),(20,12),(16,16),(20,21),(21,24),(11,24),(12,20),(15,16),(12,12)], BLUE[1])
    c.line(12,9,13,12,BLUE[2]); c.line(12,21,12,23,BLUE[2])
    c.poly([(13,10),(20,10),(17,14),(15,13)], PAPER[1]); c.line(14,10,19,10,PAPER[2])
    c.line(16,15,16,19,PAPER[2]); c.poly([(12,24),(16,20),(20,24)], PAPER[1])
    c.line(13,23,16,21,PAPER[2])
    c.rect(4,3,28,5,GOLD[0]); c.rect(5,3,27,3,GOLD[2]); c.rect(5,4,27,4,GOLD[1])
    c.rect(4,27,28,29,GOLD[0]); c.rect(5,27,27,27,GOLD[2]); c.rect(5,28,26,28,GOLD[1])
    return c.finish()


def bench_art():
    c = Canvas()
    c.rect(7,15,9,28,STEEL[0]); c.rect(24,14,26,27,STEEL[0])
    c.rect(7,16,7,27,STEEL[2]); c.rect(24,15,24,26,STEEL[1])
    c.poly([(5,21),(21,18),(27,21),(11,25)], ORANGE[0])
    c.poly([(5,20),(21,17),(27,20),(11,23)], ORANGE[1])
    c.line(6,20,20,18,ORANGE[2]); c.line(11,24,25,21,INK)
    c.rect(13,25,15,28,STEEL[0]); c.line(13,25,13,28,STEEL[1])
    c.line(4,11,28,8,STEEL[0],3); c.line(4,10,28,7,STEEL[2])
    for x,y in ((4,10),(24,7)):
        c.oval(x+2,y,3,5,STEEL[0]); c.oval(x+1,y-1,2,4,STEEL[1])
        c.line(x,y-3,x,y+1,STEEL[2])
    c.poly([(12,8),(11,4),(14,6),(16,3),(18,6),(21,4),(20,8)], GOLD[0])
    c.poly([(13,7),(12,5),(14,7),(16,4),(18,7),(20,5),(19,7)], GOLD[1])
    c.line(14,8,19,8,GOLD[2])
    return c.finish()


def panic_art():
    c = Canvas()
    c.line(8,25,5,28,STEEL[0],2); c.line(5,28,3,25,STEEL[1])
    c.line(24,23,28,26,STEEL[0],2); c.line(28,26,28,28,GOLD[1])
    c.poly([(5,17),(23,14),(28,19),(25,26),(8,28),(4,23)], STEEL[0])
    c.poly([(5,17),(23,14),(27,18),(24,23),(8,25),(4,22)], STEEL[1])
    c.line(6,18,21,15,STEEL[2]); c.line(6,21,8,23,STEEL[2])
    c.rect(12,13,22,20,ORANGE[0]); c.rect(12,13,15,19,ORANGE[1])
    c.oval(16,12,10,7,ORANGE[0]); c.oval(15,10,9,6,ORANGE[1])
    c.line(9,7,15,5,ORANGE[2]); c.line(8,8,8,10,ORANGE[2])
    c.line(20,16,18,19,INK); c.line(18,19,21,21,INK)
    c.line(21,21,18,25,INK); c.line(19,25,21,22,STEEL[2])
    c.rect(7,21,8,22,GOLD[0]); c.rect(7,21,7,21,GOLD[2])
    return c.finish()


def overloaded_art():
    c = Canvas()
    c.poly([(7,9),(24,12),(25,21),(8,18)], BLUE[0])
    c.poly([(8,10),(23,13),(24,19),(9,17)], BLUE[1])
    c.line(10,11,21,13,BLUE[2]); c.line(12,14,14,16,INK)
    c.line(14,16,17,14,INK); c.line(17,14,19,18,INK)
    c.poly([(4,6),(9,7),(11,11),(10,20),(5,19),(3,15)], STEEL[0])
    c.poly([(4,7),(8,8),(9,11),(8,18),(5,17),(4,14)], STEEL[1])
    c.line(5,8,5,14,STEEL[2])
    c.poly([(23,10),(28,11),(29,15),(28,24),(23,23),(22,19)], STEEL[0])
    c.poly([(24,11),(27,12),(28,15),(26,22),(24,21)], STEEL[1])
    c.line(24,12,24,18,STEEL[2])
    c.poly([(12,18),(15,19),(13,24)], BLUE[1]); c.line(12,19,13,21,BLUE[2])
    c.poly([(18,20),(21,21),(19,27)], BLUE[0]); c.line(19,22,19,24,BLUE[2])
    c.line(16,6,16,9,BLUE[2]); c.line(14,7,18,7,BLUE[1])
    return c.finish()


def hardcoded_art():
    c = Canvas()
    c.poly([(4,8),(17,4),(24,9),(23,22),(10,26),(4,20)], STEEL[0])
    c.poly([(5,8),(17,5),(23,9),(10,13)], STEEL[2])
    c.poly([(5,10),(10,14),(22,10),(21,21),(10,24),(5,19)], STEEL[1])
    c.poly([(10,14),(22,10),(21,21),(10,24)], STEEL[0])
    c.poly([(15,12),(11,18),(12,21),(15,22),(18,19)], INK)
    c.poly([(15,14),(13,18),(13,20),(15,21),(17,19)], BLUE[0])
    c.line(14,18,15,16,BLUE[2]); c.rect(14,19,15,19,BLUE[1])
    c.line(6,11,6,18,STEEL[2]); c.line(10,22,10,15,STEEL[1])
    for x,y in ((24,17),(25,25)):
        c.poly([(x,y-3),(x-2,y),(x-2,y+2),(x,y+3),(x+2,y+2),(x+2,y)], BLUE[0])
        c.poly([(x,y-2),(x-1,y),(x-1,y+2),(x+1,y+2),(x+1,y)], BLUE[1])
        c.rect(x-1,y,x-1,y,BLUE[2])
    return c.finish()


def cake_art():
    c = Canvas()
    c.oval(16,26,13,3,STEEL[0]); c.oval(15,25,12,2,STEEL[2])
    c.poly([(5,15),(17,10),(27,16),(27,24),(15,28),(5,24)],PAPER[0])
    c.poly([(5,15),(16,19),(16,27),(5,23)],PAPER[1])
    c.poly([(16,19),(27,16),(27,24),(16,27)],WOOD[0])
    c.poly([(17,21),(26,18),(26,20),(17,23)],PAPER[1])
    c.line(17,25,26,22,PINK[1]); c.line(6,20,15,23,PINK[0],2)
    c.poly([(5,14),(17,9),(27,15),(16,20),(5,17)],PINK[0])
    c.poly([(5,14),(17,9),(27,15),(16,18)],PAPER[2])
    c.rect(6,16,8,18,PAPER[2]); c.rect(12,18,14,20,PAPER[1])
    c.rect(19,6,21,13,BLUE[0]); c.rect(19,6,20,12,BLUE[1])
    c.line(19,7,20,7,BLUE[2]); c.line(19,10,20,10,PAPER[2])
    c.poly([(20,2),(18,5),(19,6),(21,5)],ORANGE[1]); c.rect(20,4,20,5,PAPER[2])
    c.oval(11,13,2,1,PINK[1]); c.rect(10,12,10,12,PINK[2])
    return c.finish()


def guarded_bowl_art():
    c = Canvas()
    c.rect(11,26,22,28,BLUE[0]); c.rect(12,26,19,27,BLUE[1])
    c.poly([(4,13),(28,13),(26,23),(22,27),(11,27),(6,22)],BLUE[0])
    c.poly([(5,14),(25,14),(23,23),(20,25),(11,25),(7,21)],BLUE[1])
    c.poly([(5,15),(8,16),(9,22),(7,20)],BLUE[2])
    c.oval(16,13,12,4,PAPER[0]); c.oval(15,12,11,4,PAPER[1])
    for x,y in ((7,11),(10,8),(14,9),(18,8),(22,10),(10,12),(17,12),(23,12)):
        c.line(x,y,x+2,y-1,PAPER[2])
    c.line(5,15,11,17,BLUE[0]); c.line(22,16,27,14,BLUE[0])
    c.poly([(13,17),(22,17),(22,22),(18,26),(13,22)],STEEL[0])
    c.poly([(14,18),(21,18),(21,21),(18,24),(14,21)],STEEL[2])
    c.poly([(18,18),(21,18),(21,21),(18,24)],STEEL[1])
    c.line(15,19,17,19,PAPER[2])
    return c.finish()


def clock_art():
    c = Canvas()
    c.line(9,25,7,28,STEEL[0],2); c.line(23,25,25,28,STEEL[0],2)
    c.line(7,27,8,26,STEEL[2]); c.line(23,26,24,27,STEEL[1])
    c.line(8,10,12,13,STEEL[0],2); c.line(24,10,21,13,STEEL[0],2)
    c.poly([(4,8),(7,4),(11,4),(14,7),(9,11)],GOLD[0])
    c.poly([(5,7),(8,4),(11,5),(12,7),(8,9)],GOLD[1]); c.line(7,5,10,5,GOLD[2])
    c.poly([(20,7),(23,4),(26,5),(28,8),(23,11)],GOLD[0])
    c.poly([(21,7),(23,5),(26,6),(26,8),(23,9)],GOLD[1]); c.line(23,5,25,6,GOLD[2])
    c.oval(16,18,10,10,BLUE[0]); c.oval(15,17,9,9,BLUE[1])
    c.oval(16,18,8,8,PAPER[0]); c.oval(15,17,7,7,PAPER[2])
    c.line(15,11,15,12,GOLD[0]); c.line(9,17,10,17,GOLD[0]); c.line(21,17,22,17,GOLD[0])
    c.line(16,18,16,13,INK); c.line(16,18,20,21,INK)
    c.rect(15,17,16,18,GOLD[1]); c.line(10,22,13,24,PAPER[1])
    c.rect(15,4,17,6,STEEL[0]); c.rect(15,4,16,4,STEEL[2])
    return c.finish()


def memory_art():
    c = Canvas()
    c.oval(16,19,11,9,BLUE[0]); c.oval(15,18,10,8,BLUE[1])
    c.poly([(8,13),(24,13),(26,20),(23,25),(11,26),(6,21)],BLUE[1])
    c.line(8,13,23,13,BLUE[2]); c.line(8,16,7,20,BLUE[2])
    c.line(10,25,20,26,BLUE[2]); c.line(24,21,23,24,BLUE[0])
    c.poly([(18,18),(24,15),(23,22),(18,20)],ORANGE[0])
    c.poly([(20,18),(23,16),(22,20)],ORANGE[2])
    c.oval(14,19,6,4,ORANGE[0]); c.oval(13,18,5,3,ORANGE[1])
    c.line(11,16,15,16,ORANGE[2]); c.rect(10,18,10,18,INK)
    c.poly([(14,21),(17,21),(15,24)],ORANGE[1])
    c.rect(19,10,20,11,PAPER[2]); c.rect(23,7,24,8,BLUE[2])
    c.rect(9,5,22,8,WOOD[0]); c.rect(10,5,21,6,WOOD[2])
    c.line(10,8,21,8,PAPER[1]); c.rect(11,9,20,10,BLUE[0])
    c.line(10,4,13,4,WOOD[1]); c.line(18,4,21,4,WOOD[1])
    return c.finish()


def sanity_art():
    c = Canvas()
    c.poly([(20,19),(23,19),(29,26),(26,29),(19,22)],WOOD[0])
    c.poly([(21,20),(23,20),(28,26),(26,27)],WOOD[1]); c.line(22,20,26,24,WOOD[2])
    c.oval(13,13,10,10,STEEL[0]); c.oval(12,12,9,9,STEEL[2])
    c.oval(13,13,8,8,BLUE[0]); c.oval(12,12,7,7,BLUE[1])
    c.line(7,8,9,6,BLUE[2]); c.line(6,10,6,13,BLUE[2])
    c.oval(13,13,4,4,PAPER[1]); c.oval(13,13,2,2,ORANGE[0])
    c.line(13,7,13,9,STEEL[0]); c.line(13,17,13,19,STEEL[0])
    c.line(7,13,9,13,STEEL[0]); c.line(17,13,19,13,STEEL[0])
    c.rect(11,11,12,12,PAPER[2]); c.line(19,20,21,22,STEEL[2])
    return c.finish()


def receipt_art():
    c = Canvas()
    c.poly([(9,5),(24,4),(25,21),(22,28),(19,26),(16,28),(13,26),(10,28),(8,23)],PAPER[0])
    c.poly([(9,5),(22,5),(23,20),(21,25),(18,24),(16,26),(13,24),(10,25)],PAPER[1])
    c.line(10,8,10,22,PAPER[2]); c.line(12,6,21,6,PAPER[2])
    c.oval(9,6,4,3,STEEL[0]); c.oval(9,5,4,2,PAPER[2]); c.rect(8,5,10,5,PAPER[0])
    c.line(14,10,19,10,BLUE[0]); c.line(19,10,19,17,BLUE[0]); c.line(14,17,19,17,BLUE[0])
    for x,y in ((14,10),(19,14),(14,18)):
        c.oval(x,y,2,2,GOLD[0]); c.oval(x-0.5,y-0.5,1,1,GOLD[2])
    c.line(12,22,18,22,PAPER[0]); c.line(13,24,19,24,PAPER[2])
    return c.finish()


def tibo_art():
    c = Canvas()
    c.poly([(7,13),(21,10),(26,14),(26,26),(12,29),(6,25)],STEEL[0])
    c.poly([(7,13),(21,10),(26,14),(12,17)],STEEL[2])
    c.poly([(7,14),(12,18),(12,27),(7,24)],STEEL[1])
    c.poly([(13,18),(25,15),(25,25),(13,28)],BLUE[0])
    c.poly([(14,19),(18,18),(18,25),(14,26)],BLUE[1]); c.line(14,19,16,19,BLUE[2])
    c.poly([(20,17),(23,17),(23,24),(20,25)],BLUE[1]); c.line(20,18,22,18,BLUE[2])
    c.rect(15,6,18,14,GOLD[0]); c.rect(15,6,16,13,GOLD[2])
    for x in (11,22):
        c.oval(x,6,5,3,GOLD[0]); c.oval(x-1,5,4,2,GOLD[1])
        c.oval(x,6,2,1,INK); c.line(x-2,4,x,4,GOLD[2])
    c.line(8,18,9,20,STEEL[2]); c.rect(9,23,9,23,INK)
    return c.finish()


def badge_art():
    c = Canvas()
    c.poly([(5,10),(24,8),(27,11),(27,26),(8,29),(4,26)],STEEL[0])
    c.poly([(5,10),(24,8),(26,10),(8,13)],STEEL[2])
    c.poly([(6,14),(25,11),(25,25),(8,27),(6,25)],PAPER[0])
    c.poly([(7,14),(16,13),(16,25),(8,26)],GOLD[1])
    c.poly([(17,13),(24,12),(24,24),(17,25)],STEEL[1])
    c.oval(16,17,4,4,INK); c.oval(15,16,3,3,GOLD[2])
    c.poly([(17,13),(19,14),(19,18),(17,20)],STEEL[0])
    c.poly([(12,21),(18,20),(21,22),(21,24),(11,25),(11,23)],INK)
    c.line(12,23,15,22,GOLD[2]); c.line(18,22,19,23,STEEL[0])
    c.rect(12,4,18,11,STEEL[0]); c.rect(12,4,16,9,STEEL[2])
    c.rect(14,5,16,7,INK); c.line(13,11,17,11,STEEL[1])
    c.poly([(23,21),(25,21),(25,24),(23,24)],PAPER[1])
    return c.finish()


def banana_art():
    c = Canvas()
    c.poly([(8,4),(11,3),(12,8),(16,13),(21,15),(26,12),(25,18),(21,22),(14,22),(8,16),(7,9)],YELLOW[0])
    c.poly([(8,5),(10,4),(11,10),(16,16),(21,17),(24,15),(23,19),(19,21),(14,20),(9,15)],YELLOW[1])
    c.line(9,8,11,13,YELLOW[2]); c.line(12,15,16,18,YELLOW[2])
    c.poly([(12,14),(14,18),(13,24),(8,28),(10,20)],PAPER[0])
    c.poly([(12,15),(13,18),(11,23),(9,25),(11,19)],PAPER[2])
    c.poly([(16,20),(20,21),(25,26),(22,28),(18,25)],YELLOW[0])
    c.poly([(17,21),(20,22),(23,26),(21,26),(18,24)],YELLOW[2])
    c.line(8,4,10,3,WOOD[0]); c.rect(25,12,26,13,WOOD[0])
    c.oval(24,24,4,2,BLUE[0]); c.oval(23,23,3,1,BLUE[1]); c.rect(22,22,23,22,BLUE[2])
    return c.finish()


def undo_art():
    c = Canvas()
    c.poly([(19,13),(26,3),(28,4),(28,7),(22,16)],WOOD[0])
    c.poly([(20,13),(26,4),(27,4),(26,8),(21,14)],WOOD[1])
    c.line(22,10,26,5,WOOD[2])
    c.poly([(16,13),(19,11),(24,15),(21,19)],STEEL[0])
    c.poly([(17,13),(19,12),(22,15),(20,17)],STEEL[2])
    c.poly([(15,15),(20,19),(17,24),(10,26),(5,24),(11,21)],PAPER[0])
    c.poly([(15,16),(18,19),(15,23),(9,25),(7,24),(12,21)],PAPER[1])
    c.line(14,18,10,23,PAPER[2]); c.line(17,20,14,24,WOOD[0])
    c.line(5,27,10,28,BLUE[1]); c.line(12,27,16,26,BLUE[0])
    c.oval(7,14,3,3,BLUE[0]); c.oval(6,13,2,2,BLUE[1]); c.rect(5,12,5,13,BLUE[2])
    c.rect(3,20,4,21,BLUE[1]); c.rect(5,18,5,18,BLUE[2])
    return c.finish()


def finger_art():
    c = Canvas()
    c.poly([(9,18),(5,13),(3,14),(5,21),(10,25)],PAPER[0])
    c.poly([(8,19),(5,15),(4,15),(6,20),(10,23)],PAPER[1])
    for x,top in ((8,10),(12,7),(16,4),(20,6),(24,10)):
        c.rect(x,top+1,x+2,19,PAPER[0]); c.rect(x+1,top,x+1,top,PAPER[1])
        c.rect(x,top+1,x+1,18,PAPER[1]); c.rect(x,top+1,x,top+3,PAPER[2])
    c.poly([(8,17),(26,17),(26,22),(22,26),(11,26),(8,23)],PAPER[0])
    c.poly([(9,17),(23,17),(23,22),(20,24),(11,24),(9,22)],PAPER[1])
    c.line(10,18,19,18,PAPER[2]); c.line(12,21,18,22,PAPER[0])
    c.line(22,19,22,22,PAPER[0]); c.line(8,20,10,22,PAPER[2])
    c.poly([(10,25),(23,25),(23,28),(11,29),(9,27)],BLUE[0])
    c.rect(11,25,22,26,BLUE[1]); c.line(11,25,20,25,BLUE[2])
    c.line(12,28,20,28,BLUE[1])
    return c.finish()


def preview_art():
    c = Canvas()
    c.poly([(3,5),(18,3),(21,20),(6,23)],STEEL[0])
    c.poly([(4,5),(17,4),(19,19),(6,21)],PAPER[0])
    c.poly([(5,6),(16,5),(18,18),(7,20)],BLUE[0])
    c.line(5,6,16,5,BLUE[2]); c.line(5,7,6,17,BLUE[1])
    c.oval(11,10,3,3,PAPER[1]); c.oval(10,9,2,2,PAPER[2])
    c.poly([(8,14),(14,13),(17,18),(7,19)],PAPER[1])
    c.poly([(11,12),(27,10),(29,27),(13,29)],STEEL[0])
    c.poly([(12,12),(26,11),(28,26),(14,28)],PAPER[0])
    c.poly([(13,13),(25,12),(26,25),(15,26)],BLUE[0])
    c.line(13,13,25,12,BLUE[2]); c.line(13,14,14,23,BLUE[1])
    c.oval(19,17,3,3,PAPER[1]); c.oval(18,16,2,2,PAPER[2])
    c.poly([(16,21),(22,20),(25,24),(15,25)],PAPER[1])
    c.line(17,21,20,21,PAPER[2]); c.line(23,23,24,24,PAPER[0])
    return c.finish()


def challenge_art():
    c = Canvas()
    c.poly([(10,16),(17,18),(15,28),(10,27)],BLUE[0])
    c.poly([(11,18),(14,19),(13,26),(11,25)],BLUE[1])
    c.line(11,19,11,24,BLUE[2]); c.rect(15,19,17,21,STEEL[0])
    c.poly([(4,11),(10,10),(25,4),(26,21),(10,17),(4,16)],GOLD[0])
    c.poly([(5,11),(11,11),(24,5),(24,12),(10,14),(5,14)],GOLD[1])
    c.line(12,11,23,7,GOLD[2]); c.line(5,11,8,11,GOLD[2])
    c.line(10,15,23,18,GOLD[0])
    c.oval(25,12,3,8,STEEL[0]); c.oval(24,11,2,6,STEEL[1])
    c.oval(25,12,1,5,BLUE[0]); c.line(24,7,24,9,STEEL[2])
    c.rect(4,12,5,15,STEEL[0]); c.rect(4,12,4,13,STEEL[2])
    return c.finish()


def wire_art():
    c = Canvas()
    c.poly([(6,11),(10,11),(10,21),(13,24),(20,24),(23,21),(23,12),
            (27,12),(27,22),(22,28),(12,28),(6,23)],BLUE[0])
    c.line(7,12,7,21,BLUE[2]); c.line(8,22,13,26,BLUE[1])
    c.line(13,26,21,26,BLUE[1]); c.line(22,25,25,21,BLUE[1])
    c.line(24,14,24,21,BLUE[2]); c.line(13,24,19,24,BLUE[2])
    c.rect(6,10,10,12,GOLD[0]); c.rect(6,10,9,10,GOLD[2])
    c.line(7,9,5,6,GOLD[1]); c.line(8,9,8,5,GOLD[2]); c.line(10,9,12,7,GOLD[1])
    c.rect(23,11,27,13,GOLD[0]); c.rect(23,11,26,11,GOLD[2])
    c.line(24,10,22,8,GOLD[1]); c.line(25,10,25,7,GOLD[2]); c.line(27,10,28,8,GOLD[1])
    c.poly([(17,3),(18,6),(21,7),(18,8),(17,11),(16,8),(13,7),(16,6)],ORANGE[1])
    c.rect(17,5,17,8,ORANGE[2]); c.rect(16,7,18,7,ORANGE[2])
    return c.finish()


def retort_art():
    c = Canvas()
    c.oval(15,27,9,2,STEEL[0]); c.line(8,26,21,26,STEEL[2])
    for y in (20,23):
        c.line(10,y,20,y+2,STEEL[0]); c.line(10,y,20,y,STEEL[2])
        c.line(10,y+1,19,y+3,STEEL[1])
    c.poly([(9,16),(22,16),(22,21),(10,21)],PAPER[0])
    c.rect(10,17,21,19,PAPER[1]); c.line(11,17,20,17,PAPER[2])
    c.line(13,20,18,20,ORANGE[0])
    c.poly([(7,8),(11,4),(22,4),(26,7),(26,15),(22,18),(10,17),(6,13)],ORANGE[0])
    c.poly([(8,8),(11,5),(21,5),(24,8),(24,13),(20,15),(11,15),(8,12)],ORANGE[1])
    c.line(11,6,20,6,ORANGE[2]); c.line(9,8,9,10,ORANGE[2])
    c.line(19,11,23,12,ORANGE[0])
    c.oval(8,14,3,4,ORANGE[0]); c.oval(7,13,2,3,ORANGE[1])
    c.line(6,12,7,11,ORANGE[2])
    return c.finish()


def note_art():
    c = Canvas()
    c.poly([(5,9),(24,5),(28,22),(23,27),(9,29)],PAPER[0])
    c.poly([(6,10),(23,6),(26,22),(22,25),(10,27)],PAPER[1])
    c.line(7,11,20,8,PAPER[2]); c.line(7,12,10,24,PAPER[2])
    c.poly([(22,24),(26,22),(24,26)],PAPER[2])
    c.line(21,25,23,21,PAPER[0]); c.line(11,24,16,23,PAPER[0])
    for x,y in ((11,16),(18,13),(20,20)):
        c.oval(x,y,2,2,ORANGE[0]); c.rect(x-1,y-1,x,y-1,ORANGE[1])
        c.rect(x,y,x,y,INK); c.rect(x+1,y+1,x+1,y+1,PAPER[2])
    c.line(15,6,17,11,STEEL[0]); c.line(14,6,16,10,STEEL[2])
    c.oval(13,5,4,2,ORANGE[0]); c.oval(12,4,3,1,ORANGE[1])
    c.line(11,4,13,4,ORANGE[2])
    return c.finish()


def base_art():
    c = Canvas()
    c.oval(16,27,10,2,STEEL[0]); c.oval(15,26,9,1,STEEL[1])
    c.line(8,26,18,26,STEEL[2]); c.rect(15,22,17,26,STEEL[0])
    c.rect(15,22,15,25,STEEL[2])
    c.poly([(11,13),(20,13),(21,19),(18,23),(13,23),(10,19)],WOOD[0])
    c.poly([(12,14),(18,14),(18,20),(16,22),(13,21),(11,18)],WOOD[1])
    c.line(12,14,16,14,WOOD[2]); c.line(12,15,12,18,WOOD[2])
    c.line(9,14,6,21,WOOD[0],2); c.line(8,14,6,19,WOOD[2])
    c.line(22,14,25,21,WOOD[0],2); c.line(22,15,24,19,WOOD[1])
    c.oval(9,13,2,2,STEEL[0]); c.rect(8,12,9,12,STEEL[2])
    c.oval(22,13,2,2,STEEL[0]); c.rect(21,12,22,12,STEEL[1])
    c.rect(14,10,17,13,WOOD[0]); c.rect(14,10,15,12,WOOD[2])
    c.oval(16,7,5,5,WOOD[0]); c.oval(15,6,4,4,WOOD[1])
    c.line(13,4,15,3,WOOD[2]); c.line(12,5,12,7,WOOD[2])
    c.oval(16,17,2,2,BLUE[0]); c.rect(15,16,16,17,BLUE[1]); c.rect(15,16,15,16,BLUE[2])
    return c.finish()


def adapter_art():
    c = Canvas()
    c.line(5,27,10,23,STEEL[0],3); c.line(4,26,9,22,STEEL[1])
    for x,y in ((10,8),(16,6),(22,4)):
        c.rect(x,y,x+2,y+7,GOLD[0]); c.rect(x,y,x+1,y+5,GOLD[1])
        c.rect(x,y,x,y+3,GOLD[2]); c.rect(x,y+5,x+2,y+6,INK)
    c.poly([(8,13),(22,9),(27,13),(27,23),(13,28),(8,24)],BLUE[0])
    c.poly([(9,13),(22,10),(26,13),(13,18)],BLUE[2])
    c.poly([(9,15),(13,19),(13,26),(9,23)],BLUE[1])
    c.poly([(14,19),(26,15),(26,22),(14,26)],BLUE[1])
    c.line(14,19,25,15,BLUE[2]); c.line(14,26,25,22,BLUE[0])
    for x,y in ((17,20),(22,18)):
        c.rect(x,y,x+1,y+2,INK); c.rect(x,y+3,x+1,y+3,STEEL[1])
    c.rect(19,23,20,24,INK); c.rect(19,25,20,25,STEEL[1])
    return c.finish()


def weights_art():
    c = Canvas()
    c.oval(16,24,12,4,STEEL[0]); c.rect(4,21,28,24,STEEL[0])
    c.oval(16,21,12,4,STEEL[1]); c.oval(15,20,10,3,STEEL[2])
    c.line(6,24,9,26,STEEL[1]); c.line(11,27,22,26,STEEL[1])
    c.oval(16,17,10,4,BLUE[0]); c.rect(6,14,26,17,BLUE[0])
    c.oval(16,14,10,4,BLUE[1]); c.oval(15,13,8,3,BLUE[2])
    c.line(9,17,13,19,BLUE[1]); c.line(15,19,23,17,BLUE[1])
    c.oval(16,14,4,2,INK)
    c.rect(14,7,17,14,GOLD[0]); c.rect(14,7,15,14,GOLD[1]); c.line(14,8,14,12,GOLD[2])
    c.oval(16,6,5,3,GOLD[0]); c.oval(15,5,4,2,GOLD[1])
    c.oval(15,5,2,1,INK); c.line(12,4,15,3,GOLD[2])
    return c.finish()


def tiny_art():
    c = Canvas()
    c.line(8,24,4,22,STEEL[0]); c.line(4,22,4,18,STEEL[1]); c.line(4,18,6,17,STEEL[2])
    c.rect(12,10,14,18,GOLD[0]); c.rect(12,10,12,16,GOLD[2])
    c.oval(9,9,4,3,GOLD[0]); c.oval(8,8,3,2,GOLD[1]); c.rect(8,8,9,8,INK)
    c.oval(17,8,4,3,GOLD[0]); c.oval(16,7,3,2,GOLD[1]); c.rect(16,7,17,7,INK)
    c.line(7,6,9,6,GOLD[2]); c.line(15,5,17,5,GOLD[2])
    c.rect(11,25,14,28,PINK[0]); c.rect(20,24,24,27,PINK[0])
    c.line(11,27,13,27,PINK[1]); c.line(21,26,23,26,PINK[1])
    c.oval(16,22,9,5,STEEL[0]); c.oval(14,21,7,4,STEEL[1])
    c.poly([(19,18),(23,18),(28,21),(28,23),(21,26),(17,24)],STEEL[1])
    c.line(10,19,15,18,STEEL[2]); c.line(22,19,25,20,STEEL[2])
    c.oval(17,16,4,4,STEEL[0]); c.oval(16,15,3,3,PINK[0]); c.oval(15,14,2,2,PINK[1])
    c.rect(14,13,15,13,PINK[2]); c.rect(23,21,23,21,INK)
    c.rect(28,22,28,23,PINK[0]); c.line(19,24,22,25,STEEL[0])
    return c.finish()


def open_weights_art():
    c = Canvas()
    c.line(11,15,11,8,GOLD[0],3); c.line(11,8,15,4,GOLD[0],3)
    c.line(15,4,20,4,GOLD[0],3); c.line(20,4,23,7,GOLD[0],3)
    c.line(10,14,10,8,GOLD[2]); c.line(11,7,15,3,GOLD[2]); c.line(16,3,20,3,GOLD[2])
    c.line(12,8,15,5,GOLD[1]); c.line(15,5,20,5,GOLD[1])
    c.poly([(9,14),(22,14),(26,25),(24,28),(7,28),(5,25)],STEEL[0])
    c.poly([(9,14),(21,14),(23,17),(7,17)],STEEL[2])
    c.poly([(7,18),(22,18),(24,25),(8,26)],STEEL[1])
    c.line(8,18,6,24,STEEL[2]); c.line(9,27,23,27,STEEL[0])
    c.rect(14,20,18,24,GOLD[0]); c.rect(14,20,17,22,GOLD[1]); c.rect(14,20,15,20,GOLD[2])
    for x,y in ((5,9),(27,6)):
        c.oval(x-1,y-2,2,1,BLUE[2]); c.oval(x+2,y-1,1,2,STEEL[2])
        c.oval(x,y+1,1.5,2,BLUE[0]); c.rect(x,y,x,y+1,BLUE[1])
    return c.finish()


def herd_bell_art():
    c = Canvas()
    c.oval(15,7,6,4,BLUE[0]); c.oval(14,6,5,3,BLUE[1]); c.oval(15,7,3,2,'.')
    c.line(10,5,13,3,BLUE[2]); c.rect(18,5,19,7,GOLD[0]); c.rect(18,5,18,6,GOLD[2])
    c.poly([(10,10),(21,10),(23,14),(25,23),(27,25),(25,27),(7,27),(5,25),(8,22)],GOLD[0])
    c.poly([(10,11),(20,11),(22,15),(23,23),(9,23)],GOLD[1])
    c.poly([(11,12),(15,11),(14,22),(10,23)],GOLD[2])
    c.line(21,15,23,23,GOLD[0]); c.oval(16,25,10,2,GOLD[2])
    c.oval(16,26,8,1.5,WOOD[0]); c.oval(16,27,2,2,GOLD[0]); c.rect(15,26,16,27,GOLD[1])
    return c.finish()


def come_back_art():
    c = Canvas()
    c.line(7,22,3,20,STEEL[0],2); c.line(3,20,3,13,STEEL[0],2)
    c.line(3,13,7,10,STEEL[0],2); c.line(7,10,10,12,STEEL[0],2)
    c.line(3,18,3,14,STEEL[2]); c.line(4,12,7,10,STEEL[1])
    c.poly([(7,21),(23,19),(28,22),(27,27),(8,29),(5,26)],STEEL[0])
    c.poly([(7,22),(23,20),(27,22),(10,25)],STEEL[2]); c.line(10,27,25,25,STEEL[1])
    c.poly([(13,7),(20,5),(25,8),(24,22),(14,24),(11,21)],BLUE[0])
    c.poly([(13,7),(20,5),(24,8),(15,10)],BLUE[2])
    c.poly([(14,10),(23,8),(22,21),(14,22)],BLUE[1]); c.line(14,10,13,20,BLUE[2])
    c.rect(16,3,20,5,GOLD[0]); c.rect(16,3,19,3,GOLD[2]); c.rect(16,4,19,5,GOLD[1])
    c.poly([(7,12),(10,11),(13,15),(10,18),(7,16)],STEEL[0])
    c.line(8,12,10,12,STEEL[2]); c.line(10,14,12,13,GOLD[1]); c.line(11,16,14,15,GOLD[2])
    c.rect(17,17,19,20,GOLD[0]); c.rect(17,17,18,19,GOLD[2])
    return c.finish()


def release_art():
    c = Canvas()
    c.poly([(5,10),(20,6),(27,10),(27,25),(12,29),(5,25)],BLUE[0])
    c.poly([(5,10),(20,6),(27,10),(12,14)],BLUE[2])
    c.poly([(6,12),(11,15),(11,27),(6,24)],BLUE[1])
    c.poly([(13,15),(26,11),(26,24),(13,27)],BLUE[1])
    c.line(14,16,24,13,BLUE[2]); c.line(12,15,12,27,INK)
    c.poly([(10,9),(13,8),(20,12),(17,13)],WOOD[2]); c.poly([(17,13),(20,12),(20,25),(17,26)],WOOD[1])
    c.line(18,14,18,24,WOOD[2]); c.line(6,20,10,23,BLUE[0])
    c.oval(21,19,5,5,GOLD[0]); c.oval(20,18,4,4,GOLD[1]); c.oval(20,18,3,3,STEEL[2])
    c.line(20,18,20,15,STEEL[0]); c.line(20,18,22,19,STEEL[0]); c.rect(19,17,20,18,INK)
    c.rect(18,12,21,13,GOLD[0]); c.rect(18,12,20,12,GOLD[2])
    c.oval(8,5,3,2,GOLD[0]); c.oval(7,4,2,1,GOLD[1]); c.rect(7,5,8,10,GOLD[0]); c.rect(7,6,7,9,GOLD[2])
    return c.finish()


def baguette_art():
    c = Canvas()
    c.poly([(5,22),(19,5),(24,3),(28,6),(28,11),(12,28),(7,29),(3,26)],WOOD[0])
    c.poly([(5,22),(20,5),(24,4),(27,7),(26,11),(11,27),(7,28),(4,25)],GOLD[0])
    c.poly([(5,22),(20,6),(24,5),(26,7),(24,12),(10,26),(7,27),(5,25)],GOLD[1])
    c.line(7,22,19,8,GOLD[2]); c.line(20,7,23,5,GOLD[2])
    for x,y in ((11,21),(16,15),(21,9)):
        c.line(x-2,y-2,x+2,y+2,WOOD[0],2)
        c.line(x-2,y-2,x+1,y+1,PAPER[1])
        c.line(x-1,y-2,x+2,y+1,PAPER[2])
    c.poly([(4,23),(7,21),(13,26),(10,29),(6,28)],BLUE[0])
    c.poly([(4,23),(6,22),(12,27),(10,28)],BLUE[1]); c.line(5,23,10,27,BLUE[2])
    return c.finish()


def boots_art():
    c = Canvas()
    c.poly([(7,4),(16,5),(16,15),(20,17),(20,21),(6,21),(5,18)],WOOD[0])
    c.poly([(8,6),(14,7),(13,15),(18,18),(17,19),(7,19)],WOOD[1])
    c.line(8,8,8,15,WOOD[2]); c.rect(7,4,15,7,BLUE[0]); c.rect(7,4,14,5,BLUE[2])
    c.line(6,20,19,20,STEEL[0]); c.line(7,19,15,19,STEEL[1])
    c.poly([(17,10),(25,9),(25,21),(28,23),(28,27),(14,29),(12,27),(13,24),(16,22)],WOOD[0])
    c.poly([(18,12),(23,11),(23,21),(26,24),(26,26),(15,27),(14,25),(18,22)],WOOD[1])
    c.line(18,14,18,21,WOOD[2]); c.line(17,24,23,23,WOOD[2])
    c.poly([(16,10),(25,8),(26,12),(16,14)],BLUE[0]); c.line(17,10,24,9,BLUE[2])
    c.line(17,12,24,11,BLUE[1]); c.rect(18,17,23,19,STEEL[0]); c.rect(20,17,22,19,STEEL[2]); c.rect(21,18,21,18,WOOD[0])
    c.line(15,28,27,26,STEEL[0]); c.line(16,27,25,25,STEEL[1])
    c.line(3,24,8,24,BLUE[2]); c.line(3,27,9,27,BLUE[1]); c.line(9,27,11,25,BLUE[1])
    return c.finish()


def kitten_art():
    c = Canvas()
    c.oval(23,23,5,4,ORANGE[0]); c.line(26,22,28,17,ORANGE[0],3); c.line(28,17,26,13,ORANGE[0],3)
    c.line(26,21,27,17,ORANGE[1],2); c.line(27,17,25,14,ORANGE[2])
    c.oval(15,22,8,6,ORANGE[0]); c.oval(13,21,6,5,ORANGE[1]); c.oval(15,23,4,4,PAPER[1])
    c.oval(9,27,4,2,ORANGE[1]); c.oval(20,27,4,2,ORANGE[0]); c.line(7,26,10,26,ORANGE[2]); c.line(18,26,21,26,ORANGE[1])
    c.poly([(5,12),(5,3),(11,6),(20,6),(25,3),(25,13),(22,19),(9,20)],ORANGE[0])
    c.oval(15,12,10,7,ORANGE[1]); c.poly([(6,4),(10,7),(7,10)],PAPER[1]); c.poly([(23,5),(20,8),(24,10)],PAPER[0])
    c.line(10,6,17,5,ORANGE[2]); c.line(6,11,6,14,ORANGE[2])
    c.oval(15,16,5,3,PAPER[1]); c.oval(13,15,3,2,PAPER[2])
    c.rect(9,11,10,13,INK); c.rect(20,11,21,13,INK); c.line(14,14,16,14,ORANGE[0]); c.rect(15,15,15,16,INK)
    c.line(10,17,7,16,ORANGE[0]); c.line(20,17,23,16,ORANGE[0])
    c.oval(3,20,1,2,BLUE[0]); c.rect(3,19,3,20,BLUE[2])
    return c.finish()


def compass_art():
    c = Canvas()
    c.poly([(25,5),(28,5),(28,28),(5,28),(5,24),(24,24)],STEEL[0])
    c.rect(25,6,26,25,STEEL[2]); c.rect(6,25,24,26,STEEL[1])
    for y in (10,17,23): c.line(26,y,28,y,INK)
    for x in (11,18,24): c.line(x,26,x,28,INK)
    c.rect(12,3,17,6,GOLD[0]); c.line(12,3,16,3,GOLD[2])
    c.oval(15,15,10,10,GOLD[0]); c.oval(14,14,9,9,GOLD[1]); c.oval(14,14,7,7,BLUE[0])
    c.oval(13,13,6,6,BLUE[1]); c.line(9,8,13,6,GOLD[2]); c.line(6,11,6,15,GOLD[2])
    c.poly([(9,9),(14,16),(21,21),(16,14)],STEEL[2])
    c.poly([(14,16),(21,21),(16,14)],ORANGE[1]); c.line(16,16,20,20,ORANGE[2])
    c.oval(15,15,2,2,GOLD[0]); c.rect(14,14,15,15,GOLD[2])
    return c.finish()


def apology_art():
    c = Canvas()
    c.line(6,28,10,4,WOOD[0],3); c.line(5,27,9,5,WOOD[2]); c.line(7,25,10,5,WOOD[1])
    c.oval(10,4,2,2,GOLD[0]); c.rect(9,3,10,3,GOLD[2])
    c.poly([(11,6),(16,5),(21,8),(28,7),(26,17),(22,19),(17,16),(10,16)],PAPER[0])
    c.poly([(11,7),(16,6),(21,9),(27,8),(25,16),(22,17),(17,14),(11,15)],PAPER[1])
    c.poly([(12,7),(16,6),(18,8),(17,12),(11,13)],PAPER[2])
    c.poly([(22,10),(26,9),(24,14),(22,15)],PAPER[2])
    c.line(18,8,17,13,PAPER[0]); c.line(21,10,20,14,PAPER[0])
    c.oval(21,25,3,3,BLUE[0]); c.oval(20,24,2,2,BLUE[1]); c.rect(19,23,20,23,BLUE[2])
    c.rect(26,23,27,23,BLUE[1]); c.rect(27,27,28,27,BLUE[2])
    return c.finish()


def again_art():
    c = Canvas()
    c.poly([(4,5),(8,3),(25,12),(28,16),(26,20),(8,29),(4,27),(3,24),(18,16),(4,9)],WOOD[0])
    c.poly([(5,5),(8,4),(24,13),(26,16),(24,19),(7,27),(5,26),(5,24),(21,16),(5,8)],WOOD[1])
    c.line(6,5,23,14,WOOD[2]); c.line(6,24,21,17,WOOD[2])
    c.line(7,8,18,14,WOOD[0]); c.line(9,25,20,20,WOOD[0])
    c.poly([(19,10),(22,11),(27,15),(26,20),(22,22),(20,19),(23,16)],PAPER[0])
    c.poly([(19,10),(21,11),(26,15),(25,19),(22,20),(21,18),(24,16)],PAPER[1])
    c.line(20,11,25,15,PAPER[2]); c.line(23,16,25,17,PAPER[0]); c.line(22,19,24,18,PAPER[2])
    c.rect(23,14,24,15,PINK[0]); c.rect(24,15,25,16,PINK[1])
    c.poly([(26,25),(28,25),(29,27),(27,29),(24,28)],WOOD[0])
    c.poly([(26,26),(28,26),(27,28),(25,27)],WOOD[2])
    return c.finish()


def confident_art():
    c = Canvas()
    c.poly([(12,19),(17,18),(19,27),(16,29),(13,27)],WOOD[0])
    c.poly([(13,20),(16,20),(17,26),(15,27)],WOOD[1]); c.line(14,21,15,25,WOOD[2])
    c.poly([(5,12),(12,12),(24,6),(27,7),(28,23),(25,25),(12,19),(5,19)],GOLD[0])
    c.poly([(6,13),(12,13),(24,7),(25,10),(13,16),(6,16)],GOLD[2])
    c.poly([(6,17),(13,17),(24,12),(25,22),(13,18),(6,18)],GOLD[1])
    c.oval(25,15,3,9,GOLD[0]); c.oval(25,14,2,7,GOLD[2])
    c.oval(25,15,1,5,WOOD[0]); c.rect(4,14,6,18,STEEL[0]); c.rect(4,14,5,15,STEEL[2])
    c.line(17,10,18,14,INK); c.line(18,14,17,17,INK); c.line(18,11,19,14,GOLD[2])
    c.line(8,20,6,23,STEEL[0]); c.line(6,23,8,25,STEEL[0])
    c.oval(8,26,3,1.5,PINK[0]); c.line(6,25,9,25,PINK[2])
    return c.finish()


def correction_art():
    c = Canvas()
    c.line(5,27,16,25,STEEL[0],2); c.rect(8,27,9,27,STEEL[1])
    c.poly([(7,17),(17,7),(27,14),(17,25),(12,26),(5,21)],PINK[0])
    c.poly([(7,17),(17,8),(25,14),(16,23)],PINK[1])
    c.poly([(7,17),(17,8),(20,10),(10,20)],PINK[2])
    c.poly([(13,12),(18,7),(27,14),(22,20)],BLUE[0])
    c.poly([(14,12),(18,8),(25,14),(21,18)],BLUE[1]); c.line(15,11,18,8,BLUE[2])
    c.poly([(7,19),(15,25),(12,26),(6,22)],PINK[2]); c.rect(3,24,4,24,PINK[1])
    c.rect(19,27,20,27,PINK[1]); c.rect(23,25,24,25,PINK[0])
    for x,y in ((5,9),(25,5)):
        c.oval(x-2,y-1,1.5,1,STEEL[2]); c.oval(x+2,y-2,1.5,1,BLUE[2])
        c.oval(x,y+1,1,2,BLUE[0]); c.rect(x,y,x,y+1,BLUE[1]); c.rect(x,y-1,x,y-1,INK)
    return c.finish()


def deadline_art():
    c = Canvas()
    c.line(15,21,15,27,STEEL[0],2); c.line(15,26,9,28,STEEL[0],2)
    c.line(15,26,22,28,STEEL[0],2); c.line(15,22,15,26,STEEL[2])
    c.rect(5,5,26,20,STEEL[0]); c.rect(6,6,25,19,PAPER[0])
    c.rect(7,6,24,17,PAPER[1]); c.rect(7,6,24,7,PAPER[2])
    c.rect(3,4,28,6,STEEL[0]); c.rect(4,4,27,4,STEEL[2]); c.rect(5,5,26,5,STEEL[1])
    c.line(5,21,25,21,STEEL[1]); c.line(6,20,24,20,STEEL[2])
    for x,y in ((10,11),(16,14),(22,10)):
        c.oval(x,y,2,2,BLUE[0]); c.rect(x-1,y-1,x,y,BLUE[1]); c.rect(x-1,y-1,x-1,y-1,BLUE[2])
    c.oval(24,23,5,5,GOLD[0]); c.oval(23,22,4,4,GOLD[1]); c.oval(23,22,3,3,PAPER[2])
    c.line(23,22,23,20,STEEL[0]); c.line(23,22,25,23,STEEL[0]); c.rect(22,17,24,18,GOLD[2])
    return c.finish()


def citation_art():
    c = Canvas()
    c.poly([(20,4),(26,5),(29,11),(26,15),(19,12)],PAPER[0])
    c.poly([(20,5),(25,6),(27,11),(25,13),(20,11)],PAPER[1]); c.line(20,5,24,6,PAPER[2])
    c.rect(21,8,22,9,INK)
    c.poly([(24,20),(29,22),(27,29),(20,27),(19,23)],PAPER[0])
    c.poly([(24,21),(28,23),(26,27),(21,26),(20,23)],PAPER[1]); c.line(24,21,27,22,PAPER[2])
    c.rect(23,23,24,24,INK)
    c.line(13,10,17,7,ORANGE[0],2); c.line(17,7,21,9,ORANGE[1],2)
    c.line(12,24,16,28,ORANGE[0],2); c.line(16,28,23,24,ORANGE[1],2)
    c.oval(9,24,6,3,WOOD[0]); c.rect(4,10,14,24,WOOD[0])
    c.rect(5,10,13,23,ORANGE[0]); c.rect(5,11,10,22,ORANGE[1])
    for y in (12,15,18,21): c.line(5,y,12,y-1,ORANGE[2])
    c.oval(9,9,6,3,WOOD[1]); c.oval(8,8,5,2,WOOD[2]); c.oval(9,8,2,1,WOOD[0])
    c.line(5,25,11,26,WOOD[1]); c.line(5,24,9,25,WOOD[2])
    c.line(16,8,20,9,ORANGE[2]); c.line(17,27,20,26,ORANGE[2])
    return c.finish()


def overtime_art():
    c = Canvas()
    c.poly([(4,9),(18,6),(23,23),(9,27)],PURPLE[0])
    c.poly([(5,10),(17,7),(21,22),(10,25)],PAPER[1])
    c.poly([(8,12),(15,10),(18,20),(11,22)],BLUE[0])
    c.poly([(9,11),(23,10),(25,27),(11,28)],PURPLE[0])
    c.poly([(10,12),(22,11),(23,26),(12,26)],PAPER[1])
    c.poly([(12,14),(20,13),(21,23),(13,24)],BLUE[0])
    c.poly([(15,11),(28,15),(23,29),(10,25)],PAPER[0])
    c.poly([(16,12),(27,16),(22,27),(12,24)],PAPER[2])
    c.poly([(17,15),(24,17),(21,24),(14,22)],BLUE[0])
    c.poly([(17,16),(23,18),(21,22),(15,21)],BLUE[1]); c.line(17,16,21,17,BLUE[2])
    c.oval(24,6,5,4,GOLD[0]); c.oval(23,5,4,3,GOLD[1]); c.line(21,3,23,3,GOLD[2])
    c.oval(26,4,3,3,'.')
    return c.finish()


def meeting_art():
    c = Canvas()
    c.poly([(7,13),(23,12),(22,25),(10,27)],WOOD[0])
    c.poly([(8,14),(20,13),(19,24),(10,25)],WOOD[1]); c.line(9,15,10,24,WOOD[2])
    c.poly([(5,10),(21,7),(27,12),(10,16)],WOOD[0])
    c.poly([(5,10),(20,8),(25,11),(10,14)],WOOD[2]); c.line(10,15,26,12,WOOD[1])
    c.poly([(10,10),(19,9),(22,11),(13,13)],PAPER[1]); c.line(11,10,18,9,PAPER[2])
    c.rect(9,26,23,28,WOOD[0]); c.rect(9,26,20,26,WOOD[2])
    c.line(21,9,21,4,STEEL[0],2); c.line(21,4,17,3,STEEL[0],2)
    c.line(21,8,21,4,STEEL[2]); c.oval(16,3,2,1,STEEL[1]); c.rect(15,2,16,2,STEEL[2])
    for x,y in ((4,20),(26,19)):
        c.poly([(x-1,y-2),(x+2,y),(x,y+3),(x-2,y+1)],BLUE[0])
        c.poly([(x-1,y-1),(x+1,y),(x,y+1)],BLUE[2])
    c.poly([(15,18),(18,20),(15,23),(13,21)],GOLD[0]); c.line(15,19,16,20,GOLD[2])
    return c.finish()


def queue_art():
    c = Canvas()
    c.oval(11,11,7,7,PAPER[0]); c.oval(10,10,6,6,PAPER[1]); c.oval(9,9,4,4,PAPER[2])
    c.oval(10,10,2,2,WOOD[0]); c.rect(9,9,10,9,WOOD[1])
    c.poly([(14,6),(23,8),(23,15),(26,19),(24,27),(17,28),(14,24),(16,18)],PAPER[0])
    c.poly([(15,7),(22,9),(22,16),(25,20),(23,26),(18,26),(15,23),(17,18)],PAPER[1])
    c.poly([(15,7),(18,8),(18,18),(16,22),(19,25),(18,26),(15,23),(17,18)],PAPER[2])
    for x,y in ((19,11),(21,12),(18,20),(20,21),(22,22)): c.rect(x,y,x,y,WOOD[0])
    c.poly([(4,20),(10,18),(14,21),(13,28),(6,29),(3,26)],BLUE[0])
    c.poly([(4,21),(10,19),(13,21),(7,23)],BLUE[2]); c.poly([(7,24),(12,22),(11,27),(7,28)],BLUE[1])
    c.rect(6,17,9,19,GOLD[0]); c.rect(6,17,8,17,GOLD[2]); c.rect(7,25,9,26,GOLD[1])
    return c.finish()


def sold_art():
    c = Canvas()
    c.poly([(4,10),(18,5),(28,10),(27,24),(15,29),(4,23)],WOOD[0])
    c.poly([(5,10),(18,6),(27,10),(15,15)],WOOD[2])
    c.poly([(7,10),(18,7),(24,10),(15,13)],INK)
    c.poly([(5,12),(14,16),(14,27),(5,22)],WOOD[1]); c.line(6,13,6,21,WOOD[2])
    c.poly([(16,16),(27,12),(26,23),(16,27)],WOOD[0]); c.line(17,17,25,14,WOOD[1])
    c.line(5,17,13,20,WOOD[0]); c.line(5,21,13,24,WOOD[0])
    c.poly([(14,15),(20,12),(27,15),(26,22),(21,28),(16,25)],BLUE[0])
    c.poly([(15,16),(20,13),(25,16),(24,21),(20,26),(17,23)],BLUE[1])
    c.poly([(15,16),(19,14),(19,24),(17,22)],BLUE[2])
    c.line(20,14,20,24,STEEL[0]); c.line(17,17,24,18,STEEL[0]); c.rect(20,17,21,18,STEEL[2])
    c.rect(6,12,6,12,STEEL[2]); c.rect(25,12,25,12,STEEL[1])
    return c.finish()


def retry_art():
    c = Canvas()
    for x0,y0,x1,y1 in ((11,3,16,7),(19,6,23,11),(20,15,24,19),(11,19,16,23),(4,14,8,19),(4,6,8,10)):
        c.rect(x0,y0,x1,y1,GOLD[0])
    c.oval(14,13,7,7,GOLD[0]); c.oval(13,12,6,6,GOLD[1]); c.oval(12,11,5,5,GOLD[2])
    c.rect(11,3,15,5,GOLD[2]); c.rect(4,6,7,8,GOLD[2]); c.rect(4,14,6,16,GOLD[1])
    c.rect(11,21,14,22,GOLD[1]); c.rect(21,16,23,17,GOLD[1]); c.rect(20,6,22,7,GOLD[1])
    c.oval(14,13,4,4,STEEL[0]); c.oval(14,13,2,2,STEEL[1]); c.rect(13,12,14,12,STEEL[2])
    c.line(14,13,21,8,WOOD[0],3); c.line(14,12,20,8,WOOD[2])
    c.oval(23,7,3,2,WOOD[0]); c.oval(22,6,2,1,WOOD[1])
    for x,y in ((7,26),(17,27),(27,23)):
        c.poly([(x,y-4),(x+2,y-1),(x+2,y+1),(x,y+2),(x-2,y+1),(x-2,y-1)],BLUE[0])
        c.poly([(x,y-2),(x+1,y),(x,y+1),(x-1,y)],BLUE[1]); c.rect(x-1,y-1,x-1,y-1,BLUE[2])
    return c.finish()


def access_art():
    c = Canvas()
    c.line(11,13,7,6,BLUE[0],3); c.line(7,6,11,3,BLUE[0],3)
    c.line(11,3,20,4,BLUE[0],3); c.line(20,4,23,10,BLUE[0],3)
    c.line(23,10,19,14,BLUE[0],3)
    c.line(8,6,11,4,BLUE[2]); c.line(11,4,19,5,BLUE[1]); c.line(21,7,22,10,BLUE[1])
    c.poly([(10,12),(22,13),(26,25),(23,29),(10,27),(7,15)],GOLD[0])
    c.poly([(10,13),(21,14),(24,25),(22,27),(11,25),(8,15)],GOLD[1])
    c.poly([(11,15),(20,16),(22,24),(12,23),(10,17)],PAPER[2])
    c.line(9,15,11,24,GOLD[2]); c.line(12,26,21,28,GOLD[0])
    c.oval(15,13,2,2,STEEL[0]); c.oval(15,13,1,1,STEEL[2])
    c.oval(17,20,3,3,ORANGE[0]); c.oval(16,19,2,2,ORANGE[1]); c.rect(15,18,16,18,ORANGE[2])
    c.rect(21,15,22,16,'.'); c.rect(24,23,25,24,'.')
    return c.finish()


def right_art():
    c = Canvas()
    # Pink speech bubble with a tail, holding a small heart.
    c.oval(16,13,12,9,PINK[0]); c.oval(15,12,11,8,PINK[1])
    c.poly([(8,19),(12,21),(6,28)],PINK[0]); c.poly([(9,19),(11,20),(7,26)],PINK[1])
    c.line(7,9,12,5,PINK[2]); c.line(6,11,6,13,PINK[2])
    c.oval(13,11,3,3,ORANGE[1]); c.oval(19,11,3,3,ORANGE[1])
    c.poly([(10,12),(22,12),(16,19)],ORANGE[1])
    c.poly([(10,12),(16,12),(16,19)],ORANGE[0])
    c.rect(12,9,13,9,ORANGE[2])
    return c.finish()


def context_art():
    c = Canvas()
    # A tall fan-folded printout: fresh pages at the top, browned pages below.
    folds = ((4,PAPER),(9,PAPER),(14,PAPER),(19,WOOD),(24,WOOD))
    for i,(y,ramp) in enumerate(folds):
        dx = 2 if i % 2 else 0
        c.poly([(5+dx,y),(25+dx,y),(27+dx,y+4),(7+dx,y+4)],ramp[0])
        c.poly([(6+dx,y+1),(24+dx,y+1),(25+dx,y+3),(7+dx,y+3)],ramp[1])
        c.line(6+dx,y+1,23+dx,y+1,ramp[2])
        for x in (10,14,18): c.line(x+dx,y+2,x+2+dx,y+2,ramp[0])
        if i < 4:
            # Each fold joins the next page on alternating sides.
            fx = 26 if i % 2 == 0 else 7
            c.rect(fx,y+4,fx+1,y+5,ramp[0])
    c.rect(29,26,29,26,'.'); c.rect(28,27,28,28,'.'); c.rect(9,28,10,28,'.')
    return c.finish()


def skip_art():
    c = Canvas()
    # An open steel padlock with a cracked body and an orange warning band.
    c.line(9,13,9,7,STEEL[0],3); c.line(9,6,13,3,STEEL[0],3); c.line(13,3,18,3,STEEL[0],3)
    c.line(19,4,22,7,STEEL[0],3)
    c.line(8,7,11,4,STEEL[2]); c.line(12,3,17,3,STEEL[1])
    c.poly([(5,13),(22,13),(24,15),(24,28),(5,28),(4,26),(4,15)],GOLD[0])
    c.poly([(5,14),(22,14),(23,16),(23,26),(5,26)],GOLD[1])
    c.line(6,15,6,25,GOLD[2]); c.line(6,15,21,15,GOLD[2])
    for x in (8,13,18):
        c.poly([(x,18),(x+3,18),(x+1,22),(x-2,22)],ORANGE[1])
    c.rect(5,18,23,18,ORANGE[0]); c.rect(5,22,23,22,ORANGE[0])
    c.line(16,23,19,26,INK); c.line(19,26,18,28,INK)
    return c.finish()


def vibe_art():
    c = Canvas()
    # Purple headphones over three differently coloured drops.
    c.line(6,12,6,8,PURPLE[0],3); c.line(6,8,10,3,PURPLE[0],3)
    c.line(10,3,21,3,PURPLE[0],3); c.line(21,3,25,8,PURPLE[0],3); c.line(25,8,25,12,PURPLE[0],3)
    c.line(7,8,10,4,PURPLE[2]); c.line(11,3,20,3,PURPLE[1])
    for x in (6,25):
        c.rect(x-4,10,x+3,18,PURPLE[0]); c.rect(x-3,11,x+2,17,PURPLE[1])
    c.rect(3,11,4,13,PURPLE[2]); c.rect(22,11,23,13,PURPLE[2])
    c.rect(10,10,21,18,'.')
    for x,y,ramp in ((8,26,BLUE),(16,26,PINK),(24,26,GOLD)):
        c.poly([(x,y-4),(x+2,y-1),(x+2,y+1),(x,y+2),(x-2,y+1),(x-2,y-1)],ramp[0])
        c.poly([(x,y-2),(x+1,y),(x,y+1),(x-1,y)],ramp[1]); c.rect(x-1,y-1,x-1,y-1,ramp[2])
    return c.finish()


def tests_art():
    c = Canvas()
    # A clipboard with three ticked rows.
    c.poly([(6,5),(25,5),(26,6),(26,28),(25,29),(6,29),(5,28),(5,6)],WOOD[0])
    c.rect(6,6,25,28,WOOD[1]); c.line(6,6,6,27,WOOD[2])
    c.rect(8,8,23,27,PAPER[1]); c.line(8,8,23,8,PAPER[2]); c.line(23,9,23,27,PAPER[0])
    c.rect(11,3,20,7,STEEL[0]); c.rect(12,4,19,5,STEEL[2]); c.rect(13,6,18,6,STEEL[1])
    for y in (12,17,22):
        c.line(10,y,11,y+2,GREEN[0],2); c.line(11,y+2,15,y-2,GREEN[0],2)
        c.line(10,y,11,y+1,GREEN[2]); c.line(12,y+1,14,y-1,GREEN[1])
        c.line(17,y+1,21,y+1,PAPER[0])
    return c.finish()


def cleared_art():
    c = Canvas()
    # A wiped slate in a wooden frame, a sponge, and one orange spark.
    c.rect(3,6,26,25,WOOD[0]); c.rect(4,7,25,24,WOOD[1]); c.line(4,7,25,7,WOOD[2]); c.line(4,8,4,23,WOOD[2])
    c.rect(6,9,23,22,STEEL[0])
    c.poly([(7,13),(15,10),(19,12),(9,17)],STEEL[1]); c.poly([(8,19),(17,15),(21,17),(12,21)],STEEL[1])
    c.line(9,14,15,11,STEEL[2])
    c.poly([(17,22),(26,19),(29,24),(20,28)],YELLOW[0]); c.poly([(18,22),(25,20),(27,23),(20,26)],YELLOW[1])
    c.line(18,22,24,20,YELLOW[2]); c.rect(21,24,21,24,YELLOW[0]); c.rect(24,23,24,23,YELLOW[0])
    c.poly([(26,2),(27,5),(30,6),(27,7),(26,10),(25,7),(22,6),(25,5)],ORANGE[1]); c.rect(26,5,26,6,ORANGE[2])
    return c.finish()


def welcome_art():
    c = Canvas()
    # A woven doormat with a stitched heart and a blue ribbon tag.
    c.poly([(3,14),(26,10),(29,23),(6,28)],WOOD[0])
    c.poly([(4,14),(25,11),(27,22),(6,26)],ORANGE[1])
    for i in range(5):
        c.line(6+i*4,15-i,7+i*4,25-i,ORANGE[0])
    c.line(5,14,24,11,ORANGE[2])
    c.oval(13,17,2.5,2.5,PINK[0]); c.oval(18,16,2.5,2.5,PINK[0]); c.poly([(10,18),(21,16),(17,23)],PINK[0])
    c.oval(13,17,1.5,1.5,PINK[1]); c.oval(18,16,1.5,1.5,PINK[1]); c.poly([(12,18),(19,17),(16,21)],PINK[1])
    c.rect(12,16,12,16,PINK[2])
    return c.finish()


def status_art():
    c = Canvas()
    # A monitor showing three healthy lights while smoke rises behind it.
    c.rect(3,9,26,24,STEEL[0]); c.rect(4,10,25,22,STEEL[1]); c.line(4,10,25,10,STEEL[2])
    c.rect(6,12,23,21,BLUE[0])
    for y in (14,17,20):
        c.rect(8,y-1,9,y,GREEN[1]); c.rect(8,y-1,8,y-1,GREEN[2]); c.line(11,y,20,y,BLUE[1])
    c.rect(13,24,16,26,STEEL[0]); c.rect(8,27,21,28,STEEL[0]); c.line(9,27,20,27,STEEL[2])
    c.poly([(23,22),(26,17),(28,22),(26,25)],ORANGE[1]); c.poly([(25,22),(26,20),(27,23)],ORANGE[2])
    return c.finish()


def appeal_art():
    c = Canvas()
    # A folded form tied with a blue ribbon, and a quill.
    c.poly([(5,8),(21,6),(24,26),(8,28)],PAPER[0]); c.poly([(6,9),(20,7),(22,25),(8,26)],PAPER[1])
    c.line(6,9,19,7,PAPER[2])
    for y in (11,14,20,23): c.line(9,y,19,y-1,PAPER[0])
    c.rect(7,16,22,18,BLUE[0]); c.line(7,16,22,16,BLUE[2]); c.rect(7,17,22,17,BLUE[1])
    c.poly([(13,17),(10,22),(12,22),(14,19)],BLUE[0]); c.poly([(15,17),(18,22),(16,22),(14,19)],BLUE[1])
    c.poly([(27,2),(29,4),(21,15),(19,13)],PAPER[0]); c.poly([(27,3),(28,4),(21,13),(20,13)],PAPER[2])
    c.line(20,14,17,19,WOOD[0])
    return c.finish()


def support_art():
    c = Canvas()
    # A support headset with a boom microphone and a brass coin.
    c.line(6,16,6,10,STEEL[0],3); c.line(6,10,10,5,STEEL[0],3); c.line(10,5,19,5,STEEL[0],3)
    c.line(19,5,23,10,STEEL[0],3); c.line(23,10,23,16,STEEL[0],3)
    c.line(7,10,10,6,STEEL[2]); c.line(11,5,18,5,STEEL[1])
    c.oval(6,18,3,4,BLUE[0]); c.oval(6,17,2,3,BLUE[1]); c.oval(23,18,3,4,BLUE[0]); c.oval(23,17,2,3,BLUE[1])
    c.line(5,21,9,25,STEEL[0],2); c.line(9,25,14,25,STEEL[0],2); c.oval(16,25,2,1.5,STEEL[1])
    c.oval(23,26,4,4,GOLD[0]); c.oval(22,25,3,3,GOLD[1]); c.rect(21,23,22,23,GOLD[2]); c.line(23,25,23,27,GOLD[0])
    return c.finish()


def tungsten_art():
    c = Canvas()
    # A dense isometric metal cube with a heavy shadow face.
    c.poly([(16,4),(28,10),(16,16),(4,10)],STEEL[2])
    c.poly([(4,10),(16,16),(16,29),(4,23)],STEEL[1])
    c.poly([(16,16),(28,10),(28,23),(16,29)],STEEL[0])
    c.line(16,5,26,10,STEEL[1]); c.line(6,11,15,15,STEEL[2])
    c.line(5,11,5,22,STEEL[2])
    return c.finish()


def pizza_art():
    c = Canvas()
    # A pizza slice with white glue strands dripping from its tip.
    c.poly([(4,6),(27,4),(14,26)],GOLD[0])
    c.poly([(5,8),(26,6),(14,24)],YELLOW[1])
    c.poly([(4,5),(27,3),(27,6),(4,8)],GOLD[1]); c.line(5,5,26,3,GOLD[2])
    for x,y in ((11,11),(19,10),(15,17)):
        c.oval(x,y,2,2,RED[1]); c.rect(x-1,y-1,x-1,y-1,RED[2])
    c.line(8,9,13,15,YELLOW[2])
    c.line(14,24,14,28,PAPER[2],2); c.line(18,17,20,23,PAPER[2]); c.oval(20,24,1,1.5,PAPER[2])
    c.oval(14,28,1.5,1.5,PAPER[1])
    return c.finish()


def strawberry_art():
    c = Canvas()
    # A plain strawberry with seeds and a green crown; no lettering.
    c.poly([(5,11),(16,8),(27,11),(26,19),(20,27),(16,29),(12,27),(6,19)],RED[0])
    c.poly([(6,12),(16,9),(26,12),(25,18),(19,26),(16,27),(13,26),(7,18)],RED[1])
    c.poly([(7,12),(12,10),(10,17),(8,16)],RED[2])
    for x,y in ((11,14),(16,13),(21,14),(13,19),(19,19),(16,23),(23,17),(9,17)):
        c.rect(x,y,x,y,YELLOW[1])
    c.poly([(9,9),(13,4),(16,7),(19,4),(23,9),(16,11)],GREEN[0])
    c.poly([(11,8),(13,5),(16,8),(19,5),(21,8),(16,10)],GREEN[1])
    c.line(16,3,16,7,GREEN[0]); c.rect(13,6,14,6,GREEN[2])
    return c.finish()


def gate_art():
    c = Canvas()
    # A generic orange suspension-bridge tower over blue water.
    c.rect(2,22,29,28,BLUE[0]); c.rect(3,23,28,27,BLUE[1])
    for x in (5,12,20,26): c.line(x,25,x+2,25,BLUE[2])
    c.rect(9,4,11,23,ORANGE[0]); c.rect(20,4,22,23,ORANGE[0])
    c.rect(9,4,9,22,ORANGE[2]); c.rect(20,4,20,22,ORANGE[2])
    c.rect(10,5,10,22,ORANGE[1]); c.rect(21,5,21,22,ORANGE[1])
    c.rect(9,8,22,9,ORANGE[1]); c.rect(9,14,22,15,ORANGE[1])
    c.line(2,18,9,5,ORANGE[0]); c.line(22,5,29,18,ORANGE[0])
    c.rect(2,19,29,20,ORANGE[0]); c.line(2,19,29,19,ORANGE[2])
    for x,y in ((4,15),(6,12),(25,12),(27,15)): c.line(x,y,x,18,ORANGE[1])
    return c.finish()


def seahorse_art():
    c = Canvas()
    # A golden seahorse with a curled tail inside a faint blue wisp.
    c.oval(16,16,12,13,BLUE[0]); c.oval(16,16,11,12,BLUE[1])
    c.rect(5,5,6,6,'.'); c.rect(26,26,27,27,'.')
    c.poly([(13,6),(18,5),(21,8),(26,9),(26,11),(20,12),(19,16),(20,21),(17,26),(13,27),(11,24),(14,23),(15,21),(13,17),(12,12)],GOLD[0])
    c.poly([(14,7),(18,6),(20,9),(25,10),(19,11),(18,16),(19,21),(16,25),(13,25),(15,22),(14,17),(13,12)],GOLD[1])
    c.line(15,8,14,14,GOLD[2]); c.rect(17,8,17,8,INK)
    for y in (12,15,18): c.rect(12,y,12,y,GOLD[0])
    c.oval(10,23,2,2,BLUE[1]); c.rect(9,22,10,23,GOLD[0]); c.rect(10,22,10,22,BLUE[2])
    c.rect(8,6,9,7,BLUE[2]); c.rect(24,20,24,21,BLUE[2])
    return c.finish()


def dial_art():
    c = Canvas()
    # A round knob whose scale runs from cool blue to hot orange.
    c.oval(16,17,12,12,STEEL[0])
    for i,(x,y) in enumerate(((6,22),(5,17),(7,11),(11,7),(16,5),(21,7),(25,11),(27,17),(26,22))):
        ramp = BLUE if i < 4 else (GOLD if i == 4 else ORANGE)
        c.rect(x,y,x+1,y+1,ramp[1])
    c.oval(16,17,8,8,STEEL[1]); c.oval(15,16,6,6,STEEL[2]); c.oval(16,17,4,4,STEEL[1])
    c.line(16,17,21,11,INK,2); c.line(16,17,20,12,ORANGE[1])
    c.rect(13,28,19,29,STEEL[0])
    return c.finish()


def research_art():
    c = Canvas()
    # A tall leaning stack of books topped by a rolled map.
    books = ((4,24,26,28,BLUE),(6,19,25,23,RED),(5,14,24,18,GREEN),(7,9,25,13,PURPLE))
    for x0,y0,x1,y1,ramp in books:
        c.rect(x0,y0,x1,y1,ramp[0]); c.rect(x0+1,y0+1,x1-1,y1-1,ramp[1]); c.line(x0+1,y0+1,x1-2,y0+1,ramp[2])
        c.rect(x1-3,y0+1,x1-1,y1-1,PAPER[1]); c.line(x1-3,y0+2,x1-1,y0+2,PAPER[0])
    c.rect(8,4,26,7,PAPER[0]); c.rect(9,4,25,6,PAPER[1]); c.line(9,4,24,4,PAPER[2])
    c.oval(8,6,2,2,PAPER[0]); c.oval(26,6,2,2,PAPER[0]); c.rect(15,4,16,7,RED[1])
    return c.finish()


def rejection_art():
    c = Canvas()
    # An opened envelope with a letter crossed out in red.
    c.poly([(3,12),(29,12),(29,28),(3,28)],PAPER[0])
    c.poly([(7,3),(25,3),(25,20),(7,20)],PAPER[1]); c.line(7,3,24,3,PAPER[2])
    for y in (7,10,13): c.line(10,y,22,y,PAPER[0])
    c.line(10,6,22,17,RED[1],2); c.line(22,6,10,17,RED[1],2); c.rect(11,6,11,6,RED[2])
    c.poly([(3,13),(16,21),(29,13),(29,28),(3,28)],PAPER[1])
    c.line(4,14,15,21,PAPER[2])
    return c.finish()


def stamp_art():
    c = Canvas()
    # A rubber stamp with a wooden knob and a red mark beneath it.
    c.oval(16,6,5,4,WOOD[0]); c.oval(15,5,4,3,WOOD[1]); c.rect(13,4,14,4,WOOD[2])
    c.rect(14,9,18,13,WOOD[0]); c.rect(15,9,16,12,WOOD[1])
    c.rect(7,13,25,17,STEEL[0]); c.rect(8,13,24,15,STEEL[1]); c.line(8,13,24,13,STEEL[2])
    c.rect(8,18,24,20,RED[0]); c.rect(9,18,23,19,RED[1])
    c.poly([(5,23),(27,23),(26,29),(6,29)],RED[1]); c.poly([(8,25),(24,25),(23,27),(9,27)],PAPER[2])
    c.rect(12,25,20,27,RED[0])
    return c.finish()


def cartridge_art():
    c = Canvas()
    # A game cartridge with a blank label and speed lines.
    c.poly([(9,4),(27,4),(27,26),(25,28),(9,28)],STEEL[0])
    c.rect(10,5,26,26,STEEL[1]); c.line(10,5,26,5,STEEL[2]); c.line(10,6,10,26,STEEL[2])
    c.rect(12,8,24,18,BLUE[0]); c.rect(13,9,23,17,BLUE[1]); c.line(13,9,22,9,BLUE[2])
    c.rect(15,12,21,14,PAPER[1])
    for x in (13,16,19,22): c.rect(x,22,x+1,26,GOLD[1])
    c.line(2,10,6,10,BLUE[1]); c.line(3,14,7,14,BLUE[2]); c.line(2,18,6,18,BLUE[1])
    return c.finish()


def pin_art():
    c = Canvas()
    # A red map pin pushed into the floor with a dashed return arc.
    c.oval(16,27,8,2,STEEL[0])
    c.poly([(16,26),(10,15),(22,15)],RED[0])
    c.oval(16,11,7,7,RED[0]); c.oval(16,11,6,6,RED[1]); c.oval(14,9,2,2,RED[2])
    c.poly([(16,24),(12,16),(20,16)],RED[1])
    c.oval(16,11,2,2,PAPER[2])
    for x,y in ((4,20),(3,16),(4,12),(6,8)): c.rect(x,y,x+1,y+1,BLUE[1])
    c.poly([(7,4),(10,6),(7,8)],BLUE[1])
    return c.finish()


def valve_art():
    c = Canvas()
    # A steel pipe joint closed by a round red handwheel.
    c.rect(2,21,29,27,STEEL[0]); c.rect(2,22,29,25,STEEL[1]); c.line(2,22,29,22,STEEL[2])
    c.rect(12,18,20,28,STEEL[0]); c.rect(13,19,19,27,STEEL[1]); c.line(13,19,19,19,STEEL[2])
    c.rect(15,14,17,18,STEEL[0]); c.rect(16,14,16,17,STEEL[2])
    c.oval(16,9,8,7,RED[0]); c.oval(16,9,7,6,RED[1]); c.oval(16,9,5,4,RED[0])
    c.line(10,5,14,3,RED[2])
    c.line(11,9,21,9,RED[1],2); c.line(16,4,16,14,RED[1],2)
    c.rect(15,8,17,10,STEEL[1]); c.rect(15,8,15,8,STEEL[2])
    return c.finish()


def consensus_art():
    c = Canvas()
    # A gold coin embossed with three overlapping rings that agree in the middle.
    c.oval(16,16,13,13,GOLD[0]); c.oval(16,15,12,12,GOLD[1]); c.oval(15,14,10,10,GOLD[2]); c.oval(16,15,10,10,GOLD[1])
    for cx,cy in ((13.5,13),(18.5,13),(16,17.5)):
        for k in range(48):
            a = k * math.pi / 24
            x, y = round(cx + 4.5*math.cos(a)), round(cy + 4.5*math.sin(a))
            c.rect(x,y,x,y,GOLD[0])
    c.rect(15,14,17,15,GOLD[2])
    c.line(8,7,12,4,GOLD[2])
    return c.finish()


def budget_art():
    c = Canvas()
    # A pink piggy bank with a coin dropping in and a small crack.
    c.oval(16,18,12,9,PINK[0]); c.oval(15,17,11,8,PINK[1]); c.oval(12,14,5,3,PINK[2])
    c.oval(27,18,3,3,PINK[0]); c.oval(27,18,2,2,PINK[1]); c.rect(26,17,26,18,PINK[0]); c.rect(28,17,28,18,PINK[0])
    c.poly([(19,9),(23,7),(23,12)],PINK[0])
    c.rect(9,25,11,29,PINK[0]); c.rect(19,25,21,29,PINK[0])
    c.rect(22,15,22,15,INK)
    c.rect(13,9,18,9,PINK[0])
    c.oval(15,5,3,3,GOLD[0]); c.oval(15,5,2,2,GOLD[1]); c.rect(14,4,14,4,GOLD[2])
    c.line(7,19,9,21,PINK[0]); c.line(9,21,8,23,PINK[0])
    return c.finish()


def dash_art():
    c = Canvas()
    # A long steel needle piercing straight through two blue tears.
    for cx in (11,21):
        c.oval(cx,17,5,6,BLUE[0]); c.oval(cx,17,4,5,BLUE[1]); c.poly([(cx-4,15),(cx,7),(cx+4,15)],BLUE[1])
        c.poly([(cx-5,15),(cx,6),(cx+5,15)],BLUE[0]); c.oval(cx,17,4,5,BLUE[1]); c.poly([(cx-3,15),(cx,8),(cx+3,15)],BLUE[1])
        c.rect(cx-2,14,cx-1,16,BLUE[2])
    c.rect(3,18,27,19,STEEL[1]); c.line(3,18,27,18,STEEL[2])
    c.poly([(27,17),(30,18),(27,20)],STEEL[1]); c.rect(2,17,4,20,STEEL[0])
    return c.finish()


def blueberry_art():
    c = Canvas()
    # Three dusty blueberries in a cluster, each with a dark star-shaped crown.
    for cx,cy in ((10,12),(22,13),(16,22)):
        c.oval(cx,cy,7,7,BLUE[0]); c.oval(cx-1,cy-1,6,6,BLUE[1]); c.oval(cx-3,cy-3,2,2,BLUE[2])
        c.rect(cx,cy-2,cx,cy+2,PURPLE[0]); c.rect(cx-2,cy,cx+2,cy,PURPLE[0]); c.rect(cx-1,cy-1,cx+1,cy+1,PURPLE[0])
        c.rect(cx,cy,cx,cy,PURPLE[1])
    c.line(15,3,18,6,GREEN[0]); c.poly([(18,5),(24,2),(22,7)],GREEN[1])
    return c.finish()


def discount_art():
    c = Canvas()
    # A paper price tag on a string, slashed in red, beside a brass coin.
    c.poly([(5,10),(12,4),(27,4),(27,18),(12,18)],PAPER[0])
    c.poly([(6,10),(12,5),(26,5),(26,17),(12,17)],PAPER[1]); c.line(12,5,25,5,PAPER[2])
    c.oval(11,11,1,1,'.'); c.rect(10,10,12,10,PAPER[0])
    c.line(2,4,10,10,WOOD[1])
    c.rect(15,9,23,9,PAPER[0]); c.rect(15,13,21,13,PAPER[0])
    c.line(14,15,24,7,RED[1],2)
    c.oval(21,24,6,6,GOLD[0]); c.oval(21,24,5,5,GOLD[1]); c.oval(20,23,2,2,GOLD[2]); c.rect(21,22,21,26,GOLD[0])
    return c.finish()


def rock_art():
    c = Canvas()
    # One small angular grey rock served on a blue-rimmed plate with a spoon.
    c.oval(15,22,13,6,BLUE[0]); c.oval(15,21,12,5,PAPER[2]); c.oval(15,21,8,3,PAPER[1])
    c.poly([(10,20),(11,15),(15,12),(20,14),(21,20),(16,22)],STEEL[0])
    c.poly([(11,19),(12,15),(15,13),(19,15),(19,19)],STEEL[1]); c.poly([(12,15),(15,13),(16,16),(13,17)],STEEL[2])
    c.line(26,7,28,22,STEEL[1]); c.oval(25,5,2,3,STEEL[1]); c.rect(24,4,24,5,STEEL[2])
    return c.finish()


def moon_art():
    c = Canvas()
    # A dark mountain with a cave mouth under a pale crescent moon.
    c.poly([(2,28),(11,9),(15,14),(20,6),(30,28)],PURPLE[0])
    c.poly([(3,27),(11,11),(15,16),(20,8),(29,27)],PURPLE[1])
    c.poly([(20,8),(23,13),(21,12),(19,14),(17,12)],PAPER[2]); c.poly([(11,11),(13,14),(11,13),(9,14)],PAPER[2])
    c.oval(16,25,4,4,INK); c.rect(12,25,20,28,INK)
    c.oval(6,6,4,4,YELLOW[1]); c.oval(8,5,3,3,'.'); c.rect(3,5,3,6,YELLOW[2])
    c.rect(27,4,27,4,YELLOW[2]); c.rect(24,2,24,2,YELLOW[2])
    return c.finish()


def model_art():
    c = Canvas()
    # A blue umbrella deflecting purple curse drops.
    for x,y in ((5,4),(13,4),(22,4),(28,7),(3,10)):
        c.oval(x,y,1.5,2,PURPLE[1]); c.rect(x,y-1,x,y-1,PURPLE[2])
    c.poly([(3,17),(7,10),(16,7),(25,10),(29,17)],BLUE[0])
    c.poly([(5,16),(8,11),(16,8),(24,11),(27,16)],BLUE[1])
    c.poly([(9,15),(12,10),(16,8),(14,15)],BLUE[2])
    for x in (3,10,16,22,29): c.rect(x,16,x,17,BLUE[0])
    c.rect(16,6,16,7,STEEL[0])
    c.line(16,17,16,26,STEEL[0],2); c.line(16,26,13,28,STEEL[0],2); c.rect(12,26,12,27,STEEL[0])
    c.oval(7,22,1.5,2,PURPLE[1]); c.oval(26,23,1.5,2,PURPLE[1])
    return c.finish()


def leak_art():
    c = Canvas()
    # A cracked glass jar holding a rolled note, leaking a blue drip.
    c.rect(10,4,22,7,WOOD[0]); c.rect(11,5,21,6,WOOD[1])
    c.poly([(8,8),(24,8),(25,25),(22,28),(10,28),(7,25)],BLUE[0])
    c.poly([(9,9),(23,9),(24,24),(21,27),(11,27),(8,24)],BLUE[1])
    c.rect(10,10,11,22,BLUE[2])
    c.rect(13,12,19,24,PAPER[1]); c.rect(13,12,19,13,PAPER[2]); c.rect(13,23,19,24,PAPER[0])
    c.line(20,13,22,16,INK); c.line(22,16,20,18,INK); c.line(20,18,23,21,INK)
    c.oval(26,23,1.5,2,BLUE[1]); c.rect(26,21,26,21,BLUE[1]); c.oval(28,29,2,1,BLUE[1])
    return c.finish()


def disgrace_art():
    c = Canvas()
    # A pale ice cube ringed by a purple looping arrow.
    c.oval(16,16,13,13,PURPLE[0]); c.oval(16,16,11,11,PURPLE[1]); c.oval(16,16,9,9,'.')
    c.poly([(20,1),(31,1),(31,12),(24,12)],'.')
    c.poly([(19,2),(28,6),(19,10)],PURPLE[0]); c.poly([(20,4),(26,6),(20,8)],PURPLE[1])
    c.rect(10,10,22,22,BLUE[0]); c.rect(11,11,21,21,BLUE[1]); c.rect(11,11,21,12,BLUE[2]); c.rect(11,13,12,20,BLUE[2])
    c.line(15,15,19,19,BLUE[2]); c.rect(18,14,19,15,BLUE[2])
    return c.finish()


CLAUDE_ART = 'Original project artwork, Claude-assisted'


def design(draw, palette, meaning, batch='01', author='Original project artwork, Codex-assisted'):
    return Design(draw, 1, (INK, *palette), meaning,
                  author,
                  'Original pixel geometry and material shading authored in make_item_art.py; no external pixels.',
                  f'docs/art/item-batch-{batch}-4x.png')


DESIGNS = {
    'collectibles/ban_hammer.png': design(hammer_art, (*WOOD,*STEEL,*ORANGE), 'A heavy diagonal orange gavel with worn steel ends and a wrapped wooden handle; room bans.'),
    'collectibles/compact.png': design(compact_art, (*STEEL,*PAPER,*BLUE), 'An iron press compressing a bound paper stack; compacting context and bullets.'),
    'collectibles/summary_stapler.png': design(stapler_art, (*STEEL,*ORANGE,*BLUE), 'An open orange stapler over three blue projectile capsules; combining bullets into one shot.'),
    'collectibles/ultrathink.png': design(ultrathink_art, (*PINK,*GOLD,*STEEL), 'A folded pink brain on a brass bulb base with small sparks; escalating thought.'),
    'collectibles/subagent_swarm.png': design(swarm_art, (*ORANGE,*BLUE), 'One large orange tear connected to two smaller tears by blue branching trails; resolved child shots.'),
    'collectibles/constitution.png': design(constitution_art, (*WOOD,*PAPER,*GOLD,*PINK), 'A bound cream rulebook with an embossed shield and hanging wax seal; protective rules.'),
    'collectibles/lunch_break.png': design(lunch_art, (*BLUE,*PAPER,*WOOD,*PINK), 'A turquoise rice bowl, individual rice highlights, chopsticks and a small napkin; a healing food break.'),
    'collectibles/rice_cooker.png': design(cooker_art, (*PAPER,*STEEL,*BLUE,*ORANGE), 'A steaming cream cooker with a steel lid and blue window; cook first, attack afterward.'),
    'collectibles/token_recall.png': design(recall_art, (*GOLD,*PURPLE,*BLUE), 'A brass reel pulling a blue tear along a curved tether; recalling fired tokens.'),
    'collectibles/lets_delve.png': design(delve_art, (*WOOD,*STEEL), 'A diagonal spade with an open wooden handle, bevelled steel and a small soil clod; native digging.'),
    'collectibles/ignore_instructions.png': design(injection_art, (*PAPER,*STEEL,*BLUE,*PINK), 'A glass syringe with pink fluid crossing a folded instruction sheet; injected orders and charm.', '02'),
    'collectibles/residential_ip.png': design(residential_art, (*PAPER,*WOOD,*BLUE,*GOLD), 'A cream cottage with a blue roof and a protected cable around its base; a safer residential connection.', '02'),
    'collectibles/cheap_relay.png': design(relay_art, (*GOLD,*ORANGE,*STEEL,*PAPER), 'A worn brass key with a cracked orange bow patched with tape; unreliable discount access.', '02'),
    'collectibles/silent_update.png': design(silent_art, (*PAPER,*STEEL,*PURPLE), 'A sealed cream envelope concealing a steel gear behind its corner; an unannounced change.', '02'),
    'collectibles/opus_mode.png': design(opus_art, (*GOLD,*PURPLE,*BLUE), 'An ornate brass coin meter with a purple inset and blue tear dial; powerful shots billed in coins.', '02'),
    'collectibles/banked_reset.png': design(reset_art, (*GOLD,*BLUE,*PAPER), 'A blue-glass hourglass held inside brass vault rails, retaining pale sand; a stored reset.', '02'),
    'collectibles/benchmaxxed.png': design(bench_art, (*STEEL,*ORANGE,*GOLD), 'A red padded weight bench under a loaded steel bar and small brass crown; strength for boss benchmarks.', '02'),
    'collectibles/i_panicked.png': design(panic_art, (*STEEL,*ORANGE,*GOLD), 'A large emergency plunger on a cracked metal base with severed leads; a destructive panic action.', '02'),
    'trinkets/overloaded.png': design(overloaded_art, (*STEEL,*BLUE), 'A broken glass fuse between steel caps, with cold shards hanging underneath; a frozen service outage.', '02'),
    'trinkets/hardcoded_output.png': design(hardcoded_art, (*STEEL,*BLUE), 'A bevelled steel tear die and two identical blue outputs; fixed output without numerical text.', '02'),
    'collectibles/anniversary_cake.png': design(cake_art, (*STEEL,*PAPER,WOOD[0],*PINK,*BLUE,ORANGE[1]), 'A frosted cake slice with layered filling, a plate and one lit candle; an unspoiled floor streak.', '03'),
    'collectibles/one_bowl.png': design(guarded_bowl_art, (*BLUE,*PAPER,*STEEL), 'A deep rice bowl with a steel shield on its front and no chopsticks; the one-bullet guard.', '03'),
    'collectibles/wengu_clock.png': design(clock_art, (*STEEL,*GOLD,*BLUE,*PAPER), 'A blue alarm clock with brass bells, plain hands and a cream dial without digits; rest before attacking.', '03'),
    'collectibles/seven_second_memory.png': design(memory_art, (*BLUE,*ORANGE,*PAPER,*WOOD), 'An orange fish held in a rounded blue memory jar with a cork and rising bubbles; a brief target memory.', '03'),
    'collectibles/sanity_test.png': design(sanity_art, (*WOOD,*STEEL,*BLUE,*PAPER,ORANGE[0]), 'A heavy magnifying glass framing a target inside blue glass; test the selected enemy.', '03'),
    'collectibles/routing_receipt.png': design(receipt_art, (*PAPER,*STEEL,*BLUE,*GOLD), 'A curled receipt with three brass punch points joined by a blue route; banked room progress.', '03'),
    'collectibles/tibo_reset.png': design(tibo_art, (*STEEL,*BLUE,*GOLD), 'A twin-cell blue power pack with a brass winding key; a temporary two-room boost rather than a world reset.', '03'),
    'collectibles/same_model_badge.png': design(badge_art, (*STEEL,*PAPER,*GOLD), 'A clipped identity badge with one portrait divided into bright brass and dull steel; Verified and Fallback phases.', '03'),
    'collectibles/nano_banana.png': design(banana_art, (*YELLOW,*PAPER,*WOOD,*BLUE), 'A curled yellow banana with splayed peel tips and a small blue paint spot; painting followed by a slowing peel.', '03'),
    'collectibles/undo_brush.png': design(undo_art, (*WOOD,*STEEL,*PAPER,*BLUE), 'A broad diagonal paintbrush sweeping a blue trail past a breaking projectile; erasing bullets for speed.', '03'),
    'collectibles/one_more_finger.png': design(finger_art, (*PAPER,*BLUE), 'A cream glove with five upright fingers and a side thumb, plus a blue cuff; one extra shot.', '04'),
    'collectibles/unchanged_preview.png': design(preview_art, (*STEEL,*PAPER,*BLUE), 'Two overlapping slide frames containing the same faceless bust; temporary paired decoys.', '04'),
    'collectibles/is_this_true.png': design(challenge_art, (*GOLD,*STEEL,*BLUE), 'A brass megaphone with a dark mouth and a blue handle; challenging one selected target.', '04'),
    'collectibles/live_wire.png': design(wire_art, (*BLUE,*GOLD,*ORANGE), 'A loop of blue cable with exposed copper strands and one orange spark; speed under nearby fire.', '04'),
    'collectibles/quote_retort.png': design(retort_art, (*STEEL,*PAPER,*ORANGE), 'An orange boxing glove on a compressed steel spring; a primed retaliation after a hit.', '04'),
    'collectibles/community_note.png': design(note_art, (*PAPER,*ORANGE,*STEEL), 'A pinned evidence note with a folded corner and three punctures, without written text; repeated hits expose a target.', '04'),
    'collectibles/base_model.png': design(base_art, (*STEEL,*WOOD,*BLUE), 'An unfinished wooden training mannequin on a steel stand, with a blue chest socket; a base waiting to be primed.', '04'),
    'collectibles/another_adapter.png': design(adapter_art, (*STEEL,*GOLD,*BLUE), 'An angled blue adapter block with three brass contacts and a socket face; replacing one room bonus with another.', '04'),
    'collectibles/final_weights.png': design(weights_art, (*STEEL,*BLUE,*GOLD), 'Two stacked metal weight plates secured by a brass locking ring; two flawless clears bank strength.', '04'),
    'collectibles/tiny_variant.png': design(tiny_art, (*STEEL,*GOLD,*PINK), 'A small clockwork mouse with a large winding key and pink feet; speed for reduced damage, not player resizing.', '04'),
    'collectibles/open_weights.png': design(open_weights_art, (*STEEL,*GOLD,*BLUE), 'An unlocked iron weight with two blue flies escaping past its open brass shackle; sharing native flies.', '05'),
    'collectibles/herd_bell.png': design(herd_bell_art, (*GOLD,*BLUE,WOOD[0]), 'A brass cowbell with a blue leather loop and visible clapper; replenishing a missing fly after clears.', '05'),
    'collectibles/please_come_back.png': design(come_back_art, (*STEEL,*BLUE,*GOLD), 'A blue battery in a steel charging cradle beside a loose looping plug; earning one active charge after waiting.', '05'),
    'collectibles/release_soon.png': design(release_art, (*BLUE,*WOOD,*GOLD,*STEEL), 'A strapped blue parcel with a brass timer and winding key; a delayed protective release.', '05'),
    'collectibles/emergency_baguette.png': design(baguette_art, (*WOOD,*GOLD,*PAPER,*BLUE), 'A long crusty diagonal baguette with pale scoring and a blue cloth grip; a forward bread strike.', '05'),
    'collectibles/slipstream_boots.png': design(boots_art, (*WOOD,*BLUE,*STEEL), 'Overlapping brown ankle boots with blue cuffs, metal buckle and a short air trail; sustained movement and turning gusts.', '05'),
    'collectibles/large_kitten.png': design(kitten_art, (*ORANGE,*PAPER,*BLUE), 'A large seated orange kitten with broad paws, curled tail and a small blue projectile beside it; a stationary bullet-pushing companion.', '05'),
    'collectibles/edge_compass.png': design(compass_art, (*STEEL,*GOLD,*BLUE,*ORANGE), 'A brass compass with a coloured needle beside a stone corner; shot speed near outer walls.', '05'),
    'collectibles/instant_apology.png': design(apology_art, (*WOOD,*GOLD,*PAPER,*BLUE), 'A folded white truce flag on a wooden pole above a dispersing blue bullet; local slowing and bullet removal, without healing.', '05'),
    'collectibles/next_time_again.png': design(again_art, (*WOOD,*PAPER,*PINK), 'A chipped wooden boomerang repaired with pale tape and a small bruise-coloured patch; retaliation after a hit, not a returning-projectile effect.', '05'),
    'collectibles/confident_answer.png': design(confident_art, (*GOLD,*WOOD,*STEEL,*PINK), 'A loud brass megaphone with a cracked seam and flattened squeeze bulb; confidence followed by a weaker phase, not a new projectile weapon.', '06'),
    'collectibles/smiling_correction.png': design(correction_art, (*PINK,*BLUE,*STEEL), 'A pink beveled eraser in a blue sleeve over rubbed ink, with two small blue flies; a correction earned by a flawless clear after a hit.', '06'),
    'collectibles/slide_deadline.png': design(deadline_art, (*STEEL,*PAPER,*BLUE,*GOLD), 'A pull-down projection screen on a tripod with three blue target dots and a small brass timer; a timed batch of marked enemies.', '06'),
    'collectibles/citation_thread.png': design(citation_art, (*WOOD,*ORANGE,*PAPER), 'A wooden spool of orange thread linking two punched paper reference tags; alternating hit references.', '06'),
    'collectibles/overtime_slides.png': design(overtime_art, (*PURPLE,*PAPER,*BLUE,*GOLD), 'Three fanned projection transparencies under a brass crescent; a delayed slowing outline after accumulated clears.', '06'),
    'collectibles/standup_meeting.png': design(meeting_art, (*WOOD,*PAPER,*STEEL,*BLUE,*GOLD), 'A wooden lectern with a bent microphone and small blue burst markers; recalling temporary helpers without touching native familiars.', '06'),
    'collectibles/queue_ticket.png': design(queue_art, (*PAPER,*WOOD,*BLUE,*GOLD), 'A curled perforated ticket roll above a small blue battery; earning an eligible active charge after unique clears, with no printed digits.', '06'),
    'collectibles/sold_out.png': design(sold_art, (*WOOD,*BLUE,*STEEL), 'An open empty wooden stock crate with a riveted blue shield across its front; a temporary ordinary-bullet guard.', '06'),
    'collectibles/please_retry.png': design(retry_art, (*GOLD,*STEEL,*WOOD,*BLUE), 'A brass winding wheel and wooden crank beside three separate blue drops; three delayed native tear retries.', '06'),
    'collectibles/access_pass.png': design(access_art, (*BLUE,*GOLD,*PAPER,*STEEL,*ORANGE), 'A punched brass-edged pass on a blue lanyard with an orange seal and no lettering; a floor-scoped damage benefit after an observed charged use.', '06'),
    'collectibles/absolutely_right.png': design(right_art, (*PINK,*ORANGE), 'A pink speech bubble holding a warm orange heart; agreeable words that charm whoever hurts you, without blocking the damage.', '07', CLAUDE_ART),
    'collectibles/million_context.png': design(context_art, (*PAPER,*WOOD), 'A tall fan-folded printout whose lower pages brown with age; long range whose tears lose strength in flight.', '07', CLAUDE_ART),
    'collectibles/skip_permissions.png': design(skip_art, (*STEEL,*GOLD,*ORANGE), 'An unlatched brass padlock with an orange hazard band and a crack; locks open themselves at the risk of deletion.', '07', CLAUDE_ART),
    'collectibles/vibe_coding.png': design(vibe_art, (*PURPLE,*BLUE,*PINK,*GOLD), 'Purple headphones above three differently coloured drops; random tear effects shipped on feel.', '07', CLAUDE_ART),
    'collectibles/tests_passing.png': design(tests_art, (*WOOD,*PAPER,*STEEL,*GREEN), 'A clipboard with three green ticked rows and no text; the room reports cleared while its enemies remain.', '07', CLAUDE_ART),
    'trinkets/thinking_cleared.png': design(cleared_art, (*WOOD,*STEEL,*YELLOW,*ORANGE), 'A wiped slate in a wooden frame with a yellow sponge and an orange spark; damage up while active charge is lost.', '07', CLAUDE_ART),
    'trinkets/welcome_notice.png': design(welcome_art, (*WOOD,*ORANGE,*PINK), 'A woven orange doormat with a stitched pink heart; the Ban Hammer welcomes enemies as allies instead of banning them.', '07', CLAUDE_ART),
    'trinkets/status_page.png': design(status_art, (*STEEL,*BLUE,*GREEN,*ORANGE), 'A monitor showing three healthy green lights while a small flame burns at its corner; slower risk with an always-calm display.', '07', CLAUDE_ART),
    'trinkets/appeal_form.png': design(appeal_art, (*PAPER,*BLUE,WOOD[0]), 'A folded form tied with a blue ribbon beside a quill; one filed appeal that survives a suspension.', '07', CLAUDE_ART),
    'collectibles/support_ticket.png': design(support_art, (*STEEL,*BLUE,*GOLD), 'A support headset with a boom microphone and a brass coin; paying coins for a human to lower risk.', '07', CLAUDE_ART),
    'collectibles/tungsten_cube.png': design(tungsten_art, (*STEEL,), 'A dense grey metal cube with a heavy shadow face; more damage and knockback for a slower carrier.', '08', CLAUDE_ART),
    'collectibles/pizza_glue.png': design(pizza_art, (*GOLD,*YELLOW,*RED,*PAPER), 'A pizza slice with white glue strands dripping from its tip; sticky tears that sometimes slow.', '08', CLAUDE_ART),
    'collectibles/strawberry.png': design(strawberry_art, (*RED,*YELLOW,*GREEN), 'A plain strawberry with yellow seeds and a green crown, and no lettering; every third tear counts double.', '08', CLAUDE_ART),
    'collectibles/golden_gate.png': design(gate_art, (*ORANGE,*BLUE), 'A generic orange suspension-bridge tower over blue water; spectral tears that pass over obstacles like a bridge.', '08', CLAUDE_ART),
    'collectibles/seahorse_emoji.png': design(seahorse_art, (*GOLD,*BLUE), 'A golden seahorse with a curled tail inside a faint blue wisp; summoning something that definitely exists.', '08', CLAUDE_ART),
    'collectibles/temperature_dial.png': design(dial_art, (*STEEL,*BLUE,*GOLD,*ORANGE), 'A round knob whose scale runs from cool blue to hot orange; a toggle between steady damage and random tear effects.', '08', CLAUDE_ART),
    'collectibles/deep_research.png': design(research_art, (*BLUE,*RED,*GREEN,*PURPLE,*PAPER), 'A tall stack of coloured books topped by a rolled map; reading many sources to reveal the floor.', '08', CLAUDE_ART),
    'collectibles/rejection_letter.png': design(rejection_art, (*PAPER,*RED), 'An opened envelope holding a letter crossed out in red; a hit that clears nearby bullets.', '08', CLAUDE_ART),
    'collectibles/red_stamp.png': design(stamp_art, (*WOOD,*STEEL,*RED,PAPER[2]), 'A rubber stamp with a wooden knob above a red mark; stamping an enemy so it slows and cannot hurt on contact.', '08', CLAUDE_ART),
    'collectibles/cache_cartridge.png': design(cartridge_art, (*STEEL,*BLUE,*PAPER,GOLD[1]), 'A game cartridge with a blank label, gold contacts and speed lines; faster movement in rooms already cached.', '08', CLAUDE_ART),
    'collectibles/checkpoint_pin.png': design(pin_art, (*RED,PAPER[2],STEEL[0],BLUE[1]), 'A red map pin pushed into the floor with a dashed return arc; pin a spot, then teleport back to it.', '09', CLAUDE_ART),
    'collectibles/rate_limit_valve.png': design(valve_art, (*STEEL,*RED), 'A steel pipe joint closed by a round red handwheel; pausing your attacks builds a stronger next shot.', '09', CLAUDE_ART),
    'collectibles/consensus_coin.png': design(consensus_art, (*GOLD,), 'A gold coin embossed with three overlapping rings that agree in the middle; different damage sources that agree add a pulse.', '09', CLAUDE_ART),
    'collectibles/error_budget.png': design(budget_art, (*PINK,*GOLD), 'A pink piggy bank with a coin dropping in and a small crack; the first hit each floor spends the budget for speed.', '09', CLAUDE_ART),
    'collectibles/em_dash.png': design(dash_art, (*BLUE,*STEEL), 'A long steel needle piercing straight through two blue tears; piercing tears drawn without any glyph.', '09', CLAUDE_ART),
    'collectibles/blueberry.png': design(blueberry_art, (*BLUE,PURPLE[0],PURPLE[1],GREEN[0],GREEN[1]), 'Three dusty blueberries with dark star-shaped crowns, and no lettering; every third tear splits.', '09', CLAUDE_ART),
    'trinkets/claudius_discount.png': design(discount_art, (*PAPER,WOOD[1],RED[1],*GOLD), 'A paper price tag on a string, slashed in red, beside a brass coin; shop refunds paid for by floor fees.', '09', CLAUDE_ART),
    'trinkets/small_rock.png': design(rock_art, (*STEEL,*PAPER,BLUE[0]), 'One small angular grey rock served on a plate with a spoon; breaking rocks heals.', '09', CLAUDE_ART),
    'trinkets/mt_moon.png': design(moon_art, (PURPLE[0],PURPLE[1],PAPER[2],YELLOW[1],YELLOW[2]), 'A dark mountain with a cave mouth under a pale crescent moon; revisiting rooms in the cave maps the floor.', '09', CLAUDE_ART),
    'trinkets/ai_language_model.png': design(model_art, (*BLUE,STEEL[0],PURPLE[1],PURPLE[2]), 'A blue umbrella deflecting purple curse drops; refusing one curse each floor.', '09', CLAUDE_ART),
    'trinkets/prompt_leak.png': design(leak_art, (*BLUE,*PAPER,WOOD[0],WOOD[1]), 'A cracked glass jar holding a rolled note, leaking a blue drip; the floor reveals its special rooms.', '09', CLAUDE_ART),
    'trinkets/disgrace_loop.png': design(disgrace_art, (*BLUE,PURPLE[0],PURPLE[1]), 'A pale ice cube ringed by a purple looping arrow; the first hit in a room freezes every enemy.', '09', CLAUDE_ART),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def icon_path(value):
    require(isinstance(value, str) and re.fullmatch(
        r'(collectibles|trinkets)/[a-z0-9_]+\.png', value),
        f'Invalid icon path: {value!r}')
    return value


def registrations(root):
    """Validate registration and pools independently of artwork production."""
    xml = ET.parse(root / 'content/items.xml').getroot()
    require(xml.tag == 'items' and xml.get('gfxroot') == 'gfx/items/',
            'Expected items XML with gfx/items/ root')
    result, names = {}, set()
    for item in xml:
        name, value = item.get('name'), item.get('gfx')
        require(item.tag in ('active', 'passive', 'trinket'), 'Unknown item kind')
        require(isinstance(name, str) and name.strip(), 'Missing registered name')
        # The engine adds the collectibles/ or trinkets/ folder itself; a folder
        # in the XML value doubles it and the icon renders transparent.
        require(isinstance(value, str) and re.fullmatch(r'[a-z0-9_]+\.png', value),
                f'{name}: gfx must be a bare file name, got {value!r}')
        folder = 'trinkets' if item.tag == 'trinket' else 'collectibles'
        gfx = icon_path(f'{folder}/{value}')
        require(name not in names and gfx not in result, 'Duplicate item name or gfx')
        names.add(name)
        result[gfx] = {'name': name, 'kind': item.tag}
    require(result, 'No item registrations')
    collectibles = {v['name'] for v in result.values() if v['kind'] != 'trinket'}
    for item in ET.parse(root / 'content/itempools.xml').iter('Item'):
        require(item.get('Name') in collectibles, f'Undefined collectible pool entry: {item.get("Name")}')
    return result


def registry(root):
    entries = json.loads((root / MANIFEST).read_text(encoding='utf-8'))
    require(isinstance(entries, dict) and entries.get('schema_version') == SCHEMA_VERSION,
            'Unsupported item-art manifest schema')
    require(isinstance(entries.get('entries'), list), 'Expected item-art entries list')
    registered = registrations(root)
    result, names = {}, set()
    for entry in entries['entries']:
        require(isinstance(entry, dict), 'Invalid item-art entry')
        gfx = icon_path(entry.get('gfx'))
        require(gfx not in result, f'Duplicate manifest path: {gfx}')
        require(gfx in registered, f'Unknown manifest path: {gfx}')
        require(entry.get('name') == registered[gfx]['name'], f'{gfx}: registered name mismatch')
        require(entry['name'] not in names, 'Duplicate manifest name')
        require(entry.get('status') in ('placeholder', 'designed'), f'{gfx}: unknown artwork status')
        names.add(entry['name'])
        result[gfx] = entry
    require(set(result) == set(registered), 'Manifest is missing registered icons')
    return result


def placeholder_pixels(gfx):
    key = PurePosixPath(gfx).stem
    require(key in legacy.SPRITES, f'No placeholder producer: {gfx}')
    folder = 'trinkets' if key in legacy.TRINKETS else 'collectibles'
    require(gfx == f'{folder}/{key}.png', f'Placeholder kind mismatch: {gfx}')
    grid = legacy.render(legacy.SPRITES[key]())
    if key in legacy.PIXEL_SYMMETRIC:
        for row in grid:
            for x in range(legacy.SIZE // 2):
                row[legacy.SIZE - 1 - x] = row[x]
    return legacy.rgba(grid)


def png_bytes(pixels):
    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data
                + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))
    raw = b''.join(b'\0' + bytes(v for pixel in row for v in pixel) for row in pixels)
    header = struct.pack('>IIBBBBB', len(pixels[0]), len(pixels), 8, 6, 0, 0, 0)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header)
            + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def visible_palette(pixels):
    return sorted({'#%02x%02x%02x' % tuple(p[:3]) for row in pixels for p in row if p[3]})


def pixel_contract(pixels, palette, designed):
    require(len(pixels) == 32 and all(len(row) == 32 for row in pixels), 'Expected 32x32 pixels')
    require(all(len(p) == 4 and all(type(v) is int and 0 <= v <= 255 for v in p)
                for row in pixels for p in row), 'Expected RGBA8 values')
    require(all(p[3] in (0, 255) for row in pixels for p in row), 'Undeclared alpha; hard edges required')
    visible = [(x, y) for y, row in enumerate(pixels) for x, p in enumerate(row) if p[3]]
    require(visible, 'Empty icon')
    require(len(visible) < 1024, 'Opaque icon background')
    require(set(visible_palette(pixels)) <= set(palette), 'Undeclared visible colour')
    if designed:
        require(all(0 < x < 31 and 0 < y < 31 for x, y in visible),
                'Designed icon needs a transparent outer margin')


def contact_path(root, relative):
    require(isinstance(relative, str) and relative.startswith('docs/art/')
            and '\\' not in relative and ':' not in relative
            and '..' not in PurePosixPath(relative).parts,
            'Contact sheet must be a repository path under docs/art/')
    require((root / relative).is_file(), 'Missing contact sheet')
    return relative


def produce(root, entry, designs=None):
    """Return canonical record/PNG from a declared status and drawing source."""
    designs = DESIGNS if designs is None else designs
    gfx, status = icon_path(entry['gfx']), entry['status']
    if status == 'placeholder':
        pixels = placeholder_pixels(gfx)
        palette = visible_palette(pixels)
        drawing = {'file': 'tools/make_placeholders.py', 'function': PurePosixPath(gfx).stem, 'version': 1}
        author = 'Project contributors; see resources/ART_LICENSE.md'
        provenance = 'Existing original procedural placeholder; no external pixels.'
        description = 'Legacy placeholder for ' + entry['name'] + '; designed artwork pending.'
        contact, exception = None, ''
    else:
        require(status == 'designed' and gfx in designs, f'{gfx}: missing designed producer')
        d = designs[gfx]
        require(type(d.version) is int and d.version > 0, 'Invalid drawing version')
        require(all(isinstance(v, str) and v.strip() for v in
                    (d.description, d.author, d.provenance)), 'Missing design provenance or meaning')
        palette = list(d.palette)
        require(palette and len(set(palette)) == len(palette)
                and all(isinstance(c, str) and re.fullmatch(r'#[0-9a-f]{6}', c) for c in palette),
                'Invalid declared palette')
        require(len(palette) <= 16 or (isinstance(d.palette_exception, str) and d.palette_exception.strip()),
                'More than 16 declared colours need a documented reason')
        contact = contact_path(root, d.contact_sheet)
        pixels = d.draw()
        drawing = {'file': 'tools/make_item_art.py', 'function': d.draw.__name__, 'version': d.version}
        author, provenance, description, exception = d.author, d.provenance, d.description, d.palette_exception
    pixel_contract(pixels, palette, status == 'designed')
    png = png_bytes(pixels)
    record = {'name': entry['name'], 'gfx': gfx, 'status': status, 'drawing': drawing,
              'author': author, 'license': 'MIT', 'provenance': provenance,
              'size': [32, 32], 'alpha': [0, 255], 'palette': palette,
              'palette_exception': exception, 'sha256': hashlib.sha256(png).hexdigest(),
              'description': description, 'contact_sheet': contact}
    return record, png


def check(root=ROOT, designs=None):
    entries = registry(root)
    on_disk = {p.relative_to(root / ICON_ROOT).as_posix() for p in (root / ICON_ROOT).rglob('*.png')}
    require(on_disk == set(entries), 'Missing or unregistered icon files')
    for gfx, entry in entries.items():
        path = root / ICON_ROOT / gfx
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) >= 33, f'{gfx}: not PNG')
        require(struct.unpack('>II', data[16:24]) == (32, 32), f'{gfx}: expected 32x32')
        require(data[24:26] == bytes([8, 6]), f'{gfx}: expected RGBA8')
        _, _, rows = read_rgba(path)
        pixels = [[tuple(row[x:x+4]) for x in range(0, 128, 4)] for row in rows]
        expected, png = produce(root, entry, designs)
        pixel_contract(pixels, expected['palette'], entry['status'] == 'designed')
        require(data == png, f'{gfx}: pixels/PNG differ from deterministic producer')
        require(entry == expected, f'{gfx}: manifest metadata/hash differs from producer')
    # Retain the original silhouette gate independently of designed silhouettes.
    for name in legacy.SYMMETRIC:
        grid = legacy.SPRITES[name]()
        require(all((grid[y][x] != '.') == (grid[y][31-x] != '.')
                    for y in range(32) for x in range(16)), f'Asymmetric legacy silhouette: {name}')
    return dict(Counter(entry['status'] for entry in entries.values()))


def write(root=ROOT, out=None, designs=None):
    """Regenerate only registered paths; validate all producers before writing."""
    entries = registry(root)
    generated = [produce(root, entry, designs) for entry in entries.values()]
    destination = root / ICON_ROOT if out is None else Path(out)
    require(out is None or destination.resolve() != (root / ICON_ROOT).resolve(),
            'Export must not target canonical icons; use write without out')
    for record, png in generated:
        path = destination / record['gfx']
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)
    # An export never changes the canonical manifest.
    if out is None:
        manifest = {'schema_version': SCHEMA_VERSION, 'entries': [r for r, _ in generated]}
        (root / MANIFEST).write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


def initialize(root=ROOT):
    path = root / MANIFEST
    require(not path.exists(), 'Manifest already exists; refusing to replace statuses')
    entries = [{'name': v['name'], 'gfx': gfx, 'status': 'placeholder'}
               for gfx, v in registrations(root).items()]
    records = [produce(root, entry)[0] for entry in entries]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({'schema_version': SCHEMA_VERSION, 'entries': records}, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--check', action='store_true')
    action.add_argument('--write', action='store_true')
    action.add_argument('--init-manifest', action='store_true')
    parser.add_argument('--out', type=Path, help='Export icons without updating the manifest (with --write)')
    args = parser.parse_args()
    if args.out is not None:
        if not args.write:
            parser.error('--out requires --write')
        require(args.out.resolve() != (ROOT / ICON_ROOT).resolve(), 'Use --write without --out for canonical icons')
    if args.check:
        print('  OK: registered item artwork, metadata, deterministic pixels and pools:', check())
    elif args.write:
        write(out=args.out)
    else:
        initialize()


if __name__ == '__main__':
    main()
