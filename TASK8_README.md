# Task 8: Sketching System for City Exploration

## Overview
Task 8 implements a comprehensive sketching system that allows players to sketch various subjects throughout Florence, improving their artistic skills and building their portfolio through observation and practice.

## Features Implemented

### 🎨 Core Sketching System
- **SketchingSystem class** with support for different subject types
- **Multi-phase sketching process**: Observation → Sketching → Completion
- **Subject type support**: Buildings, People, Objects, Scenes
- **Quality calculation** based on skills, observation time, and practice
- **Experience rewards** for completed sketches

### 🖼️ Sketching UI
- **Progress tracking** with visual progress bar
- **Phase indicators** (Observing, Sketching, Completing)
- **Subject information** display with type and name
- **Cancellation support** with ESC key or button
- **Completion feedback** with quality and portfolio integration

### 🏛️ Sketchable Subjects in Florence
- **Cathedral**: High-difficulty building sketch (Gothic Renaissance architecture)
- **Market Square**: Medium-difficulty scene sketch (bustling commerce)
- **Street Scene**: Low-difficulty scene sketch (typical Renaissance street)
- **Visual highlighting** when subjects are approachable
- **Metadata-driven** subject configuration

### 📈 Skill Integration
- **Sketching skill progression** through practice
- **Observation skill development** through careful study
- **Quality improvement** with higher skill levels
- **Faster sketching** as skills increase
- **Practice bonuses** for repeated subjects

### 📚 Portfolio Integration
- **Automatic sketch storage** in portfolio system
- **Subject tracking** to prevent duplicate counting
- **Quality ratings** and creation dates
- **Subject metadata** preservation (type, name, difficulty)
- **Inspiration source** tracking for future artwork creation

## Technical Implementation

### Sketching Process Flow
1. **Subject Detection**: Player approaches sketchable subject
2. **Highlighting**: Subject becomes visually highlighted
3. **Interaction**: Player presses E to start sketching
4. **Observation Phase**: Required observation time based on difficulty
5. **Sketching Phase**: Progress based on player skills
6. **Completion**: Quality calculation and portfolio storage
7. **Rewards**: Experience points awarded

### Subject Types & Mechanics
- **Buildings**: Longer observation time, architectural complexity
- **People**: Medium observation, pose and movement factors
- **Objects**: Quick observation, material and size considerations
- **Scenes**: Longest observation, multiple element complexity

### Quality Calculation Factors
- **Base Quality**: Starting point (3.0)
- **Skill Bonus**: Sketching + Observation skills
- **Observation Bonus**: Time spent observing vs. required
- **Practice Bonus**: Previous sketches of same subject
- **Difficulty Multiplier**: Subject complexity affects potential
- **Randomness**: Small random variation for realism

## Controls
- **WASD/Arrow Keys**: Move around Florence
- **E**: Start sketching when near highlighted subjects
- **ESC**: Cancel sketching (during sketching process)
- **I**: Open Inventory
- **P**: Open Portfolio (view completed sketches)

## Subject Configuration
Each sketchable subject includes:
- **Subject ID**: Unique identifier for tracking
- **Name & Description**: Display information
- **Subject Type**: Building, Person, Object, or Scene
- **Difficulty**: Affects observation time and quality potential
- **Type-specific metadata**: Architecture style, scene elements, etc.

## Testing
Run `scenes/tests/Task8_SketchingTest.tscn` to test:
- ✅ Subject highlighting and interaction
- ✅ Sketching UI and progress tracking
- ✅ Quality calculation and skill progression
- ✅ Portfolio integration
- ✅ Experience point rewards

## Integration Points
- **Florence Environment**: Sketchable subjects integrated into city
- **Portfolio System**: Sketches automatically stored and displayed
- **Skill Manager**: Experience points awarded for sketching activities
- **UI Manager**: Sketching UI integrated with existing UI systems

## Future Enhancements
- **Dynamic subjects**: NPCs and moving objects to sketch
- **Weather effects**: Different lighting conditions affecting sketches
- **Sketch comparison**: Visual before/after for repeated subjects
- **Master feedback**: NPC comments on sketch quality
- **Sketch trading**: Exchange sketches with other characters

## Requirements Satisfied
- ✅ **4.2**: Sketchable objects highlighted as interactive elements
- ✅ **4.3**: Sketching interface appropriate for subject types
- ✅ **4.4**: Completed sketches added to portfolio with skill progression
- ✅ **4.5**: Varied mechanics for different subject types
- ✅ **4.6**: Quality improvement tracking over repeated subjects
- ✅ **5.1**: Skill progression integration

## Files Created/Modified
- `scripts/systems/SketchingSystem.gd` - Core sketching mechanics
- `scripts/ui/SketchingUI.gd` - Sketching interface
- `scenes/ui/SketchingUI.tscn` - Sketching UI scene
- `scenes/tests/Task8_SketchingTest.tscn` - Test scene
- `scripts/tests/Task8_SketchingTest.gd` - Test script
- `scenes/environments/Florence.tscn` - Added sketchable subjects
- `scripts/environments/Florence.gd` - Integrated sketching system

The sketching system provides a rich, skill-based activity that encourages exploration of Florence while building the player's artistic abilities and portfolio. The system is designed to be extensible for future subject types and enhanced mechanics.