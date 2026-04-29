# Design Document

## Overview

The Artist Apprentice RPG is a simulation game built in Godot Engine that combines skill-based progression, resource management, and exploration mechanics. The game features a 3/4 top-down perspective and takes place in Renaissance Florence, where players learn artistic techniques through hands-on workshop activities and city exploration.

The core gameplay loop involves: receiving tasks from the master artist → gathering materials from natural sources → crafting supplies in the workshop → completing artistic projects → improving skills → unlocking new areas and techniques.

## Architecture

### Core Systems Architecture

The game will be structured using Godot's scene-based architecture with the following main systems:

- **Game Manager**: Central singleton managing game state, save/load, and scene transitions
- **Player Controller**: Handles character movement, interactions, and input processing
- **Skill System**: Manages skill progression, experience tracking, and ability unlocks
- **Inventory System**: Handles item storage, crafting materials, and portfolio management
- **Quest/Task System**: Manages assignments from the master artist and progress tracking
- **Interaction System**: Unified system for handling all interactive objects and NPCs
- **UI Manager**: Manages all user interface elements and menus

### Scene Structure

```
Main.tscn (Game Manager)
├── Workshop.tscn (Indoor environment)
│   ├── WorkstationNodes (Paint mixing, canvas making, etc.)
│   ├── MasterArtist.tscn (NPC with dialogue system)
│   └── InteractableObjects.tscn
├── Florence.tscn (City environment)
│   ├── Buildings.tscn (Sketchable architecture)
│   ├── NPCs.tscn (Citizens to sketch)
│   └── SketchPoints.tscn (Designated sketching locations)
├── NaturalAreas.tscn (Gathering locations)
│   ├── ClayDeposits.tscn
│   ├── MineralVeins.tscn
│   └── HarvestableNodes.tscn
└── UI/
    ├── HUD.tscn
    ├── Inventory.tscn
    ├── Portfolio.tscn
    └── SkillTree.tscn
```

## Components and Interfaces

### Player Character System

**PlayerController.gd**
- Handles 2D movement using Godot's CharacterBody2D with 8-directional movement
- Manages interaction detection through Area2D collision detection
- Integrates with 2D camera for smooth following and scene framing
- Processes input for movement, interaction, and UI toggles

**SkillManager.gd**
- Tracks skill levels: Painting, Sketching, Color Theory, Crafting, Gathering, Observation
- Calculates experience gains based on activity difficulty and success
- Manages skill-based unlock conditions for new content
- Provides skill check functionality for advanced techniques

### Crafting and Workshop System

**WorkstationBase.gd** (Base class for all workshop activities)
- Defines common interface for all crafting stations
- Handles skill requirements and success calculations
- Manages resource consumption and output generation
- Provides feedback for skill progression

**PaintCreationStation.gd** (Extends WorkstationBase)
- Implements simple material-based paint creation system
- Allows combining pigments with binding agents to create paint colors
- Generates paint items when required materials are available
- Provides straightforward crafting interface without complex mechanics

**CanvasMakingStation.gd** (Extends WorkstationBase)
- Implements simple canvas creation with size selection
- Allows choosing canvas dimensions based on available materials
- Generates canvas items when materials (wood, fabric) are available
- Provides simple selection interface for different canvas sizes

**ArtworkCreationStation.gd** (Extends WorkstationBase)
- Handles artwork creation using available materials and inspiration
- Automatically determines artwork quality based on player's artistic skill level
- Consumes paint, canvas, and inspiration (sketches) to create finished artworks
- Adds completed artworks to player's portfolio with appropriate quality ratings

### Exploration and Gathering System

**GatheringNode.gd** (Base class for harvestable resources)
- Manages resource availability and regeneration timers
- Implements skill-based gathering success rates
- Handles rare material discovery mechanics
- Provides visual feedback for resource quality and quantity

**SketchingSystem.gd**
- Manages different sketching interfaces for various subject types
- Implements observation-based mechanics for accuracy scoring
- Tracks sketch quality improvement over time
- Integrates with portfolio system for progress visualization

### NPC and Dialogue System

**MasterArtist.gd**
- Manages task assignment based on player skill progression
- Implements dialogue trees using Godot's resource system
- Provides teaching interactions that boost specific skills
- Tracks relationship progression and story advancement

**DialogueManager.gd**
- Handles dialogue display and player choice processing
- Manages dialogue state and branching conversations
- Integrates with quest system for task-related dialogue
- Supports localization for future expansion

## Data Models

### Player Data Structure

```gdscript
class_name PlayerData extends Resource

@export var skills: Dictionary = {
    "painting": 0,
    "sketching": 0,
    "color_theory": 0,
    "crafting": 0,
    "gathering": 0,
    "observation": 0
}

@export var inventory: Array[InventoryItem] = []
@export var portfolio: Array[ArtworkData] = []
@export var completed_tasks: Array[String] = []
@export var discovered_locations: Array[String] = []
@export var master_relationship: int = 0
```

### Item System

```gdscript
class_name InventoryItem extends Resource

@export var item_id: String
@export var display_name: String
@export var description: String
@export var item_type: ItemType
@export var quality: float = 1.0
@export var stack_size: int = 1
@export var current_stack: int = 1

enum ItemType {
    PIGMENT,
    PAINT,
    CANVAS,
    TOOL,
    RAW_MATERIAL,
    ARTWORK
}
```

### Artwork and Portfolio System

```gdscript
class_name ArtworkData extends Resource

@export var artwork_id: String
@export var title: String
@export var artwork_type: ArtworkType
@export var quality_score: float
@export var creation_date: String
@export var materials_used: Array[String]
@export var skill_level_at_creation: Dictionary
@export var thumbnail_texture: Texture2D

enum ArtworkType {
    SKETCH,
    PAINTING,
    STUDY,
    MASTERWORK
}
```

## Error Handling

### Input Validation
- Validate all player inputs for crafting recipes and material combinations
- Implement bounds checking for skill values and experience calculations
- Handle edge cases in resource gathering (empty nodes, insufficient tools)

### Save System Integrity
- Implement checksum validation for save file integrity
- Provide fallback mechanisms for corrupted save data
- Handle version compatibility for future game updates

### Performance Considerations
- Implement object pooling for frequently spawned items (sketches, materials)
- Use Godot's built-in optimization features (culling, LOD systems)
- Manage memory usage for large portfolio collections

## Testing Strategy

### Unit Testing Approach
- Test skill calculation algorithms with various input scenarios
- Validate crafting recipe logic and material consumption
- Test save/load functionality with edge cases and corrupted data
- Verify UI responsiveness across different screen resolutions

### Integration Testing
- Test complete gameplay loops from task assignment to completion
- Validate cross-system interactions (skills affecting crafting outcomes)
- Test scene transitions and data persistence between areas
- Verify NPC dialogue integration with quest progression

### Playtesting Focus Areas
- Balance testing for skill progression rates and material requirements
- User experience testing for crafting mini-games and sketching interfaces
- Exploration flow testing for natural material gathering loops
- Tutorial effectiveness for new player onboarding

### Performance Testing
- Frame rate stability during complex crafting activities
- Memory usage monitoring during extended play sessions
- Load time optimization for scene transitions
- UI responsiveness under various system loads

## Technical Implementation Notes

### Godot-Specific Considerations
- Utilize Godot's signal system for loose coupling between game systems
- Implement custom resources for save data and item definitions
- Use Godot's built-in tweening system for smooth UI animations
- Leverage the scene instancing system for modular workshop stations

### 2D Pixel Art with 3/4 Top-Down Perspective
- Create pixel art sprites designed with 3/4 perspective angles for characters and objects
- Design environment tiles and backgrounds that maintain consistent 3/4 perspective
- Implement depth sorting for proper visual layering using Godot's Y-sort functionality
- Use 2D camera with smooth following for scene navigation and transitions

### Renaissance Florence Setting
- Research historical accuracy for building architecture and city layout
- Implement period-appropriate color palettes and artistic techniques
- Design authentic crafting recipes based on historical art methods
- Create educational content about Renaissance art practices