# Tilemap Editing Cheat Sheet
**Godot 4.5 — TileMapLayer**

---

## Opening the tile editor

1. Open an environment scene (`Workshop.tscn`, `Florence.tscn`, `NaturalAreas.tscn`)
2. In the **Scene panel** (top-left), click the **TileMap** node
3. A **TileMap** panel appears at the **bottom** of the editor — this is the tile editor
4. If you don't see the panel, look for the **TileMap** tab at the very bottom of the screen and click it

---

## Tile editor layout

```
[ Toolbar: tool buttons ]  [ Zoom ]
────────────────────────────────────
  Left panel          │  Viewport
  (tile palette)      │  (paint here)
```

The **left panel** shows your tileset. Click a tile there to select it, then click/drag in the **viewport** to place it.

---

## The toolbar buttons (left to right)

| Icon | Shortcut | What it does |
|------|----------|--------------|
| Select | `S` | Select/move existing tiles |
| Paint | `D` | Paint individual tiles |
| Line | `L` | Draw a straight line of tiles |
| Rect | `R` | Fill a rectangle |
| Bucket Fill | `F` | Flood fill a connected area |
| Picker | `P` | Pick a tile from the map (eyedropper) |
| Eraser | `E` | Erase tiles (hold while using other tools too) |

---

## Basic workflow

### Painting tiles
1. Select the **TileMap** node in the Scene panel
2. Click **Paint** tool (`D`) in the toolbar
3. Click a tile in the **left palette** to select it
4. Click or drag in the **viewport** to place tiles

### Erasing tiles
- Hold **Right-click** while dragging — erases as you drag
- Or switch to the **Eraser** tool (`E`), then click/drag

### Picking a tile already on the map
- Press `P` (Picker) and click any placed tile — it becomes your active brush
- Or hold **Ctrl** while using the Paint tool

### Filling a region
- Use **Rect** (`R`): click and drag to define a rectangle, release to fill it
- Use **Bucket Fill** (`F`): click any tile to flood fill the same-type area

### Undo / Redo
- `Ctrl+Z` — undo last paint action
- `Ctrl+Shift+Z` — redo

---

## Navigating the viewport while editing

| Action | How |
|--------|-----|
| Pan | `Middle-click` drag, or `Space` + drag |
| Zoom in/out | `Scroll wheel` or `+` / `-` |
| Zoom to fit | `Numpad 0` or View → Frame All |

---

## Selecting multiple tiles as a brush

1. In the **left palette**, hold **Shift** or **Ctrl** and click several tiles
2. They become a **multi-tile brush** — painting places all of them in that pattern
3. Useful for painting a wall segment or road section in one stroke

---

## Our tileset layout (24×24, 8 cols × 3 rows)

### Workshop (`workshop_tiles.png`)

|   | Col 0 | Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 | Col 7 |
|---|-------|-------|-------|-------|-------|-------|-------|-------|
| **Row 0** | Wood floor | Stone floor | Dark floor | Rug centre | Doorstep | Shadow | Side shadow | Stone floor alt |
| **Row 1** | Stone wall | Plaster wall | Wall+window | Wall arch | Wall torch | Wall shelf | Wall corner | Wall top cap |
| **Row 2** | Paint station | Canvas station | Artwork station | Workbench | Storage chest | Fireplace | Pillar | Shadow |

### Florence (`florence_tiles.png`)

|   | Col 0 | Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 | Col 7 |
|---|-------|-------|-------|-------|-------|-------|-------|-------|
| **Row 0** | Cobblestone | Cobble worn | Piazza stone | Dirt/earth | Steps | Street gutter | Bridge stone | (empty) |
| **Row 1** | Plaster facade | Terracotta facade | Arched window | Arched doorway | Roof tile | Roof edge | Column | Wall coping |
| **Row 2** | Garden grass | Fountain water | Fountain stone | Market awning | Well top | Tree canopy | Flower bed | (empty) |

### Natural Areas (`nature_tiles.png`)

|   | Col 0 | Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 | Col 7 |
|---|-------|-------|-------|-------|-------|-------|-------|-------|
| **Row 0** | Grass light | Grass dark | Dirt path | Rocky ground | Clay deposit | Mineral vein | Sandy bank | Shallow water |
| **Row 1** | Tree canopy | Tree trunk | Bush | Tall grass | Wildflowers | Fallen log | Mushrooms | Tree shadow |
| **Row 2** | Large rock | Rock cluster | Cave entrance | Cave floor | Deep water | Water edge | Cliff face | Cliff top |

---

## Replacing placeholder tiles with real art

When you have a finished pixel art tile sheet:

1. Replace the PNG in `assets/sprites/tilesets/` (keep same filename, same grid size)
2. Godot auto-reimports — **no tilemap reconfiguration needed**
3. All painted tile placements stay exactly where they are

To regenerate placeholder tiles from scratch:
```
python3 tools/generate_tilesets.py
```

To re-inject default layouts into scene files (wipes manual edits!):
```
python3 tools/inject_tilemaps.py
```
