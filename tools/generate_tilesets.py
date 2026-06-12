#!/usr/bin/env python3
"""
Generate GBA-style 24x24 placeholder tilesets for Artist Apprentice RPG.

Outputs three 192x72 PNG files (8 cols x 3 rows) to:
  assets/sprites/tilesets/workshop_tiles.png
  assets/sprites/tilesets/florence_tiles.png
  assets/sprites/tilesets/nature_tiles.png

Each tile is designed to connect seamlessly with neighbours.
Run from the project root: python3 tools/generate_tilesets.py
"""

import os
from PIL import Image, ImageDraw

T = 24   # tile size
COLS = 8
ROWS = 3

# ── Palettes ─────────────────────────────────────────────────────────────────
# Workshop (warm indoor – stone, wood, plaster)
WL  = (185, 145,  90, 255)  # wood light
WM  = (148, 110,  58, 255)  # wood mid
WD  = (108,  72,  32, 255)  # wood dark
SL  = (188, 182, 168, 255)  # stone light
SM  = (148, 140, 125, 255)  # stone mid
SD  = (105,  98,  85, 255)  # stone dark
PL  = (228, 218, 192, 255)  # plaster light
PM  = (195, 182, 150, 255)  # plaster mid
WA  = (205, 125,  65, 255)  # warm accent
WS  = ( 82, 140, 195, 255)  # window sky
FR  = (215,  80,  45, 255)  # rug red
FO  = (205, 155,  55, 255)  # rug orange/gold
FG  = (195, 210, 175, 255)  # glass green tint
FLM = (235, 175,  65, 255)  # flame
WOK = (  0,   0,   0,   0)  # transparent

# Florence (outdoor city – cobble, terracotta, plaster)
CBL = (162, 152, 132, 255)  # cobble light
CBD = (115, 105,  88, 255)  # cobble dark
CBS = ( 78,  70,  58, 255)  # cobble shadow
CFL = (228, 218, 192, 255)  # facade light (plaster)
CFD = (192, 178, 148, 255)  # facade mid
TRL = (205, 148, 102, 255)  # terracotta light
TRD = (162, 108,  65, 255)  # terracotta dark
SKY = (135, 175, 215, 255)  # sky / window
GRN = ( 82, 148,  72, 255)  # plant green
WTR = ( 90, 152, 205, 255)  # water
WSH = ( 60,  52,  42, 255)  # city shadow

# Nature (outdoor – grass, dirt, rock, clay, water)
GL  = (105, 175,  72, 255)  # grass light
GM  = ( 72, 135,  50, 255)  # grass mid
GD  = ( 48,  95,  32, 255)  # grass dark
DL  = (168, 122,  72, 255)  # dirt light
DM  = (128,  90,  50, 255)  # dirt mid
DD  = ( 92,  62,  32, 255)  # dirt dark
RL  = (148, 138, 122, 255)  # rock light
RM  = (108, 100,  86, 255)  # rock mid
RD  = ( 75,  68,  56, 255)  # rock dark
CL  = (195, 115,  72, 255)  # clay
CD  = (152,  82,  48, 255)  # clay dark
MN  = (148, 168, 178, 255)  # mineral/crystal
WL2 = ( 88, 148, 202, 255)  # water light
WD2 = ( 55, 108, 162, 255)  # water dark
TRK = (115,  82,  48, 255)  # tree bark
TC  = ( 65, 130,  50, 255)  # tree canopy
TH  = ( 95, 165,  70, 255)  # canopy highlight


# ── Drawing helpers ───────────────────────────────────────────────────────────
def fill(d, x, y, c):
    """Fill the whole tile at grid coords x,y with colour c."""
    d.rectangle([x*T, y*T, x*T+T-1, y*T+T-1], fill=c)

def rect(d, x, y, lx, ty, rx, by, c):
    """Draw a filled rect in local coords within the tile at x,y."""
    d.rectangle([x*T+lx, y*T+ty, x*T+rx, y*T+by], fill=c)

def px(d, x, y, lx, ty, c):
    """Set a single pixel in local coords."""
    d.point([x*T+lx, y*T+ty], fill=c)

def hline(d, x, y, lx, rx, ty, c):
    d.line([x*T+lx, y*T+ty, x*T+rx, y*T+ty], fill=c)

def vline(d, x, y, lx, ty, by, c):
    d.line([x*T+lx, y*T+ty, x*T+lx, y*T+by], fill=c)


# ── Tile drawing functions ────────────────────────────────────────────────────

def wood_floor(d, x, y):
    fill(d, x, y, WL)
    for row in [6, 7, 14, 15]:
        hline(d, x, y, 0, 23, row, WM)
    # vertical plank seams (staggered)
    for sx in [8, 16]:
        vline(d, x, y, sx, 0, 6, WD)
    for sx in [4, 12, 20]:
        vline(d, x, y, sx, 8, 14, WD)
    for sx in [6, 14, 22]:
        vline(d, x, y, sx, 16, 23, WD)

def stone_floor(d, x, y):
    fill(d, x, y, SL)
    for g in [8, 16]:
        hline(d, x, y, 0, 23, g, SM)
        vline(d, x, y, g, 0, 23, SM)
    # corner dots
    for cx in [0, 8, 16]:
        for cy in [0, 8, 16]:
            px(d, x, y, cx, cy, SD)

def dark_stone_floor(d, x, y):
    fill(d, x, y, SM)
    for g in [8, 16]:
        hline(d, x, y, 0, 23, g, SD)
        vline(d, x, y, g, 0, 23, SD)

def rug_center(d, x, y):
    fill(d, x, y, FR)
    rect(d, x, y, 2, 2, 21, 21, (200, 60, 35, 255))
    rect(d, x, y, 4, 4, 19, 19, (185, 50, 28, 255))
    # diamond pattern lines
    for i in range(0, 24, 4):
        px(d, x, y, i, 11, FO)
        px(d, x, y, 11, i, FO)

def doorstep(d, x, y):
    fill(d, x, y, SM)
    rect(d, x, y, 1, 1, 22, 22, SL)
    hline(d, x, y, 1, 22, 11, SM)
    hline(d, x, y, 1, 22, 12, SM)

def shadow_tile(d, x, y):
    fill(d, x, y, (45, 35, 20, 180))

def wall_base_floor(d, x, y):
    fill(d, x, y, WL)
    for row in [6, 7, 14, 15]:
        hline(d, x, y, 0, 23, row, WM)
    # shadow at top (near wall)
    rect(d, x, y, 0, 0, 23, 3, (80, 60, 35, 180))

def stone_wall(d, x, y):
    fill(d, x, y, SM)
    # Brick courses (alternating offset)
    for row in range(3):
        ty = row * 8
        hline(d, x, y, 0, 23, ty, SD)
        # brick seams, offset alternating rows
        offset = 0 if row % 2 == 0 else 12
        for bx in range(offset, 24, 12):
            vline(d, x, y, bx, ty+1, ty+7, SD)
    hline(d, x, y, 0, 23, 23, SD)

def plaster_wall(d, x, y):
    fill(d, x, y, PL)
    hline(d, x, y, 0, 23, 23, PM)
    # subtle crack
    d.line([x*T+10, y*T+4, x*T+14, y*T+9, x*T+11, y*T+15], fill=PM)

def wall_window(d, x, y):
    fill(d, x, y, PL)
    hline(d, x, y, 0, 23, 23, PM)
    # window opening
    rect(d, x, y, 4, 3, 19, 18, WS)
    rect(d, x, y, 4, 3, 19, 18, SD)  # outline
    rect(d, x, y, 5, 4, 18, 17, WS)
    # cross pane
    hline(d, x, y, 5, 18, 10, (160, 145, 120, 255))
    vline(d, x, y, 11, 4, 17, (160, 145, 120, 255))

def wall_arch(d, x, y):
    fill(d, x, y, SM)
    # arch opening (dark void)
    rect(d, x, y, 4, 0, 19, 23, SD)
    rect(d, x, y, 5, 0, 18, 23, (25, 18, 10, 255))
    # arch stones around top
    for i in range(3):
        rect(d, x, y, 4+i*2, 0, 5+i*2, 3, SL)
    hline(d, x, y, 0, 23, 23, SD)

def wall_torch(d, x, y):
    fill(d, x, y, SM)
    stone_wall(d, x, y)
    # bracket
    rect(d, x, y, 9, 12, 14, 15, WD)
    # flame
    rect(d, x, y, 10, 5, 13, 12, WA)
    rect(d, x, y, 11, 3, 12, 7, FLM)

def wall_shelf(d, x, y):
    fill(d, x, y, SM)
    for row in range(3):
        ty = row * 8
        hline(d, x, y, 0, 23, ty, SD)
    # shelf planks
    rect(d, x, y, 2, 7, 21, 9, WM)
    rect(d, x, y, 2, 15, 21, 17, WM)
    hline(d, x, y, 0, 23, 23, SD)

def wall_corner(d, x, y):
    fill(d, x, y, SM)
    # Horizontal courses on right half
    for row in range(3):
        ty = row * 8
        hline(d, x, y, 12, 23, ty, SD)
    # Vertical stone on left half
    for col in [0, 8]:
        vline(d, x, y, col, 0, 23, SD)
    vline(d, x, y, 12, 0, 23, SD)
    hline(d, x, y, 0, 23, 23, SD)

def wall_top_cap(d, x, y):
    fill(d, x, y, SD)
    rect(d, x, y, 0, 0, 23, 6, SM)
    rect(d, x, y, 0, 0, 23, 3, SL)
    # crenellation hints
    for cx in range(0, 24, 8):
        rect(d, x, y, cx+1, 0, cx+5, 3, SM)

def station_paint(d, x, y):
    fill(d, x, y, WM)
    rect(d, x, y, 1, 1, 22, 22, WL)
    hline(d, x, y, 1, 22, 14, WM)
    # paint pots (coloured circles)
    for i, c in enumerate([(185,65,45,255),(65,105,185,255),(65,165,85,255)]):
        cx = 4 + i*7
        rect(d, x, y, cx, 3, cx+4, 9, c)
    # brushes
    rect(d, x, y, 3, 16, 5, 22, WD)
    rect(d, x, y, 10, 16, 12, 22, WD)
    rect(d, x, y, 17, 16, 19, 22, WD)

def station_canvas(d, x, y):
    fill(d, x, y, WM)
    rect(d, x, y, 1, 1, 22, 22, WL)
    hline(d, x, y, 1, 22, 14, WM)
    # canvas frame
    rect(d, x, y, 4, 2, 19, 12, WD)
    rect(d, x, y, 5, 3, 18, 11, (240, 235, 215, 255))
    # stretcher bars
    hline(d, x, y, 5, 18, 7, (220, 210, 190, 255))

def station_artwork(d, x, y):
    fill(d, x, y, WM)
    rect(d, x, y, 1, 1, 22, 22, WL)
    hline(d, x, y, 1, 22, 14, WM)
    # painting in progress (small canvas with rough colour)
    rect(d, x, y, 4, 2, 19, 12, WD)
    rect(d, x, y, 5, 3, 18, 11, (230, 220, 195, 255))
    rect(d, x, y, 6, 4, 11, 10, (185,105,75,255))
    rect(d, x, y, 12, 4, 17, 8, (80,130,180,255))

def workbench(d, x, y):
    fill(d, x, y, WM)
    rect(d, x, y, 1, 1, 22, 22, WL)
    rect(d, x, y, 0, 0, 23, 2, WD)  # back rail
    # tools scattered
    rect(d, x, y, 3, 5, 5, 14, WD)   # chisel handle
    rect(d, x, y, 3, 3, 5, 6, SM)    # chisel head
    rect(d, x, y, 10, 5, 20, 7, WD)  # ruler

def storage_chest(d, x, y):
    fill(d, x, y, WD)
    rect(d, x, y, 1, 1, 22, 22, WM)
    rect(d, x, y, 1, 1, 22, 10, WL)  # lid highlight
    # metal hasp
    rect(d, x, y, 9, 9, 14, 14, SM)
    rect(d, x, y, 10, 10, 13, 13, SL)
    # wood grain lines
    for gx in [6, 12, 18]:
        vline(d, x, y, gx, 2, 22, WD)

def fireplace(d, x, y):
    fill(d, x, y, SD)
    rect(d, x, y, 2, 0, 21, 18, SM)
    rect(d, x, y, 4, 0, 19, 14, (22, 14, 8, 255))  # dark interior
    # embers/glow
    rect(d, x, y, 6, 10, 17, 14, (185, 60, 20, 255))
    rect(d, x, y, 8, 6, 15, 11, WA)
    rect(d, x, y, 10, 3, 13, 8, FLM)

def pillar(d, x, y):
    fill(d, x, y, SL)
    # circle (top of pillar)
    d.ellipse([x*T+3, y*T+3, x*T+20, y*T+20], fill=SM, outline=SD)
    d.ellipse([x*T+6, y*T+6, x*T+17, y*T+17], fill=SL)
    # capital shadow
    rect(d, x, y, 3, 3, 20, 5, SD)


# ── Florence tiles ────────────────────────────────────────────────────────────
def cobblestone(d, x, y):
    fill(d, x, y, CBD)
    # cobble shapes
    stones = [(1,1,9,7),(11,2,21,8),(2,9,8,15),(10,9,20,14),
              (1,16,10,22),(12,16,22,22)]
    for s in stones:
        rect(d, x, y, s[0], s[1], s[2], s[3], CBL)
        hline(d, x, y, s[0]+1, s[2]-1, s[1]+1, (185,175,155,255))

def cobble_worn(d, x, y):
    fill(d, x, y, CBL)
    for g in [8, 16]:
        hline(d, x, y, 0, 23, g, CBD)
    for g in [6, 14, 20]:
        vline(d, x, y, g, 0, 7, CBD)
    for g in [4, 12, 18]:
        vline(d, x, y, g, 9, 15, CBD)
    for g in [8, 16]:
        vline(d, x, y, g, 17, 23, CBD)

def piazza_stone(d, x, y):
    fill(d, x, y, CFL)
    for g in [12]:
        hline(d, x, y, 0, 23, g, CFD)
        vline(d, x, y, g, 0, 23, CFD)
    for g in [0, 12]:
        px(d, x, y, g, 0, CBD)
        px(d, x, y, g, 12, CBD)

def dirt_earth(d, x, y):
    fill(d, x, y, DM)
    for i in range(8):
        px(d, x, y, (i*3+1)%23, (i*5+2)%22, DL)
        px(d, x, y, (i*5+3)%22, (i*3+1)%22, DD)

def street_steps(d, x, y):
    fill(d, x, y, CBL)
    for row in range(3):
        ty_s = row * 8
        rect(d, x, y, row, ty_s, 23-row, ty_s+7, CBL)
        hline(d, x, y, row, 23-row, ty_s+7, CBD)

def street_gutter(d, x, y):
    fill(d, x, y, CBD)
    cobble_worn(d, x, y)
    rect(d, x, y, 0, 20, 23, 23, CBS)

def bridge_stone(d, x, y):
    fill(d, x, y, CBL)
    for g in [8, 16]:
        vline(d, x, y, g, 0, 23, CBD)
    hline(d, x, y, 0, 23, 11, CBD)
    hline(d, x, y, 0, 23, 12, CBD)

def facade_plaster(d, x, y):
    fill(d, x, y, CFL)
    hline(d, x, y, 0, 23, 23, CFD)
    # subtle plaster texture – random lighter spots
    for i in range(5):
        lx2 = (i * 7 + 2) % 20
        ty2 = (i * 5 + 3) % 18
        px(d, x, y, lx2, ty2, (235, 228, 208, 255))

def facade_terracotta(d, x, y):
    fill(d, x, y, TRL)
    # stone blocks
    for row in range(3):
        ty2 = row * 8
        hline(d, x, y, 0, 23, ty2, TRD)
        offset = 0 if row % 2 == 0 else 10
        for bx in range(offset, 24, 10):
            vline(d, x, y, bx, ty2+1, ty2+7, TRD)
    hline(d, x, y, 0, 23, 23, TRD)

def facade_window(d, x, y):
    fill(d, x, y, CFL)
    hline(d, x, y, 0, 23, 23, CFD)
    # arch window
    rect(d, x, y, 5, 2, 18, 20, CBD)
    rect(d, x, y, 6, 3, 17, 19, SKY)
    # arch top (rounded – approximate with rects)
    rect(d, x, y, 7, 2, 16, 6, SKY)
    # cross pane
    hline(d, x, y, 6, 17, 12, CFD)
    vline(d, x, y, 11, 3, 19, CFD)

def facade_doorway(d, x, y):
    fill(d, x, y, TRL)
    facade_terracotta(d, x, y)
    rect(d, x, y, 4, 0, 19, 22, TRD)
    rect(d, x, y, 5, 0, 18, 21, (22, 14, 8, 255))
    # arch keystones
    for i in range(3):
        rect(d, x, y, 5+i*4, 0, 8+i*4, 3, TRL)

def roof_tile(d, x, y):
    fill(d, x, y, TRD)
    # overlapping semicircle tiles (roman/barrel style)
    for row in range(3):
        ty2 = row * 8
        for col in range(3):
            cx2 = col * 8
            d.ellipse([x*T+cx2, y*T+ty2, x*T+cx2+7, y*T+ty2+8],
                      fill=TRL, outline=TRD)

def roof_edge(d, x, y):
    fill(d, x, y, TRD)
    rect(d, x, y, 0, 0, 23, 8, TRL)
    hline(d, x, y, 0, 23, 8, TRD)
    # terracotta edge tiles
    for cx2 in range(0, 24, 6):
        rect(d, x, y, cx2+1, 0, cx2+4, 8, TRD)
    hline(d, x, y, 0, 23, 23, TRD)

def column(d, x, y):
    fill(d, x, y, CFL)
    # capital (wider top)
    rect(d, x, y, 3, 0, 20, 4, CBL)
    rect(d, x, y, 4, 4, 19, 4, CBD)
    # shaft
    rect(d, x, y, 7, 5, 16, 22, CBL)
    rect(d, x, y, 7, 5, 8, 22, (195, 188, 168, 255))  # highlight
    rect(d, x, y, 15, 5, 16, 22, CBD)  # shadow

def wall_coping(d, x, y):
    fill(d, x, y, CBL)
    rect(d, x, y, 0, 0, 23, 5, (200, 192, 172, 255))
    hline(d, x, y, 0, 23, 5, CBD)
    hline(d, x, y, 0, 23, 6, CBD)
    facade_terracotta(d, x, y)

def garden_grass(d, x, y):
    fill(d, x, y, GRN)
    for i in range(6):
        bx = (i * 7 + 1) % 20
        by = (i * 5 + 2) % 20
        px(d, x, y, bx, by, (60, 128, 52, 255))
        px(d, x, y, bx+1, by+1, (105, 162, 82, 255))

def fountain_water(d, x, y):
    fill(d, x, y, WTR)
    d.ellipse([x*T+3, y*T+3, x*T+20, y*T+20], fill=(75, 138, 195, 255))
    d.ellipse([x*T+8, y*T+8, x*T+15, y*T+15], fill=(105, 165, 218, 255))
    # ripple rings
    d.ellipse([x*T+5, y*T+5, x*T+18, y*T+18], fill=None,
              outline=(85, 148, 200, 255))

def fountain_stone(d, x, y):
    fill(d, x, y, CBL)
    d.ellipse([x*T+1, y*T+1, x*T+22, y*T+22], fill=CBL, outline=CBD)
    d.ellipse([x*T+4, y*T+4, x*T+19, y*T+19], fill=WTR, outline=CBD)

def market_awning(d, x, y):
    fill(d, x, y, (185, 45, 35, 255))
    # stripes
    for sx in range(0, 24, 4):
        rect(d, x, y, sx, 0, sx+1, 23, (215, 210, 185, 255))
    # scalloped bottom edge
    for ex in range(0, 24, 6):
        d.ellipse([x*T+ex, y*T+16, x*T+ex+6, y*T+22],
                  fill=(165, 35, 25, 255))

def well_top(d, x, y):
    fill(d, x, y, CBL)
    d.ellipse([x*T+2, y*T+2, x*T+21, y*T+21], fill=CBL, outline=CBD)
    d.ellipse([x*T+5, y*T+5, x*T+18, y*T+18], fill=(22, 14, 8, 255))
    # rope
    vline(d, x, y, 11, 2, 5, WD)

def tree_canopy_fl(d, x, y):
    fill(d, x, y, (55, 42, 28, 200))  # semi-transparent shadow
    d.ellipse([x*T+1, y*T+1, x*T+22, y*T+22], fill=(55, 118, 45, 255))
    d.ellipse([x*T+3, y*T+2, x*T+18, y*T+17], fill=GRN)

def flower_bed(d, x, y):
    fill(d, x, y, GRN)
    for i, c in enumerate([(205,60,50,255),(230,185,55,255),(75,115,205,255)]):
        bx = 3 + i * 7
        by = 8
        d.ellipse([x*T+bx, y*T+by, x*T+bx+4, y*T+by+4], fill=c)
        vline(d, x, y, bx+2, by+4, 18, (68, 125, 58, 255))

def transparent_tile(d, x, y):
    pass  # leave fully transparent


# ── Nature tiles ──────────────────────────────────────────────────────────────
def grass_light(d, x, y):
    fill(d, x, y, GL)
    # small blade marks
    for i in range(8):
        bx = (i * 5 + 2) % 22
        by = (i * 7 + 1) % 21
        px(d, x, y, bx, by, GM)

def grass_dark(d, x, y):
    fill(d, x, y, GM)
    for i in range(6):
        bx = (i * 7 + 1) % 22
        by = (i * 5 + 3) % 21
        px(d, x, y, bx, by, GD)
        px(d, x, y, bx+1, by, GL)

def dirt_path(d, x, y):
    fill(d, x, y, DL)
    for i in range(5):
        bx = (i * 6 + 1) % 21
        by = (i * 4 + 2) % 21
        px(d, x, y, bx, by, DM)
        px(d, x, y, bx+2, by+1, DD)

def rocky_ground(d, x, y):
    fill(d, x, y, RM)
    pebbles = [(2,2,8,7),(10,3,17,8),(1,11,7,17),(12,10,20,16),(4,18,10,22)]
    for p in pebbles:
        rect(d, x, y, p[0], p[1], p[2], p[3], RL)
        px(d, x, y, p[0]+1, p[1]+1, (165, 155, 138, 255))

def clay_deposit(d, x, y):
    fill(d, x, y, CL)
    # layered horizontal bands
    for row in range(3):
        ty2 = row * 8
        hline(d, x, y, 0, 23, ty2, CD)
        rect(d, x, y, 0, ty2+1, 23, ty2+5, CL)
        rect(d, x, y, 0, ty2+5, 23, ty2+7, (205, 125, 82, 255))
    # ochre highlight specks
    for i in range(4):
        px(d, x, y, i*6+1, i*3+2, (215, 145, 88, 255))

def mineral_vein(d, x, y):
    fill(d, x, y, RM)
    rocky_ground(d, x, y)
    # crystal specks
    for i in range(6):
        cx2 = (i * 7 + 3) % 20
        cy = (i * 5 + 2) % 20
        rect(d, x, y, cx2, cy, cx2+2, cy+2, MN)

def sandy_bank(d, x, y):
    fill(d, x, y, (198, 175, 128, 255))
    for i in range(4):
        px(d, x, y, i*6+2, i*4+3, (215, 195, 148, 255))
        px(d, x, y, i*5+1, i*6+1, (178, 155, 108, 255))

def shallow_water(d, x, y):
    fill(d, x, y, WL2)
    # ripples
    for row in [6, 14]:
        hline(d, x, y, 2, 10, row, WD2)
        hline(d, x, y, 13, 21, row+2, WD2)

def tree_canopy_top(d, x, y):
    fill(d, x, y, GD)
    d.ellipse([x*T+1, y*T+1, x*T+22, y*T+22], fill=TC)
    d.ellipse([x*T+4, y*T+3, x*T+16, y*T+14], fill=TH)

def tree_trunk(d, x, y):
    fill(d, x, y, GL)
    d.ellipse([x*T+6, y*T+6, x*T+17, y*T+17], fill=TRK, outline=DD)
    # grain lines
    vline(d, x, y, 10, 7, 16, (98, 68, 38, 255))
    vline(d, x, y, 13, 7, 16, (98, 68, 38, 255))

def bush_small(d, x, y):
    fill(d, x, y, GL)
    d.ellipse([x*T+3, y*T+5, x*T+20, y*T+20], fill=GM)
    d.ellipse([x*T+5, y*T+3, x*T+18, y*T+16], fill=TC)
    d.ellipse([x*T+7, y*T+5, x*T+15, y*T+12], fill=TH)

def tall_grass(d, x, y):
    fill(d, x, y, GM)
    for bx in range(2, 24, 5):
        vline(d, x, y, bx, 0, 18, GD)
        vline(d, x, y, bx+1, 0, 14, GL)
    fill_bottom = (0, 0, 0, 0)  # keep base as mid green
    rect(d, x, y, 0, 18, 23, 23, GM)

def wildflowers(d, x, y):
    fill(d, x, y, GL)
    grass_light(d, x, y)
    for i, c in enumerate([(220,200,55,255),(195,65,55,255),(75,105,200,255)]):
        bx = 3 + i * 7
        by = 5 + (i % 2) * 5
        d.ellipse([x*T+bx, y*T+by, x*T+bx+3, y*T+by+3], fill=c)

def fallen_log(d, x, y):
    fill(d, x, y, GM)
    rect(d, x, y, 0, 8, 23, 15, TRK)
    rect(d, x, y, 1, 9, 22, 14, (128, 92, 52, 255))
    # end grain circle
    d.ellipse([x*T+1, y*T+8, x*T+7, y*T+15], fill=(148, 108, 62, 255), outline=TRK)
    d.ellipse([x*T+3, y*T+10, x*T+5, y*T+13], fill=DD)

def mushrooms(d, x, y):
    fill(d, x, y, DM)
    # two mushrooms
    for mx, my, c in [(5,8,(195,55,42,255)),(14,11,(215,195,155,255))]:
        rect(d, x, y, mx, my, mx+5, my+8, (225, 215, 185, 255))  # stem
        d.ellipse([x*T+mx-2, y*T+my-5, x*T+mx+7, y*T+my+2], fill=c)
        # spots on red mushroom
        if c[0] > 190 and c[1] < 100:
            px(d, x, y, mx+1, my-3, (235, 230, 210, 255))
            px(d, x, y, mx+4, my-2, (235, 230, 210, 255))

def tree_shadow_floor(d, x, y):
    fill(d, x, y, GD)
    rect(d, x, y, 0, 0, 23, 23, (35, 72, 22, 255))

def large_rock(d, x, y):
    fill(d, x, y, RM)
    d.polygon([x*T+4, y*T+18, x*T+2, y*T+10, x*T+8, y*T+2,
               x*T+16, y*T+1, x*T+22, y*T+8, x*T+21, y*T+19], fill=RL)
    # highlight and shadow
    d.line([x*T+4, y*T+8, x*T+10, y*T+3, x*T+16, y*T+3],
           fill=(165, 155, 138, 255))
    d.line([x*T+18, y*T+10, x*T+20, y*T+16], fill=RD)

def rock_cluster(d, x, y):
    fill(d, x, y, GM)
    for rx, ry, rw, rh in [(2,12,8,10),(10,14,7,8),(15,10,8,12),(5,10,6,6)]:
        rect(d, x, y, rx, ry, rx+rw, ry+rh, RL)
        px(d, x, y, rx+1, ry+1, (165, 155, 138, 255))

def cave_entrance(d, x, y):
    fill(d, x, y, RM)
    rect(d, x, y, 3, 0, 20, 23, RD)
    rect(d, x, y, 5, 0, 18, 20, (22, 14, 8, 255))
    # arch outline
    for ax in [5, 17]:
        vline(d, x, y, ax, 0, 8, RM)
    hline(d, x, y, 5, 17, 0, RM)

def cave_floor(d, x, y):
    fill(d, x, y, (35, 25, 14, 255))
    for i in range(4):
        bx = i * 6 + 1
        by = i * 4 + 2
        px(d, x, y, bx, by, RD)

def deep_water(d, x, y):
    fill(d, x, y, WD2)
    d.ellipse([x*T+4, y*T+8, x*T+16, y*T+16], fill=(42, 90, 148, 255))
    hline(d, x, y, 2, 10, 4, WL2)
    hline(d, x, y, 13, 21, 14, WL2)

def water_edge(d, x, y):
    fill(d, x, y, DL)
    rect(d, x, y, 0, 0, 23, 11, WL2)
    hline(d, x, y, 0, 23, 11, WD2)
    hline(d, x, y, 0, 23, 12, (105, 162, 200, 255))

def cliff_face(d, x, y):
    fill(d, x, y, RM)
    for row in range(4):
        ty2 = row * 6
        hline(d, x, y, 0, 23, ty2, RD)
        rect(d, x, y, 0, ty2+1, 23, ty2+5, RL)
    # shadow side
    rect(d, x, y, 20, 0, 23, 23, (88, 80, 65, 255))

def cliff_top(d, x, y):
    fill(d, x, y, GL)
    rect(d, x, y, 0, 12, 23, 23, RM)
    hline(d, x, y, 0, 23, 12, RD)
    # grass overhang
    for bx in range(0, 24, 4):
        rect(d, x, y, bx, 10, bx+3, 13, GM)


# ── Assemble sheets ───────────────────────────────────────────────────────────

WORKSHOP_TILES = [
    # Row 0 – floors
    [wood_floor, stone_floor, dark_stone_floor, rug_center,
     doorstep,   shadow_tile, wall_base_floor,  stone_floor],
    # Row 1 – walls
    [stone_wall, plaster_wall, wall_window, wall_arch,
     wall_torch, wall_shelf,  wall_corner, wall_top_cap],
    # Row 2 – object tops
    [station_paint, station_canvas, station_artwork, workbench,
     storage_chest, fireplace,      pillar,          shadow_tile],
]

FLORENCE_TILES = [
    # Row 0 – ground
    [cobblestone,   cobble_worn,    piazza_stone,   dirt_earth,
     street_steps,  street_gutter,  bridge_stone,   transparent_tile],
    # Row 1 – building facades
    [facade_plaster, facade_terracotta, facade_window, facade_doorway,
     roof_tile,      roof_edge,         column,        wall_coping],
    # Row 2 – city features
    [garden_grass,  fountain_water, fountain_stone, market_awning,
     well_top,      tree_canopy_fl, flower_bed,     transparent_tile],
]

NATURE_TILES = [
    # Row 0 – ground
    [grass_light,  grass_dark,   dirt_path,    rocky_ground,
     clay_deposit, mineral_vein, sandy_bank,   shallow_water],
    # Row 1 – vegetation
    [tree_canopy_top, tree_trunk,  bush_small,   tall_grass,
     wildflowers,     fallen_log,  mushrooms,    tree_shadow_floor],
    # Row 2 – terrain / special
    [large_rock,  rock_cluster,  cave_entrance, cave_floor,
     deep_water,  water_edge,    cliff_face,    cliff_top],
]


def generate_sheet(tile_grid, out_path):
    img = Image.new('RGBA', (COLS * T, ROWS * T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for row_idx, row in enumerate(tile_grid):
        for col_idx, fn in enumerate(row):
            fn(d, col_idx, row_idx)
    img.save(out_path)
    print(f"  Saved {out_path}  ({img.size[0]}x{img.size[1]})")


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    out_dir = os.path.join(project_root, 'assets', 'sprites', 'tilesets')
    os.makedirs(out_dir, exist_ok=True)

    print("Generating placeholder tilesets (24x24, GBA palette)...")
    generate_sheet(WORKSHOP_TILES, os.path.join(out_dir, 'workshop_tiles.png'))
    generate_sheet(FLORENCE_TILES, os.path.join(out_dir, 'florence_tiles.png'))
    generate_sheet(NATURE_TILES,   os.path.join(out_dir, 'nature_tiles.png'))
    print("Done.")
