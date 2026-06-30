#!/usr/bin/env python3
"""
Generate placeholder 24×24 forward-facing character sprites for the 6 main characters.
GBA-style pixel art, RGBA PNG with transparent background.

Characters:
  player    — young apprentice artist
  aldric    — Master Artist, older, distinguished
  casimir   — Lord/nobleman patron, richly dressed
  fenwick   — Merchant/supplier, practical, weathered
  serafine  — Guild inspector, formal uniform
  mira      — Rival apprentice, noble but practical

Output:
  assets/sprites/characters/<name>.png   — one 24×24 sprite per character
  assets/sprites/characters/preview.png  — all 6 side-by-side for reference (144×32)

Run from project root:
    python3 tools/generate_character_sprites.py
"""

import os
from PIL import Image, ImageDraw

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(PROJECT_ROOT, 'assets', 'sprites', 'characters')

W, H = 24, 24
TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (20, 12, 8, 255)


# ── Pixel-level drawing helpers ───────────────────────────────────────────────

def make_sprite():
    return Image.new('RGBA', (W, H), TRANSPARENT)


def px(draw, x, y, color):
    if 0 <= x < W and 0 <= y < H:
        draw.point((x, y), fill=color)


def hline(draw, y, x1, x2, color):
    for x in range(x1, x2 + 1):
        px(draw, x, y, color)


def vline(draw, x, y1, y2, color):
    for y in range(y1, y2 + 1):
        px(draw, x, y, color)


def rect(draw, x1, y1, x2, y2, color):
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            px(draw, x, y, color)


def outline_rect(draw, x1, y1, x2, y2):
    """Draw a 1-pixel outline around a rectangle."""
    hline(draw, y1 - 1, x1, x2, OUTLINE)
    hline(draw, y2 + 1, x1, x2, OUTLINE)
    vline(draw, x1 - 1, y1, y2, OUTLINE)
    vline(draw, x2 + 1, y1, y2, OUTLINE)


# ── Base humanoid draw function ───────────────────────────────────────────────
#
# 24×24 forward-facing anatomy:
#   y  0     : top padding
#   y  1- 2  : hair top
#   y  3-10  : head (8px tall, 10px wide centred at x=12)
#   y 11     : neck
#   y 12-17  : torso + arms (12px wide body + 2px arms each side)
#   y 18     : belt / waist
#   y 19-21  : legs (split into two 4px-wide columns)
#   y 22-23  : feet/shoes

def draw_humanoid(
        img,
        skin,           # face/neck/hand colour
        hair,           # hair colour
        torso,          # shirt/tunic/jacket colour
        belt,           # belt/waist colour
        legs,           # trouser/skirt colour
        shoes,          # shoe/boot colour
        hair_style='short',   # 'short' | 'long' | 'hat' | 'hood' | 'noble'
        hat_color=None,
        beard=False,
        beard_color=None,
        accessory=None,       # 'bag' | 'badge' | 'collar' | 'trim'
        accessory_color=None,
        trim_color=None,      # optional torso trim
):
    d = ImageDraw.Draw(img)

    # ── Hair / head covering ──────────────────────────────────────────────────
    if hair_style == 'short':
        rect(d, 8, 1, 15, 3, hair)          # top of head
        px(d, 7, 3, hair); px(d, 16, 3, hair)  # slight width at ears
    elif hair_style == 'long':
        rect(d, 8, 1, 15, 3, hair)
        vline(d, 7, 3, 9, hair)             # left long fall
        vline(d, 16, 3, 9, hair)            # right long fall
    elif hair_style == 'hat':
        rect(d, 7, 0, 16, 3, hat_color)     # brim wider
        rect(d, 9, 1, 14, 3, hat_color)     # crown extends up
        hline(d, 3, 6, 17, hat_color)       # brim overhang
        # hair peeking under brim
        px(d, 8, 3, hair); px(d, 15, 3, hair)
    elif hair_style == 'noble':             # plumed hat / noble cap
        rect(d, 7, 1, 16, 3, hat_color)
        rect(d, 10, 0, 13, 2, hat_color)    # crown
        # feather plume (white/light)
        plume = (240, 235, 220, 255)
        vline(d, 16, 0, 3, plume)
        px(d, 17, 1, plume)
        hline(d, 3, 6, 17, hat_color)       # cap brim
    elif hair_style == 'hood':
        rect(d, 7, 1, 16, 4, hair)
        vline(d, 6, 2, 11, hair)            # hood sides frame face
        vline(d, 17, 2, 11, hair)

    # ── Head / face ───────────────────────────────────────────────────────────
    rect(d, 8, 3, 15, 10, skin)

    # Outline head
    hline(d, 2, 8, 15, OUTLINE)
    hline(d, 11, 8, 15, OUTLINE)
    vline(d, 7, 3, 10, OUTLINE)
    vline(d, 16, 3, 10, OUTLINE)

    # Eyes — two 2×1 dark pixels at y=6
    px(d, 9, 6, OUTLINE); px(d, 10, 6, OUTLINE)
    px(d, 13, 6, OUTLINE); px(d, 14, 6, OUTLINE)
    # Eye whites
    px(d, 9, 6, (230, 220, 210, 255)); px(d, 13, 6, (230, 220, 210, 255))
    # Pupils
    px(d, 10, 6, OUTLINE); px(d, 14, 6, OUTLINE)

    # Mouth
    px(d, 11, 9, OUTLINE); px(d, 12, 9, OUTLINE)

    # Beard (optional)
    if beard:
        bc = beard_color or hair
        rect(d, 9, 9, 14, 11, bc)

    # ── Neck ─────────────────────────────────────────────────────────────────
    rect(d, 11, 11, 12, 12, skin)

    # ── Torso ────────────────────────────────────────────────────────────────
    rect(d, 8, 12, 15, 17, torso)

    # Optional trim stripe down centre
    if trim_color:
        vline(d, 11, 12, 17, trim_color)
        vline(d, 12, 12, 17, trim_color)

    # Arms
    rect(d, 6, 12, 7, 16, torso)    # left arm
    rect(d, 16, 12, 17, 16, torso)  # right arm
    # Hands
    px(d, 6, 17, skin); px(d, 17, 17, skin)

    # Accessory details
    if accessory == 'badge':
        c = accessory_color or (200, 175, 50, 255)
        rect(d, 13, 13, 14, 14, c)     # small guild badge on chest
    elif accessory == 'collar':
        c = accessory_color or (230, 225, 215, 255)
        hline(d, 12, 9, 14, c)         # white collar
    elif accessory == 'bag':
        c = accessory_color or (110, 85, 50, 255)
        rect(d, 5, 13, 6, 16, c)       # satchel on left side
        px(d, 5, 12, OUTLINE)
    elif accessory == 'trim':
        c = accessory_color or (180, 150, 40, 255)
        hline(d, 12, 8, 15, c)         # gold trim at collar
        hline(d, 17, 8, 15, c)         # gold trim at hem

    # Torso outline
    hline(d, 11, 8, 15, OUTLINE)
    hline(d, 18, 8, 15, OUTLINE)
    vline(d, 7, 12, 17, OUTLINE)
    vline(d, 18, 12, 17, OUTLINE)

    # ── Belt ─────────────────────────────────────────────────────────────────
    hline(d, 18, 8, 15, belt)

    # ── Legs ─────────────────────────────────────────────────────────────────
    rect(d, 8, 19, 11, 21, legs)     # left leg
    rect(d, 12, 19, 15, 21, legs)    # right leg
    # Inner gap/shadow
    px(d, 11, 19, OUTLINE); px(d, 12, 19, OUTLINE)

    # ── Shoes ────────────────────────────────────────────────────────────────
    rect(d, 8, 22, 11, 23, shoes)
    rect(d, 12, 22, 15, 23, shoes)
    # Shoe outline
    for sx, ex in [(8, 11), (12, 15)]:
        hline(d, 24 if H > 23 else 23, sx, ex, OUTLINE)  # clipped bottom
        px(d, sx - 1, 22, OUTLINE); px(d, ex + 1, 22, OUTLINE)

    # Overall dark pixel corners for cleanliness
    for corner in [(7, 2), (16, 2), (7, 11), (16, 11)]:
        px(d, corner[0], corner[1], OUTLINE)


# ── Character definitions ─────────────────────────────────────────────────────

CHARACTERS = {
    'player': dict(
        label='Player',
        skin=(200, 158, 118, 255),
        hair=(110, 68, 30, 255),
        torso=(165, 125, 75, 255),       # warm ochre tunic — paint-stained
        belt=(80, 55, 25, 255),
        legs=(90, 60, 30, 255),
        shoes=(55, 35, 18, 255),
        hair_style='short',
        accessory='bag',                 # paint satchel
        accessory_color=(130, 100, 55, 255),
    ),
    'aldric': dict(
        label='Master Aldric',
        skin=(190, 148, 110, 255),
        hair=(185, 178, 168, 255),       # grey-white — older master
        torso=(110, 45, 45, 255),        # deep burgundy master's robes
        belt=(60, 30, 20, 255),
        legs=(75, 35, 35, 255),
        shoes=(40, 25, 15, 255),
        hair_style='short',
        beard=True,
        beard_color=(175, 168, 158, 255),
        accessory='badge',               # guild master badge
        accessory_color=(200, 170, 50, 255),
    ),
    'casimir': dict(
        label='Lord Casimir',
        skin=(205, 168, 128, 255),
        hair=(65, 50, 35, 255),          # dark with hints of grey
        torso=(45, 65, 145, 255),        # rich noble blue
        belt=(40, 30, 10, 255),
        legs=(30, 45, 110, 255),
        shoes=(35, 25, 10, 255),
        hair_style='noble',
        hat_color=(35, 50, 120, 255),
        accessory='trim',                # gold trim
        accessory_color=(210, 175, 50, 255),
        trim_color=(190, 155, 40, 255),
    ),
    'fenwick': dict(
        label='Brother Fenwick',
        skin=(185, 138, 98, 255),        # weathered, reddish
        hair=(130, 80, 35, 255),
        torso=(100, 110, 60, 255),       # practical olive merchant coat
        belt=(70, 55, 25, 255),
        legs=(65, 70, 35, 255),
        shoes=(50, 38, 20, 255),
        hair_style='hat',
        hat_color=(80, 60, 30, 255),
        accessory='bag',                 # merchant's satchel (carries supplies)
        accessory_color=(90, 70, 35, 255),
    ),
    'serafine': dict(
        label='Serafine',
        skin=(180, 142, 108, 255),
        hair=(45, 32, 22, 255),          # dark, pulled back
        torso=(65, 85, 105, 255),        # formal guild blue-grey
        belt=(45, 55, 70, 255),
        legs=(50, 65, 80, 255),
        shoes=(35, 40, 50, 255),
        hair_style='short',
        accessory='badge',               # official guild inspector badge
        accessory_color=(210, 180, 55, 255),
        accessory_color_extra=(200, 60, 50, 255),  # unused but for reference
    ),
    'mira': dict(
        label='Mira',
        skin=(205, 168, 132, 255),
        hair=(58, 38, 25, 255),          # dark, noble
        torso=(145, 82, 105, 255),       # warm wine/mauve — noble but practical
        belt=(90, 50, 65, 255),
        legs=(110, 60, 80, 255),
        shoes=(60, 38, 30, 255),
        hair_style='long',               # longer hair suggesting noble background
        accessory='collar',
        accessory_color=(235, 228, 218, 255),
    ),
}


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print('Generating character sprites...')

    sprites = {}
    order = ['player', 'aldric', 'casimir', 'fenwick', 'serafine', 'mira']

    for key in order:
        cfg = CHARACTERS[key]
        img = make_sprite()

        # Pull only draw_humanoid kwargs
        draw_kwargs = {k: v for k, v in cfg.items()
                       if k not in ('label', 'accessory_color_extra')}
        draw_humanoid(img, **draw_kwargs)

        out_path = os.path.join(OUT_DIR, f'{key}.png')
        img.save(out_path)
        sprites[key] = img
        print(f'  {key}.png  ({cfg["label"]})')

    # ── Preview sheet: all 6 side-by-side with 4px gap and label row ─────────
    GAP = 4
    LABEL_H = 8
    preview_w = len(order) * W + (len(order) - 1) * GAP
    preview_h = H + LABEL_H + 2
    preview = Image.new('RGBA', (preview_w, preview_h), (40, 35, 30, 255))
    pd = ImageDraw.Draw(preview)

    for i, key in enumerate(order):
        x = i * (W + GAP)
        preview.alpha_composite(sprites[key], (x, 0))
        # Tiny label (just index dot — no font dependency)
        pd.rectangle([x + W // 2 - 1, H + 2, x + W // 2 + 1, H + 4],
                     fill=(200, 190, 170, 255))

    preview_path = os.path.join(OUT_DIR, 'preview.png')
    preview.save(preview_path)
    print(f'\n  preview.png  (all 6 side-by-side)')

    print('\nCharacter order in preview (left → right):')
    for i, key in enumerate(order):
        print(f'  {i+1}. {key:10s} — {CHARACTERS[key]["label"]}')

    print(f'\nSprites saved to: assets/sprites/characters/')
    print('Replace any .png with your own 24×24 art — same filename, same directory.')


if __name__ == '__main__':
    main()
