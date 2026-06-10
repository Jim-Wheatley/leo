# Step 3: Define the Strict JSON Contract for AI-Generated Tasks

## What is a JSON Contract?

Think of a **JSON contract** as a **blueprint or rule book** that the AI must follow when creating tasks. Just like a recipe tells a cook exactly what ingredients and amounts to use, a JSON contract tells the AI:
- What fields a task must have
- What type of data each field should be (text, number, etc.)
- What values are allowed (like a menu of options to choose from)

This is crucial because **the AI can make mistakes** or generate invalid data. The contract ensures that whatever the AI creates can actually work in your game without breaking it.

---

## Your Game's Configuration

**Last Updated**: February 16, 2026

### Confirmed Allow-Lists:
- [x] Task Types: SKILL_PRACTICE, CRAFTING, GATHERING, EXPLORATION, ARTWORK_CREATION, LEARNING
- [x] Difficulties: BEGINNER, APPRENTICE, JOURNEYMAN, EXPERT, MASTER
- [x] Objective Types: craft_item, create_artwork, gather_item, explore_location, skill_practice, learn_technique
- [x] Skills: crafting, painting, color_theory, sketching, portfolio_management, gathering
- [x] Item IDs: Found 15 total items (using 10 for Phase 1)
- [x] Locations: workshop, florence, natural_areas

### Phase 1 Item Set (Simplified):
**Pigments**: pigment_red, pigment_blue, pigment_yellow, pigment_green  
**Paints**: paint_red, paint_blue, paint_yellow, paint_green, paint_white, paint_black  
**Canvases**: canvas_small, canvas_medium  
**Raw Materials**: binding_agent, wood_frame, canvas_fabric

**Key Mechanic**: Players mix paints during the painting process. Orange, purple, and other secondary colors emerge naturally as players blend base colors on canvas—they are not separate inventory items. The four base pigments (including green from natural sources like verdigris and malachite) produce the corresponding base paints.
more canvas sizes (canvas_large)
- Add more base colors if needed
- Consider specialty pigments or material
- Add canvas_large
- Consider adding more raw materials or tools as game develops

### Notes:
Phase 1 focuses on basic crafting and painting tasks using a limited but complete item set. This ensures the AI doesn't request items that might not be fully implemented yet.

---

## Step 3A: Understanding Your Current Task Structure

Your game's tasks have these key parts (from `TaskData.gd`):

```
Task Structure:
├── Identification
│   ├── task_id (unique string identifier)
│   └── title (display name)
│
├── Classification
│   ├── task_type (what kind of task: CRAFTING, GATHERING, etc.)
│   └── difficulty (how hard: BEGINNER to MASTER)
│
├── Requirements (what player needs to start)
│   └── required_items (items needed in inventory)
│
├── Objectives (what the player must do)
│   └── List of objectives, each with:
│       ├── description (what to do)
│       ├── target (how many/much)
│       └── type (what kind of objective)
│
├── Rewards (what the player gets)
│   ├── skill_rewards (practice points for skills)
│   ├── item_rewards (items to give)
│   └── reputation_reward (relationship with master)
│
└── Dialogue (story text)
    ├── assignment_dialogue (when task is given)
    └── completion_dialogue (when task is done)
```

---

## Step 3B: Create the Allow-Lists (Menus of Options)

The AI needs to know what options it's allowed to pick from. Create these lists:

### 1. **Allowed Task Types**
From your `TaskData.gd`, the valid types are:
```
✓ SKILL_PRACTICE
✓ CRAFTING
✓ GATHERING
✓ EXPLORATION
✓ ARTWORK_CREATION
✓ LEARNING
```
**The AI can only choose one of these six.**

### 2. **Allowed Difficulty Levels**
From your `TaskData.gd`, the valid difficulties are:
```
✓ BEGINNER
✓ APPRENTICE
✓ JOURNEYMAN
✓ EXPERT
✓ MASTER
```
**The AI can only choose one of these five.**

### 3. **Allowed Objective Types**
Looking at your existing tasks, objectives have a `type` field:
```
✓ craft_item (player must craft something)
✓ create_artwork (player must create artwork)
✓ gather_item (player must collect materials)
✓ explore_location (player must visit a location)
✓ skill_practice (player must practice a skill)
✓ learn_technique (player must learn something)
```
**The AI can only choose one of these six.**

### 4. **Allowed Skill Names** (for rewards)
From your game, the valid skills appear to be:
```
✓ crafting
✓ painting
✓ color_theory
✓ sketching
✓ portfolio_management
✓ gathering
```

### 5. **Allowed Item IDs** (what the game can reward or require)

Your game uses these actual item IDs (found in `InventoryItem.gd` and `PlayerData.gd`):

**Pigments** (raw materials for paint):
```
✓ pigment_red
✓ pigment_blue
✓ pigment_yellow
✓ pigment_green
```
*(Green pigments occur naturally—sources include Verdigris and Malachite)*

**Paints** (used to create artwork):
```
✓ paint_red
✓ paint_blue
✓ paint_yellow
✓ paint_green
✓ paint_white
✓ paint_black
```

**Note**: Players mix paints during the painting process. Orange, purple, and other secondary colors are created dynamically when painting, not as separate items.
```
✓ canvas_small
✓ canvas_medium
✓ canvas_large
```

**Raw Materials** (for crafting):
```
✓ binding_agent (for making paint)
✓ wood_frame (for making canvas)
✓ canvas_fabric (for making canvas)
```

**Phase 1 Recommendation**: Start by allowing only a subset for simplicity:
- Pigments: pigment_red, pigment_blue, pigment_yellow, pigment_green
- Paints: paint_red, paint_blue, paint_yellow, paint_green, paint_white, paint_black
- Canvases: canvas_small, canvas_medium
- Raw materials: binding_agent, wood_frame, canvas_fabric

You can expand the canvas sizes once the system is working. Mixing of secondary colors happens naturally during painting.

### 6. **Allowed Locations** (for exploration tasks)
**Phase 1** — Allow only these three locations:
```
✓ workshop (where the player starts)
✓ florence (the city area)
✓ natural_areas (gathering location)
```

---

## Step 3C: Create the JSON Schema Specification

This is the **exact format** the AI must use when generating a task. Create a new file or documentation that shows the AI exactly what to produce.

Here's the contract in plain language:

```json
{
  "task_id": "unique_identifier_here",
  "title": "Short task name (5-10 words max)",
  "description": "Longer explanation (1-2 sentences)",
  "task_type": "must be one of: SKILL_PRACTICE, CRAFTING, GATHERING, EXPLORATION, ARTWORK_CREATION, LEARNING",
  "difficulty": "must be one of: BEGINNER, APPRENTICE, JOURNEYMAN, EXPERT, MASTER",
  
  "required_items": {
    "item_id": 1
  },
  
  "objectives": [
    {
      "id": "objective_1",
      "description": "What the player must do",
      "target": 1,
      "type": "must be one of: craft_item, create_artwork, gather_item, explore_location, skill_practice, learn_technique"
    }
  ],
  
  "skill_rewards": {
    "skill_name": 25
  },
  
  "item_rewards": [
    {
      "item_id": "must be one of the allowed items",
      "quantity": 1
    }
  ],
  
  "reputation_reward": 5,
  
  "assignment_dialogue": "Text the master says when giving the task",
  "completion_dialogue": "Text the master says when task is completed"
}
```

**Notes on Fields**:
- **required_items**: (Optional) Items the player must have in inventory to START the task. Format: `{"item_id": quantity}`. Can be empty `{}` if no items are required.
- **skill_rewards**: Experience points to give for each skill. Values between 10-100.
- **item_rewards**: Items to give upon completion. Max 3 items.
- **reputation_reward**: Relationship points with Master Artist (0-20).
- **All numbers must be integers** (no decimals).
- **All text must be valid JSON strings** (no line breaks, escape quotes with `\"`)

---

## Step 3D: Create Constraint Rules for the AI

These are **hard rules** that prevent bad data:

1. **task_id must be unique** — no duplicates with existing tasks
2. **difficulty must match task complexity**:
   - SKILL_PRACTICE tasks → BEGINNER or APPRENTICE only
   - CRAFTING/GATHERING → APPRENTICE to JOURNEYMAN
   - EXPLORATION → APPRENTICE to EXPERT
   - ARTWORK_CREATION → JOURNEYMAN to MASTER
3. **objectives must have at least 1, max 3**
4. **target numbers must be 1-5** (no huge numbers)
5. **skill_rewards values must be 10-100**
6. **item_rewards max 3 items**
7. **required_items max 5 items** (don't make tasks too expensive to start)
8. **required_items quantities must be 1-5** (reasonable amounts)
9. **reputation_reward max 20**
10. **Dialogue text must be 10-100 words** (not empty, not too long)
11. **No cHere's what a complete, valid AI-generated task looks like:

```json
{
  "task_id": "master_base_colors",
  "title": "Master the Base Colors",
  "description": "Learn to create the foundational colors from pigments. By mastering these base hues, you will have the palette needed for all future artworks.",
  "task_type": "CRAFTING",
  "difficulty": "APPRENTICE",
  
  "required_items": {
    "pigment_red": 1,
    "pigment_blue": 1,
    "pigment_yellow": 1,
    "pigment_green": 1,
    "binding_agent": 5
  },
  
  "objectives": [
    {
      "id": "create_red_paint",
      "description": "Create red paint from red pigment",
      "target": 1,
      "type": "craft_item"
    },
    {
      "id": "create_blue_paint",
      "description": "Create blue paint from blue pigment",
      "target": 1,
      "type": "craft_item"
    },
    {
      "id": "create_green_paint",
      "description": "Create green paint from green pigment",
      "target": 1,
      "type": "craft_item"
    }
  ],
  
  "skill_rewards": {
    "crafting": 40,
    "color_theory": 30
  },
  
  "item_rewards": [
    {
      "item_id": "paint_yellow",
      "quantity": 1
    }
  ],
  
  "reputation_reward": 10,
  
  "assignment_dialogue": "Ah, my young apprentice! You must first master the creation of our base colors—red, blue, yellow, and green. These four hues are the foundation of all art. Learn to combine pigments with binding agent to create paints of true clarity and brilliance. Green pigments, found in natural materials like verdigris and malachite, yield especially beautiful results. Once you have mastered these base colors, you will understand how all other colors arise from their combinations.",
  
  "completion_dialogue": "Excellent! You now possess the base colors needed for your artistic journey. Remember, when you paint, these colors can be mixed and blended to create the full spectrum. Your foundation is now strong. Let us continue your training."
}
```

**Why this example is valid**:
- ✓ All fields are present and properly formatted
- ✓ `task_type` is CRAFTING (appropriate for paint creation)
- ✓ `difficulty` is APPRENTICE (learning basic colors)
- ✓ `required_items` uses real base pigments (including green) and binding agent
- ✓ 3 objectives (creating base colors from pigments)
- ✓ Objective targets are small (1 each)
- ✓ Skill rewards are in the 10-100 range
- ✓ Item reward is a base paint color
- ✓ Reputation reward is within 0-20
- ✓ Dialogue mentions green pigments from natural sources (verdigris, malachite)
- ✓ Dialogue explains that mixing happens naturally during paintiturally during painting, not as a separate task
- ✓ Dialogue is neither too short nor too long
- ✓ No invalid characters or formatting issues

---

## Step 3F: Summary Table

Print this out or screenshot it — you'll give this to the AI as part of the prompt:

| Field | Type | Allowed Values |
|-------|------|---|
| task_type | string | SKILL_PRACTICE, CRAFTING, GATHERING, EXPLORATION, ARTWORK_CREATION, LEARNING |
| difficulty | string | BEGINNER, APPRENTICE, JOURNEYMAN, EXPERT, MASTER |
| objective.type | string | craft_item, create_artwork, gather_item, explore_location, skill_practice, learn_technique |
| skill name | string | crafting, painting, color_theory, sketching, portfolio_management, gathering |
| item_id (Phase 1) | string | paint_red, paint_blue, paint_yellow, paint_green, paint_white, paint_black, pigment_red, pigment_blue, pigment_yellow, pigment_green, canvas_small, canvas_medium, binding_agent, wood_frame, canvas_fabric |
| location | string | workshop, florence, natural_areas |

**Phase 1 Item Categories**:
- **Pigments**: pigment_red, pigment_blue, pigment_yellow, pigment_green (green from natural sources like verdigris and malachite)
- **Paints**: paint_red, paint_blue, paint_yellow, paint_green, paint_white, paint_black
- **Canvases**: canvas_small, canvas_medium
- **Raw Materials**: binding_agent, wood_frame, canvas_fabric

---

## What You've Accomplished ✓

✅ **Understand the task structure** — You know what fields exist and how they work  
✅ **Created allow-lists** — Limited choices prevent bad AI output  
✅ **Defined the JSON format** — The AI knows exactly what shape to produce  
✅ **Set constraints** — Rules that prevent broken data from entering your game  
✅ **Found real item IDs** — All 15 items from your codebase identified  
✅ **Added required_items** — Tasks can now require items to start  
✅ **Created example output** — A complete valid JSON task for reference  

## Next Steps

- **Step 4**: You'll use this contract to instruct the AI in the prompt
- **Step 5**: You'll validate incoming JSON against these rules before accepting it
- **Step 6**: You'll wire this into the Master Artist NPC

