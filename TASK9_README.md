# Task 9: Natural Material Gathering System

## Overview
This task implements a comprehensive natural material gathering system that allows players to collect clay, minerals, and rare pigments from natural sources outside Florence. The system includes resource depletion, regeneration mechanics, and skill-based gathering.

## Implementation Details

### Core Components

#### GatheringNode (Base Class)
- **Location**: `scripts/systems/GatheringNode.gd`
- **Purpose**: Base class for all harvestable resource nodes
- **Features**:
  - Resource availability and regeneration timers
  - Skill-based gathering success rates
  - Rare material discovery mechanics
  - Visual feedback for resource quality and quantity
  - Save/load functionality for persistent resource states

#### ClayDeposit
- **Location**: `scripts/systems/ClayDeposit.gd`
- **Purpose**: Specialized gathering node for clay materials
- **Features**:
  - No skill requirement (accessible to beginners)
  - 15 max resources with 4-minute regeneration
  - 15% chance for rare ochre materials
  - Provides basic pigment materials

#### MineralVein
- **Location**: `scripts/systems/MineralVein.gd`
- **Purpose**: Specialized gathering node for mineral ores
- **Features**:
  - Requires Gathering Skill level 2
  - 8 max resources with 10-minute regeneration
  - 25% chance for precious pigments (lapis lazuli, cinnabar, etc.)
  - Higher skill experience gain

### Scene Structure

#### NaturalAreas Scene
- **Location**: `scenes/environments/NaturalAreas.tscn`
- **Purpose**: Main gathering environment outside Florence
- **Contains**:
  - Multiple clay deposits scattered around the area
  - Mineral veins in strategic locations
  - Exit point back to Florence
  - Player spawn point

#### NaturalAreas Script
- **Location**: `scripts/environments/NaturalAreas.gd`
- **Purpose**: Manages the natural areas scene
- **Features**:
  - Initializes all gathering nodes
  - Handles scene transitions
  - Manages save/load for resource states
  - Provides feedback for gathering activities

### Player Integration

#### PlayerController Updates
- **Location**: `scripts/player/PlayerController.gd`
- **New Features**:
  - Interaction target management
  - Gathering interaction handling
  - Support for gathering node detection

#### GameManager Updates
- **Location**: `scripts/singletons/GameManager.gd`
- **New Features**:
  - Natural areas scene registration
  - Inventory management for gathered materials
  - Item type definitions for new materials
  - Display names and descriptions for all materials

### Material Types

#### Basic Materials
- **Clay**: Common material for basic pigment creation
- **Mineral Ore**: Raw ore that can be processed into pigments

#### Rare Materials
- **Rare Ochre**: High-quality ochre with rich color properties
- **Red Ochre**: Natural red pigment from iron-rich clay
- **Yellow Ochre**: Natural yellow pigment from iron-rich clay
- **Lapis Lazuli**: Precious blue stone for ultramarine
- **Cinnabar**: Rare red mineral for vermillion pigment
- **Malachite**: Green copper mineral for vibrant green pigments
- **Azurite**: Blue copper mineral for deep blue pigments

## Gameplay Mechanics

### Resource Depletion and Regeneration
- Resources deplete as players gather from them
- Depleted nodes show visual feedback (grayed out appearance)
- Automatic regeneration after specified time periods
- Different regeneration times for different resource types

### Skill Integration
- Gathering skill affects success rates and yield
- Higher skill levels provide bonus materials
- Skill experience gained from successful gathering
- Some resources require minimum skill levels

### Rare Material Discovery
- Chance-based system for finding rare materials
- Higher-tier resources have better rare material chances
- Rare materials unlock unique pigment colors
- Visual and audio feedback for rare discoveries

## Controls
- **E or Space**: Interact with gathering nodes and transition points
- **WASD or Arrow Keys**: Move around the natural areas
- **I**: Open/Close inventory to view gathered materials (works in all scenes)
- **P**: Open/Close portfolio to view artworks (works in all scenes)

## How to Access Natural Areas

### From Florence:
1. Start in the Workshop and exit to Florence (Press E at the exit door)
2. In Florence, move to the **very bottom** of the city (below the street)
3. Look for the green "🌿 To Natural Areas" label at the south gate
4. Press E when prompted to travel to Natural Areas

### From Natural Areas:
1. Move to the "To Florence" exit point (left side of the natural areas)
2. Press E to return to Florence

### Navigation Flow:
Workshop ↔ Florence ↔ Natural Areas

## Testing

### Test Scene
- **Location**: `scenes/tests/Task9_GatheringTest.tscn`
- **Script**: `scripts/tests/Task9_GatheringTest.gd`
- **Purpose**: Comprehensive testing of all gathering mechanics

### Test Coverage
1. **Clay Deposit Functionality**: Tests basic clay gathering
2. **Mineral Vein Functionality**: Tests skill-gated mineral gathering
3. **Resource Depletion**: Tests depletion and regeneration mechanics
4. **Skill Requirements**: Validates skill-based access control
5. **Rare Materials**: Tests rare material discovery system

### Running Tests
1. Open the test scene: `scenes/tests/Task9_GatheringTest.tscn`
2. Run the scene to see automated test results
3. Press Enter to re-run tests
4. Check console output for detailed test results

## Integration with Existing Systems

### Skill System
- Integrates with SkillManager for gathering skill tracking
- Provides experience points for skill progression
- Respects skill requirements for advanced resources

### Inventory System
- Adds gathered materials to player inventory
- Supports item stacking and organization
- Provides proper item metadata (names, descriptions, types)

### Save System
- Persists resource node states across game sessions
- Maintains regeneration timers
- Preserves gathered material quantities

## Future Enhancements

### Potential Improvements
1. **Visual Polish**: Replace placeholder sprites with detailed pixel art
2. **Audio Feedback**: Add sound effects for gathering and rare discoveries
3. **Seasonal Variations**: Different materials available in different seasons
4. **Tool Requirements**: Require specific tools for certain materials
5. **Environmental Hazards**: Add challenges to gathering activities

### Expansion Opportunities
1. **New Resource Types**: Add wood, herbs, and other natural materials
2. **Processing Stations**: Add refinement mechanics for raw materials
3. **Trading System**: Allow trading of rare materials with NPCs
4. **Exploration Rewards**: Hidden resource nodes in secret locations

## Requirements Fulfilled

This implementation satisfies all requirements from Requirement 3:

- ✅ **3.1**: Natural areas with harvestable material nodes
- ✅ **3.2**: Clay deposits for direct pigment gathering
- ✅ **3.3**: Inventory integration and skill progression
- ✅ **3.4**: Resource depletion and regeneration mechanics
- ✅ **3.5**: Rare material discovery system

The natural material gathering system provides a solid foundation for resource collection that integrates seamlessly with the existing crafting and skill systems.