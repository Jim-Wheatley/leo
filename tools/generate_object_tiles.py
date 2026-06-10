#!/usr/bin/env python3
"""
Generate placeholder workshop object tiles and wire them into Workshop.tscn.

Sheet: 8 cols x 4 rows of 24x24 tiles → 192x96px
Layout:
  Row 0: [WB-TL][WB-TR][Easel-TL][Easel-TR][PT-TL][PT-TR][Tbl-TL][Tbl-TR]
  Row 1: [WB-BL][WB-BR][Easel-BL][Easel-BR][PT-BL][PT-BR][Tbl-BL][Tbl-BR]
  Row 2: [TShlf-L][TShlf-R][PShlf-L][PShlf-R][Seat][Bed-T][ ][ ]
  Row 3: [       ][       ][       ][       ][    ][Bed-B][ ][ ]

WB=Workbench  PT=Paint mixing table  TShlf=Tool shelf  PShlf=Pigment shelf

Run from project root:
    python3 tools/generate_object_tiles.py
"""

import os, re, struct
from PIL import Image, ImageDraw

T = 24
COLS, ROWS = 8, 4

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILESET_DIR  = os.path.join(PROJECT_ROOT, 'assets', 'sprites', 'tilesets')
SCENE_PATH   = os.path.join(PROJECT_ROOT, 'scenes', 'environments', 'Workshop.tscn')

PNG_NAME    = 'workshop_objects.png'
TRES_NAME   = 'workshop_objects_tileset.tres'
EXT_ID      = 'ts_workshop_obj'

# ── Palette ───────────────────────────────────────────────────────────────────
WL  = (205, 165, 98, 255)   # wood light
WM  = (158, 118, 58, 255)   # wood mid
WD  = (112, 76, 28, 255)    # wood dark
WVD = (72, 46, 12, 255)     # wood very dark

CVS = (245, 240, 222, 255)  # canvas white
CVS_S = (200, 195, 175, 255) # canvas shadow
FR  = (165, 128, 68, 255)   # easel frame
FR_D = (118, 86, 38, 255)   # frame dark

BL  = (228, 218, 195, 255)  # bedding light
BL_S = (188, 178, 155, 255) # bedding shadow
HB  = (98, 70, 38, 255)     # headboard

SHL = (195, 158, 98, 255)   # shelf light
SHD = (142, 108, 52, 255)   # shelf dark

ST  = (178, 138, 78, 255)   # stool top
ST_D = (128, 92, 40, 255)   # stool shadow/leg

PR  = (195, 65, 42, 255)    # paint red
PB  = (62, 108, 195, 255)   # paint blue
PG  = (62, 175, 82, 255)    # paint green
PY  = (215, 188, 52, 255)   # paint yellow
PO  = (205, 128, 45, 255)   # paint orange

# Tool colours
TC  = (145, 140, 128, 255)  # tool (metal grey)
TC_D = (95, 92, 82, 255)    # tool dark

TRP = (0, 0, 0, 0)          # transparent

# ── Drawing helpers ───────────────────────────────────────────────────────────
def fill(d, gx, gy, c):
    d.rectangle([gx*T, gy*T, gx*T+T-1, gy*T+T-1], fill=c)

def rect(d, gx, gy, lx, ty, rx, by, c):
    d.rectangle([gx*T+lx, gy*T+ty, gx*T+rx, gy*T+by], fill=c)

def hline(d, gx, gy, lx, rx, ty, c):
    d.line([gx*T+lx, gy*T+ty, gx*T+rx, gy*T+ty], fill=c)

def vline(d, gx, gy, lx, ty, by, c):
    d.line([gx*T+lx, gy*T+ty, gx*T+lx, gy*T+by], fill=c)

def dot(d, gx, gy, lx, ty, c):
    d.point([gx*T+lx, gy*T+ty], fill=c)


# ── Workbench 2×2 ─────────────────────────────────────────────────────────────
def wb_tl(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)   # back edge (near wall)
    rect(d, gx, gy, 0, 4, 23, 16, WL)   # surface highlight
    rect(d, gx, gy, 0, 4, 2, 23, WD)    # left edge shadow
    for gx2 in [8, 16]:
        vline(d, gx, gy, gx2, 4, 23, WD)  # plank seams

def wb_tr(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)
    rect(d, gx, gy, 0, 4, 23, 16, WL)
    rect(d, gx, gy, 21, 4, 23, 23, WD)  # right edge shadow
    # chisel/tool silhouette on surface
    rect(d, gx, gy, 4, 8, 18, 10, TC)
    rect(d, gx, gy, 4, 8, 6, 12, TC_D)  # handle
    for gx2 in [8, 16]:
        vline(d, gx, gy, gx2, 4, 7, WD)

def wb_bl(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)     # top edge (front lip of surface)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 0, 2, 2, 23, WVD)   # left leg
    rect(d, gx, gy, 3, 2, 23, 15, WM)   # front apron
    rect(d, gx, gy, 3, 16, 23, 19, WD)  # lower apron/shelf
    rect(d, gx, gy, 3, 20, 10, 23, WVD) # left leg base

def wb_br(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 21, 2, 23, 23, WVD) # right leg
    rect(d, gx, gy, 0, 2, 20, 15, WM)
    rect(d, gx, gy, 0, 16, 20, 19, WD)
    rect(d, gx, gy, 13, 20, 20, 23, WVD) # right leg base


# ── Easel/Painting area 2×2 ───────────────────────────────────────────────────
def easel_tl(d, gx, gy):
    fill(d, gx, gy, TRP)
    # Canvas top-left quadrant
    rect(d, gx, gy, 4, 2, 23, 23, FR_D)    # frame border
    rect(d, gx, gy, 6, 4, 23, 23, CVS)     # canvas
    rect(d, gx, gy, 6, 4, 23, 6, CVS_S)    # canvas top shadow

def easel_tr(d, gx, gy):
    fill(d, gx, gy, TRP)
    # Canvas top-right quadrant
    rect(d, gx, gy, 0, 2, 19, 23, FR_D)    # frame border
    rect(d, gx, gy, 0, 4, 17, 23, CVS)     # canvas
    rect(d, gx, gy, 0, 4, 17, 6, CVS_S)    # top shadow
    # Small paint sketch on canvas
    rect(d, gx, gy, 3, 8, 12, 14, (195, 155, 98, 255))  # rough sketch colour

def easel_bl(d, gx, gy):
    fill(d, gx, gy, TRP)
    # Canvas lower-left + left leg
    rect(d, gx, gy, 4, 0, 23, 19, FR_D)    # frame
    rect(d, gx, gy, 6, 0, 23, 17, CVS)     # canvas lower portion
    rect(d, gx, gy, 6, 15, 23, 17, CVS_S)  # canvas bottom shadow
    # Left leg of easel A-frame
    rect(d, gx, gy, 6, 19, 9, 23, FR)      # leg
    rect(d, gx, gy, 5, 22, 10, 23, FR_D)   # foot

def easel_br(d, gx, gy):
    fill(d, gx, gy, TRP)
    rect(d, gx, gy, 0, 0, 19, 19, FR_D)
    rect(d, gx, gy, 0, 0, 17, 17, CVS)
    rect(d, gx, gy, 0, 15, 17, 17, CVS_S)
    # Right leg
    rect(d, gx, gy, 14, 19, 17, 23, FR)
    rect(d, gx, gy, 13, 22, 18, 23, FR_D)
    # Centre support leg
    rect(d, gx, gy, 9, 18, 11, 23, FR_D)


# ── Paint mixing table 2×2 ────────────────────────────────────────────────────
def pt_tl(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)   # back edge
    rect(d, gx, gy, 0, 4, 23, 18, WL)   # surface
    rect(d, gx, gy, 0, 4, 2, 23, WD)    # left edge
    # Pigment pots on back-left
    for i, c in enumerate([PR, PB]):
        bx = 4 + i * 8
        rect(d, gx, gy, bx, 5, bx+5, 12, c)
        rect(d, gx, gy, bx+1, 5, bx+4, 7, (min(c[0]+40,255), min(c[1]+40,255), min(c[2]+40,255), 255))

def pt_tr(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)
    rect(d, gx, gy, 0, 4, 23, 18, WL)
    rect(d, gx, gy, 21, 4, 23, 23, WD)
    # More paint pots
    for i, c in enumerate([PG, PY, PO]):
        bx = 1 + i * 7
        rect(d, gx, gy, bx, 5, bx+5, 12, c)
        rect(d, gx, gy, bx+1, 5, bx+4, 7, (min(c[0]+40,255), min(c[1]+40,255), min(c[2]+40,255), 255))
    # Brush lying on surface
    rect(d, gx, gy, 2, 14, 20, 16, WVD)
    rect(d, gx, gy, 2, 14, 4, 16, PR)   # brush tip

def pt_bl(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 0, 2, 2, 23, WVD)
    rect(d, gx, gy, 3, 2, 23, 13, WM)
    # Paint drip stain on front
    rect(d, gx, gy, 8, 4, 11, 12, PR)
    rect(d, gx, gy, 9, 12, 10, 15, PR)
    rect(d, gx, gy, 3, 14, 23, 19, WD)
    rect(d, gx, gy, 3, 20, 10, 23, WVD)

def pt_br(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 21, 2, 23, 23, WVD)
    rect(d, gx, gy, 0, 2, 20, 13, WM)
    rect(d, gx, gy, 12, 4, 15, 12, PB)  # paint stain
    rect(d, gx, gy, 13, 12, 14, 14, PB)
    rect(d, gx, gy, 0, 14, 20, 19, WD)
    rect(d, gx, gy, 13, 20, 20, 23, WVD)


# ── Generic table 2×2 ─────────────────────────────────────────────────────────
def tbl_tl(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)
    rect(d, gx, gy, 0, 4, 23, 16, WL)
    rect(d, gx, gy, 0, 4, 2, 23, WD)
    for gx2 in [6, 12, 18]:
        vline(d, gx, gy, gx2, 4, 23, WD)

def tbl_tr(d, gx, gy):
    fill(d, gx, gy, WM)
    rect(d, gx, gy, 0, 0, 23, 3, WVD)
    rect(d, gx, gy, 0, 4, 23, 16, WL)
    rect(d, gx, gy, 21, 4, 23, 23, WD)
    for gx2 in [6, 12, 18]:
        vline(d, gx, gy, gx2, 4, 23, WD)

def tbl_bl(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 0, 2, 2, 23, WVD)
    rect(d, gx, gy, 3, 2, 23, 19, WM)
    # Decorative apron moulding
    rect(d, gx, gy, 4, 8, 22, 11, WD)
    rect(d, gx, gy, 3, 20, 10, 23, WVD)

def tbl_br(d, gx, gy):
    fill(d, gx, gy, WL)
    hline(d, gx, gy, 0, 23, 0, WVD)
    hline(d, gx, gy, 0, 23, 1, WM)
    rect(d, gx, gy, 21, 2, 23, 23, WVD)
    rect(d, gx, gy, 0, 2, 20, 19, WM)
    rect(d, gx, gy, 1, 8, 19, 11, WD)
    rect(d, gx, gy, 13, 20, 20, 23, WVD)


# ── Tool shelf 2×1 ────────────────────────────────────────────────────────────
def tshelf_l(d, gx, gy):
    fill(d, gx, gy, WVD)             # wall background
    # Bracket
    rect(d, gx, gy, 0, 14, 4, 23, SHD)
    rect(d, gx, gy, 1, 15, 3, 22, SHL)
    # Shelf plank
    rect(d, gx, gy, 0, 10, 23, 14, SHL)
    rect(d, gx, gy, 0, 10, 23, 11, (218, 182, 115, 255))  # top highlight
    rect(d, gx, gy, 0, 13, 23, 14, SHD)  # bottom shadow
    # Hanging chisel
    rect(d, gx, gy, 8, 0, 11, 10, TC)
    rect(d, gx, gy, 8, 7, 11, 10, TC_D)  # tip
    rect(d, gx, gy, 9, 0, 10, 2, WD)     # hook

def tshelf_r(d, gx, gy):
    fill(d, gx, gy, WVD)
    rect(d, gx, gy, 19, 14, 23, 23, SHD)  # bracket
    rect(d, gx, gy, 20, 15, 22, 22, SHL)
    rect(d, gx, gy, 0, 10, 23, 14, SHL)
    rect(d, gx, gy, 0, 10, 23, 11, (218, 182, 115, 255))
    rect(d, gx, gy, 0, 13, 23, 14, SHD)
    # Hanging hammer
    rect(d, gx, gy, 8, 1, 11, 10, WD)   # handle
    rect(d, gx, gy, 5, 0, 14, 5, TC)    # head
    rect(d, gx, gy, 13, 0, 14, 10, TC_D)
    # Small hook
    rect(d, gx, gy, 9, 0, 10, 2, WVD)


# ── Pigment shelf 2×1 ─────────────────────────────────────────────────────────
def pshelf_l(d, gx, gy):
    fill(d, gx, gy, WVD)
    rect(d, gx, gy, 0, 14, 4, 23, SHD)
    rect(d, gx, gy, 1, 15, 3, 22, SHL)
    rect(d, gx, gy, 0, 10, 23, 14, SHL)
    rect(d, gx, gy, 0, 10, 23, 11, (218, 182, 115, 255))
    rect(d, gx, gy, 0, 13, 23, 14, SHD)
    # Two pigment jars on shelf
    for i, c in enumerate([PR, PY]):
        jx = 3 + i * 9
        rect(d, gx, gy, jx, 3, jx+6, 10, c)
        rect(d, gx, gy, jx+1, 3, jx+5, 5, (min(c[0]+50,255), min(c[1]+50,255), min(c[2]+50,255), 255))
        rect(d, gx, gy, jx, 9, jx+6, 10, (max(c[0]-40,0), max(c[1]-40,0), max(c[2]-40,0), 255))

def pshelf_r(d, gx, gy):
    fill(d, gx, gy, WVD)
    rect(d, gx, gy, 19, 14, 23, 23, SHD)
    rect(d, gx, gy, 20, 15, 22, 22, SHL)
    rect(d, gx, gy, 0, 10, 23, 14, SHL)
    rect(d, gx, gy, 0, 10, 23, 11, (218, 182, 115, 255))
    rect(d, gx, gy, 0, 13, 23, 14, SHD)
    for i, c in enumerate([PB, PG]):
        jx = 3 + i * 9
        rect(d, gx, gy, jx, 3, jx+6, 10, c)
        rect(d, gx, gy, jx+1, 3, jx+5, 5, (min(c[0]+50,255), min(c[1]+50,255), min(c[2]+50,255), 255))
        rect(d, gx, gy, jx, 9, jx+6, 10, (max(c[0]-40,0), max(c[1]-40,0), max(c[2]-40,0), 255))


# ── Seat / stool 1×1 ──────────────────────────────────────────────────────────
def seat(d, gx, gy):
    fill(d, gx, gy, TRP)
    # Circular stool seat from 3/4 above
    d.ellipse([gx*T+3, gy*T+2, gx*T+20, gy*T+16], fill=ST, outline=ST_D)
    d.ellipse([gx*T+5, gy*T+3, gx*T+17, gy*T+12], fill=WL)  # highlight
    # Three legs visible from below seat
    rect(d, gx, gy, 4, 15, 7, 22, ST_D)   # left leg
    rect(d, gx, gy, 10, 16, 13, 23, ST_D) # centre leg
    rect(d, gx, gy, 16, 15, 19, 22, ST_D) # right leg
    # Feet
    hline(d, gx, gy, 3, 8, 22, WVD)
    hline(d, gx, gy, 9, 14, 23, WVD)
    hline(d, gx, gy, 15, 20, 22, WVD)


# ── Bed 1×2 ───────────────────────────────────────────────────────────────────
def bed_top(d, gx, gy):
    # Headboard + pillow (top tile)
    fill(d, gx, gy, BL_S)
    rect(d, gx, gy, 0, 0, 23, 8, HB)    # headboard
    rect(d, gx, gy, 1, 1, 22, 7, (115, 85, 45, 255))  # headboard panel
    # Pillow
    rect(d, gx, gy, 2, 9, 21, 20, BL)
    rect(d, gx, gy, 2, 9, 21, 11, (255, 252, 242, 255))  # pillow highlight
    rect(d, gx, gy, 2, 18, 21, 20, BL_S)  # pillow shadow
    # Sheet fold
    rect(d, gx, gy, 0, 20, 23, 23, BL)
    hline(d, gx, gy, 0, 23, 20, BL_S)

def bed_bottom(d, gx, gy):
    # Sheet + footboard (bottom tile)
    fill(d, gx, gy, BL)
    # Sheet texture
    for row in [4, 10, 16]:
        hline(d, gx, gy, 2, 21, row, BL_S)
    rect(d, gx, gy, 0, 0, 2, 23, WD)    # left frame
    rect(d, gx, gy, 21, 0, 23, 23, WD)  # right frame
    # Footboard
    rect(d, gx, gy, 0, 18, 23, 23, HB)
    rect(d, gx, gy, 1, 19, 22, 22, (115, 85, 45, 255))  # panel


# ── Tile grid ─────────────────────────────────────────────────────────────────
TILE_GRID = [
    # Row 0
    [wb_tl,     wb_tr,     easel_tl,  easel_tr,  pt_tl,     pt_tr,     tbl_tl,    tbl_tr],
    # Row 1
    [wb_bl,     wb_br,     easel_bl,  easel_br,  pt_bl,     pt_br,     tbl_bl,    tbl_br],
    # Row 2
    [tshelf_l,  tshelf_r,  pshelf_l,  pshelf_r,  seat,      bed_top,   None,      None],
    # Row 3
    [None,      None,      None,      None,      None,      bed_bottom, None,      None],
]

def blank(d, gx, gy):
    pass  # leave transparent

def generate_png(out_path):
    img = Image.new('RGBA', (COLS * T, ROWS * T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for row_idx, row in enumerate(TILE_GRID):
        for col_idx, fn in enumerate(row):
            if fn is not None:
                fn(d, col_idx, row_idx)
    img.save(out_path)
    print(f'  PNG saved: {out_path}  ({img.size[0]}×{img.size[1]})')


# ── TileSet .tres ─────────────────────────────────────────────────────────────
def generate_tres(out_path, png_name):
    tile_lines = '\n'.join(
        f'{col}:{row}/0 = 0'
        for row in range(ROWS)
        for col in range(COLS)
    )
    content = f"""\
[gd_resource type="TileSet" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/tilesets/{png_name}" id="1"]

[sub_resource type="TileSetAtlasSource" id="1"]
texture = ExtResource("1")
texture_region_size = Vector2i({T}, {T})
{tile_lines}

[resource]
tile_size = Vector2i({T}, {T})
sources/0 = SubResource("1")
"""
    with open(out_path, 'w') as f:
        f.write(content)
    print(f'  TileSet saved: {out_path}')


# ── Scene patching ────────────────────────────────────────────────────────────
def patch_workshop_scene(scene_path, tres_name, ext_id):
    with open(scene_path) as f:
        text = f.read()

    # Skip if already patched
    if ext_id in text:
        print(f'  Workshop.tscn: Objects layer already present – skipped')
        return

    # 1. Bump load_steps
    text = re.sub(r'load_steps=(\d+)',
                  lambda m: f'load_steps={int(m.group(1))+1}', text, count=1)

    # 2. Append ext_resource after the last existing one
    ext_line = (f'[ext_resource type="TileSet" '
                f'path="res://assets/sprites/tilesets/{tres_name}" '
                f'id="{ext_id}"]')
    last_ext = list(re.finditer(r'\[ext_resource [^\]]+\]', text))[-1]
    ins = text.index('\n', last_ext.end()) + 1
    text = text[:ins] + ext_line + '\n' + text[ins:]

    # 3. Insert Objects TileMapLayer immediately after the floor TileMap node block
    #    (the floor TileMap ends just before [node name="Background"])
    objects_layer = (
        '[node name="Objects" type="TileMapLayer" parent="."]\n'
        f'tile_set = ExtResource("{ext_id}")\n'
        'z_index = 1\n'
    )
    # Insert before Background (which is the first regular node after TileMap)
    m = re.search(r'\[node name="Background" type="ColorRect"', text)
    if m:
        text = text[:m.start()] + objects_layer + '\n' + text[m.start():]

    with open(scene_path, 'w') as f:
        f.write(text)
    print(f'  Workshop.tscn: Objects TileMapLayer added (z_index=1)')


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    print('Generating workshop object tiles...')
    os.makedirs(TILESET_DIR, exist_ok=True)
    generate_png(os.path.join(TILESET_DIR, PNG_NAME))
    generate_tres(os.path.join(TILESET_DIR, TRES_NAME), PNG_NAME)
    patch_workshop_scene(SCENE_PATH, TRES_NAME, EXT_ID)
    print('\nDone.')
    print('\nTile layout reference:')
    print('  Row 0/1 col 0-1: Workbench      (2×2)')
    print('  Row 0/1 col 2-3: Easel           (2×2)')
    print('  Row 0/1 col 4-5: Paint table     (2×2)')
    print('  Row 0/1 col 6-7: Table           (2×2)')
    print('  Row 2   col 0-1: Tool shelves    (2×1)')
    print('  Row 2   col 2-3: Pigment shelves (2×1)')
    print('  Row 2   col 4:   Seat/stool      (1×1)')
    print('  Row 2+3 col 5:   Bed             (1×2)')
