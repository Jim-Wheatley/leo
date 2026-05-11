#!/usr/bin/env python3
"""
Fix incorrect tile_map_data encoding in TileMapLayer nodes.

The previous encoding used struct '<HHIHH' (source_id as uint32, no header,
no alternative_tile). Godot 4.5 requires:

  Byte 0-1 : uint16 = 0  (format version header, TILE_MAP_LAYER_DATA_FORMAT_0)
  Per cell (12 bytes, all uint16 LE):
    map_x | map_y | source_id | atlas_x | atlas_y | alternative_tile

This script reads the existing PackedByteArray from each scene, re-decodes it
using the old layout, then re-encodes using the correct Godot 4.5 layout.

Run from project root:
    python3 tools/fix_tilemap_encoding.py
"""

import os
import re
import struct

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE_DIR = os.path.join(PROJECT_ROOT, 'scenes', 'environments')
SCENES = ['Workshop.tscn', 'Florence.tscn', 'NaturalAreas.tscn']


def decode_old_bytes(byte_values: list[int]) -> list[tuple]:
    """
    Decode the previously generated (incorrect) PackedByteArray.
    Old format per cell — struct '<HHIHH' (12 bytes):
      map_x(u16) map_y(u16) source_id(u32) atlas_x(u16) atlas_y(u16)
    No header byte was present.
    """
    cells = []
    data = bytes(byte_values)
    for i in range(0, len(data), 12):
        chunk = data[i:i + 12]
        if len(chunk) < 12:
            break
        mx, my, src, ax, ay = struct.unpack('<HHIHH', chunk)
        cells.append((mx, my, src, ax, ay))
    return cells


def encode_new_bytes(cells: list[tuple]) -> bytes:
    """
    Encode cells using the correct Godot 4.5 format:
      2-byte header (uint16 = 0) then per cell 6 × uint16.
    """
    buf = bytearray(struct.pack('<H', 0))  # format-version header
    for mx, my, src, ax, ay in cells:
        buf += struct.pack('<HHHHHH',
                           mx & 0xFFFF,
                           my & 0xFFFF,
                           src & 0xFFFF,
                           ax & 0xFFFF,
                           ay & 0xFFFF,
                           0)             # alternative_tile = 0
    return bytes(buf)


def fix_scene(text: str) -> tuple[str, bool, int]:
    """Find and re-encode tile_map_data in a scene file."""
    pattern = re.compile(r'tile_map_data = PackedByteArray\(([^)]+)\)')
    match = pattern.search(text)
    if not match:
        return text, False, 0

    raw_ints = [int(v.strip()) for v in match.group(1).split(',')]
    cells = decode_old_bytes(raw_ints)
    new_bytes = encode_new_bytes(cells)
    new_literal = 'PackedByteArray(' + ', '.join(str(b) for b in new_bytes) + ')'

    updated = text[:match.start()] + f'tile_map_data = {new_literal}' + text[match.end():]
    return updated, True, len(cells)


def main():
    print('Re-encoding tile_map_data for Godot 4.5...')
    for filename in SCENES:
        path = os.path.join(SCENE_DIR, filename)
        with open(path) as f:
            original = f.read()

        updated, changed, cell_count = fix_scene(original)

        if not changed:
            print(f'  {filename}: no tile_map_data found – skipped')
            continue

        with open(path, 'w') as f:
            f.write(updated)
        print(f'  {filename}: re-encoded {cell_count} cells ✓')

    print('\nDone. Reload the project in Godot.')


if __name__ == '__main__':
    main()
