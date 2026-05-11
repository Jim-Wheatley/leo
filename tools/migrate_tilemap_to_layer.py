#!/usr/bin/env python3
"""
One-time migration: convert TileMap nodes to TileMapLayer nodes in environment scenes.

Changes per scene:
  - [node type="TileMap"] → [node type="TileMapLayer"]
  - Removes: format, layer_0/name, layer_0/y_sort_enabled, layer_0/z_index
  - Converts: layer_0/tile_data = PackedInt32Array(...) →
              tile_map_data = PackedByteArray(...)

Encoding change (per cell):
  Old — 3 × int32:
    coords_int  = (map_x & 0xFFFF) | ((map_y & 0xFFFF) << 16)
    source_id   (int32)
    atlas_int   = (atlas_x & 0xFFFF) | ((atlas_y & 0xFFFF) << 16)

  New — 12 bytes:
    map_x    uint16 LE
    map_y    uint16 LE
    source   uint32 LE
    atlas_x  uint16 LE
    atlas_y  uint16 LE

Run from project root:
    python3 tools/migrate_tilemap_to_layer.py
"""

import os
import re
import struct

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE_DIR = os.path.join(PROJECT_ROOT, 'scenes', 'environments')

SCENES = ['Workshop.tscn', 'Florence.tscn', 'NaturalAreas.tscn']


def int32_array_to_byte_array(int32_values: list[int]) -> str:
    """
    Convert a flat list of TileMap (deprecated) int32 values to a Godot 4.5
    TileMapLayer PackedByteArray literal string.

    Godot 4.5 tile_map_data layout (tile_map_layer.cpp):
      2-byte header : uint16 = 0  (TILE_MAP_LAYER_DATA_FORMAT_0)
      Per cell (12 bytes, all uint16 LE):
        map_x(u16) map_y(u16) source_id(u16) atlas_x(u16) atlas_y(u16) alt(u16)
    """
    # 2-byte format-version header
    buf = bytearray(struct.pack('<H', 0))

    for i in range(0, len(int32_values), 3):
        coords    = int32_values[i]
        source_id = int32_values[i + 1]
        atlas     = int32_values[i + 2]

        map_x   = coords & 0xFFFF
        map_y   = (coords >> 16) & 0xFFFF
        atlas_x = atlas & 0xFFFF
        atlas_y = (atlas >> 16) & 0xFFFF
        alt     = 0

        # All fields are uint16; source_id must be uint16 (not uint32)
        buf += struct.pack('<HHHHHH', map_x, map_y, source_id & 0xFFFF,
                           atlas_x, atlas_y, alt)

    return 'PackedByteArray(' + ', '.join(str(b) for b in buf) + ')'


def migrate_scene(text: str) -> tuple[str, bool]:
    """
    Find and replace the TileMap node block in a scene file.
    Returns (updated_text, was_changed).
    """
    # Match the full TileMap node block:
    # [node name="TileMap" type="TileMap" parent="."]
    # <any properties until the next [node or end of file>
    pattern = re.compile(
        r'(\[node name="TileMap" type="TileMap" parent="\."]\n)'  # header line
        r'((?:(?!\[).+\n)*)',                                      # property lines
        re.MULTILINE
    )

    match = pattern.search(text)
    if not match:
        return text, False

    header_line  = match.group(1)
    prop_block   = match.group(2)

    # ── Extract tile_set line (keep verbatim) ─────────────────────────────────
    tile_set_line = ''
    for line in prop_block.splitlines():
        if line.startswith('tile_set ='):
            tile_set_line = line
            break

    # ── Extract and convert tile_data ─────────────────────────────────────────
    data_match = re.search(r'layer_0/tile_data = PackedInt32Array\(([^)]+)\)',
                           prop_block)
    if not data_match:
        print('  WARNING: no tile_data found – skipping conversion')
        return text, False

    int32_values = [int(v.strip()) for v in data_match.group(1).split(',')]
    cell_count   = len(int32_values) // 3
    byte_array   = int32_array_to_byte_array(int32_values)

    # ── Build replacement block ───────────────────────────────────────────────
    replacement = (
        '[node name="TileMap" type="TileMapLayer" parent="."]\n'
        f'{tile_set_line}\n'
        f'tile_map_data = {byte_array}\n'
    )

    updated = text[:match.start()] + replacement + text[match.end():]
    return updated, True, cell_count


def main():
    for filename in SCENES:
        path = os.path.join(SCENE_DIR, filename)
        with open(path) as f:
            original = f.read()

        result = migrate_scene(original)
        if len(result) == 2:          # not changed (no tile_data found)
            text, changed = result
            cell_count = 0
        else:
            text, changed, cell_count = result

        if not changed:
            print(f'  {filename}: no TileMap node found – skipped')
            continue

        with open(path, 'w') as f:
            f.write(text)
        print(f'  {filename}: migrated {cell_count} cells  TileMap → TileMapLayer ✓')

    print('\nDone.')


if __name__ == '__main__':
    print('Migrating TileMap → TileMapLayer...')
    main()
