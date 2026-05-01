#!/usr/bin/env python3
"""
Inject TileMap nodes into Godot 4 environment scenes.

Steps performed:
  1. Write TileSet .tres resource files for each environment
  2. Update Workshop.tscn, Florence.tscn, NaturalAreas.tscn:
       - add ext_resource reference to the TileSet
       - insert a TileMap node (format=2) as the first child
       - hide the existing Background / WorkshopFloor ColorRect nodes

Run from the project root:
    python3 tools/inject_tilemaps.py
"""

import os
import re

T = 24  # tile size in pixels

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE_DIR  = os.path.join(PROJECT_ROOT, 'scenes', 'environments')
TILESET_DIR = os.path.join(PROJECT_ROOT, 'assets', 'sprites', 'tilesets')


# ── Tile-data encoding ────────────────────────────────────────────────────────

def encode_cell(mx, my, ax, ay, source=0):
    """Return the 3-int Godot 4 TileMap cell encoding."""
    coords = (mx & 0xFFFF) | ((my & 0xFFFF) << 16)
    atlas  = (ax & 0xFFFF) | ((ay & 0xFFFF) << 16)
    return (coords, source, atlas)


def build_tile_data(layout_fn, cols, rows):
    """
    Call layout_fn(col, row) → (atlas_x, atlas_y) or None for empty.
    Returns a flat list of int32 values ready for PackedInt32Array.
    """
    data = []
    for y in range(rows):
        for x in range(cols):
            result = layout_fn(x, y)
            if result is not None:
                ax, ay = result
                data.extend(encode_cell(x, y, ax, ay))
    return data


def pack(data):
    """Format a list of ints as a Godot PackedInt32Array literal."""
    return 'PackedInt32Array(' + ', '.join(str(v) for v in data) + ')'


# ── Map layout functions ──────────────────────────────────────────────────────

def workshop_layout(x, y):
    # 43 cols × 32 rows  (1032 × 768 px)
    # Row 0  – wall top cap
    if y == 0:
        if x == 0 or x == 42: return (6, 1)   # wall corner
        return (7, 1)                           # wall top cap
    # Row 1  – stone wall face
    if y == 1:
        if x == 0 or x == 42: return (6, 1)   # wall corner
        return (0, 1)                           # stone wall
    # Rows 2–31 – wood floor
    if x == 0 or x == 42:
        return (6, 0)                           # shadow tile at sides
    return (0, 0)                               # wood floor


def florence_layout(x, y):
    # 86 cols × 64 rows  (2064 × 1536 px)
    # Horizontal main street band  (matches MainStreet ColorRect ~row 25–29)
    main_street = 25 <= y <= 29
    # Vertical cross streets
    cross1 = 25 <= x <= 29   # ~CrossStreet1 x=600-700
    cross2 = 50 <= x <= 54   # ~CrossStreet2 x=1200-1300
    on_street = main_street or cross1 or cross2

    # Central piazza where streets intersect
    piazza = (38 <= x <= 56) and (22 <= y <= 42)

    # Top 2 rows: building facades alternating plaster / terracotta
    if y == 0:
        return (7, 1) if (x // 10) % 2 == 0 else (7, 1)   # wall coping
    if y == 1:
        return (0, 1) if (x // 10) % 2 == 0 else (1, 1)   # plaster / terracotta

    if piazza:
        return (2, 0)   # piazza stone
    if on_street:
        return (1, 0)   # cobblestone worn (main arteries)
    return (0, 0)       # cobblestone everywhere else


def nature_layout(x, y):
    # 43 cols × 32 rows  (1032 × 768 px)

    # Clay deposit patches  (from ClayDeposit positions in NaturalAreas.tscn)
    #   ClayDeposit1 (200,300) → tile (8,12)
    #   ClayDeposit2 (400,500) → tile (16,20)
    #   ClayDeposit3 (700,200) → tile (29, 8)
    clay_patches = [
        range(7, 11), range(11, 14),    # patch 1 cols, rows
        range(15, 19), range(19, 22),   # patch 2
        range(28, 32), range(7, 10),    # patch 3
    ]
    if (7 <= x <= 10 and 11 <= y <= 13) or \
       (15 <= x <= 18 and 19 <= y <= 21) or \
       (28 <= x <= 31 and 7 <= y <= 9):
        return (4, 0)   # clay deposit

    # Mineral vein patches
    #   MineralVein1 (150,600) → tile (6,25)
    #   MineralVein2 (800,400) → tile (33,16)
    if (5 <= x <= 8 and 24 <= y <= 26) or \
       (32 <= x <= 35 and 15 <= y <= 17):
        return (5, 0)   # mineral vein

    # Dirt path – diagonal from top-left toward bottom-right
    path_col = y // 2 + 2
    if abs(x - path_col) <= 1:
        return (2, 0)   # dirt path

    # Scattered tree canopy (deterministic pattern)
    tree_positions = {(3,3),(5,8),(12,5),(20,3),(35,6),(38,2),
                      (10,15),(25,18),(40,22),(8,26),(30,28)}
    if (x, y) in tree_positions:
        return (0, 1)   # tree canopy top

    # Some rocky ground patches
    if (18 <= x <= 22 and 10 <= y <= 14) or \
       (2 <= x <= 5 and 20 <= y <= 24):
        return (3, 0)   # rocky ground

    # Grass variation – alternate light / dark in a checker-ish pattern
    if (x + y) % 7 == 0:
        return (1, 0)   # grass dark variation

    return (0, 0)       # grass light (dominant tile)


# ── TileSet .tres generation ──────────────────────────────────────────────────

ATLAS_TILES = [(col, row) for row in range(3) for col in range(8)]

def tileset_tres(png_filename):
    """Return the content of a TileSet .tres resource file."""
    tile_lines = '\n'.join(f'{ax}:{ay}/0 = 0' for ax, ay in ATLAS_TILES)
    return f"""\
[gd_resource type="TileSet" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/tilesets/{png_filename}" id="1"]

[sub_resource type="TileSetAtlasSource" id="1"]
texture = ExtResource("1")
texture_region_size = Vector2i(24, 24)
{tile_lines}

[resource]
tile_size = Vector2i({T}, {T})
sources/0 = SubResource("1")
"""


# ── Scene patching helpers ────────────────────────────────────────────────────

def increment_load_steps(text):
    """Bump load_steps=N by 1 in the scene header."""
    def bump(m):
        return f'load_steps={int(m.group(1)) + 1}'
    return re.sub(r'load_steps=(\d+)', bump, text, count=1)


def insert_ext_resource(text, new_ext_resource_line):
    """Append a new [ext_resource ...] block after the last existing one."""
    # Find the last ext_resource block
    matches = list(re.finditer(r'\[ext_resource [^\]]+\]', text))
    if matches:
        last = matches[-1]
        insert_pos = text.index('\n', last.end()) + 1
        return text[:insert_pos] + new_ext_resource_line + '\n' + text[insert_pos:]
    # Fallback: insert before the first [sub_resource] or [node]
    m = re.search(r'\[(sub_resource|node) ', text)
    if m:
        return text[:m.start()] + new_ext_resource_line + '\n\n' + text[m.start():]
    return text


def insert_after_root_node(text, root_node_name, tilemap_block):
    """Insert tilemap_block immediately after the [node name="ROOT"] declaration."""
    pattern = rf'(\[node name="{root_node_name}" type="Node2D"[^\]]*\][^\[]*)'
    m = re.search(pattern, text)
    if m:
        insert_pos = m.end()
        return text[:insert_pos] + '\n' + tilemap_block + '\n' + text[insert_pos:]
    return text


def hide_node(text, node_name, parent='.'):
    """Add visible = false to a named [node] block if not already present."""
    pattern = rf'(\[node name="{node_name}" type="[^"]*" parent="{re.escape(parent)}"\])'
    def add_visible(m):
        return m.group(0) + '\nvisible = false'
    # Only patch if not already hidden
    if re.search(rf'\[node name="{node_name}".*\]\nvisible = false', text):
        return text
    return re.sub(pattern, add_visible, text, count=1)


# ── Per-scene configuration ───────────────────────────────────────────────────

SCENES = [
    {
        'file': 'Workshop.tscn',
        'root': 'Workshop',
        'tileset_tres': 'workshop_tileset.tres',
        'tileset_png':  'workshop_tiles.png',
        'ext_id':       'ts_workshop',
        'map_cols': 43,
        'map_rows': 32,
        'layout_fn': workshop_layout,
        'hide_nodes': ['Background', 'WorkshopFloor'],
    },
    {
        'file': 'Florence.tscn',
        'root': 'Florence',
        'tileset_tres': 'florence_tileset.tres',
        'tileset_png':  'florence_tiles.png',
        'ext_id':       'ts_florence',
        'map_cols': 86,
        'map_rows': 64,
        'layout_fn': florence_layout,
        'hide_nodes': ['Background'],
    },
    {
        'file': 'NaturalAreas.tscn',
        'root': 'NaturalAreas',
        'tileset_tres': 'nature_tileset.tres',
        'tileset_png':  'nature_tiles.png',
        'ext_id':       'ts_nature',
        'map_cols': 43,
        'map_rows': 32,
        'layout_fn': nature_layout,
        'hide_nodes': ['Background'],
    },
]


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    # 1. Write TileSet .tres files
    print("Writing TileSet resources...")
    for cfg in SCENES:
        tres_content = tileset_tres(cfg['tileset_png'])
        tres_path = os.path.join(TILESET_DIR, cfg['tileset_tres'])
        with open(tres_path, 'w') as f:
            f.write(tres_content)
        print(f"  {cfg['tileset_tres']}")

    # 2. Patch scene files
    print("\nPatching scene files...")
    for cfg in SCENES:
        scene_path = os.path.join(SCENE_DIR, cfg['file'])
        with open(scene_path, 'r') as f:
            text = f.read()

        # Build tile data
        print(f"  {cfg['file']}: generating {cfg['map_cols']}x{cfg['map_rows']} layout...", end='', flush=True)
        data = build_tile_data(cfg['layout_fn'], cfg['map_cols'], cfg['map_rows'])
        tile_count = len(data) // 3
        print(f" {tile_count} tiles placed")

        # Ext resource line
        ext_line = (
            f'[ext_resource type="TileSet" '
            f'path="res://assets/sprites/tilesets/{cfg["tileset_tres"]}" '
            f'id="{cfg["ext_id"]}"]'
        )

        # TileMap node block
        tilemap_block = f"""\
[node name="TileMap" type="TileMap" parent="."]
tile_set = ExtResource("{cfg['ext_id']}")
format = 2
layer_0/name = "Ground"
layer_0/y_sort_enabled = false
layer_0/z_index = 0
layer_0/tile_data = {pack(data)}"""

        # Apply patches
        text = increment_load_steps(text)
        text = insert_ext_resource(text, ext_line)
        text = insert_after_root_node(text, cfg['root'], tilemap_block)
        for node_name in cfg['hide_nodes']:
            text = hide_node(text, node_name)

        with open(scene_path, 'w') as f:
            f.write(text)
        print(f"  {cfg['file']}: patched ✓")

    print("\nDone. Open the project in Godot to verify.")


if __name__ == '__main__':
    main()
