# Audio Setup Guide

## Current Audio Files

Your audio files are located in `assets/audio/`:

### Music
- `BeepBox-Song-1.wav` - Main workshop theme music

### Sound Effects
- `mixkit-game-ball-tap-2073.wav` - UI clicks, interactions, gathering
- `mixkit-game-bonus-reached-2065.wav` - Crafting success
- `mixkit-video-game-treasure-2066.wav` - Skill ups, achievements

## Audio Mapping

The AudioManager has been configured to use your audio files:

### Music Tracks
- `"workshop_theme"` → BeepBox-Song-1.wav
- `"main_theme"` → BeepBox-Song-1.wav

### Sound Effects
- `"ui_click"` → mixkit-game-ball-tap-2073.wav (UI interactions)
- `"crafting_success"` → mixkit-game-bonus-reached-2065.wav (Successful crafting)
- `"skill_up"` → mixkit-video-game-treasure-2066.wav (Skill level increases)
- `"achievement_unlocked"` → mixkit-video-game-treasure-2066.wav (Achievement unlocks)
- `"gathering"` → mixkit-game-ball-tap-2073.wav (Material gathering)
- `"sketching"` → mixkit-game-ball-tap-2073.wav (Sketching actions)
- `"footstep"` → mixkit-game-ball-tap-2073.wav (Player footsteps)

### Ambient Tracks
- `"workshop_ambient"` → BeepBox-Song-1.wav (Workshop background)
- `"city_ambient"` → BeepBox-Song-1.wav (Florence city background)

## Where Audio Plays

### Automatic Audio
The following audio plays automatically during gameplay:

1. **Workshop Scene**
   - Background music starts when entering the workshop
   - Crafting success sound plays when completing crafting
   - UI click sound plays on interactions

2. **Skill System**
   - Skill up sound plays when any skill levels up
   - Visual effects accompany the sound

3. **Crafting Stations**
   - Success sound + VFX when crafting completes
   - Skill experience gain triggers skill up sounds

### Manual Testing
Use the test scene (`scenes/tests/Task13_AdvancedFeaturesTest.tscn`) to test all audio:
- Press `1` for UI click
- Press `2` for crafting success
- Press `3` for skill up
- Press `A` to toggle music on/off

## Adding More Audio Files

To add more audio files:

1. **Add the file** to `assets/audio/` folder
2. **Update AudioManager** in `scripts/singletons/AudioManager.gd`:
   ```gdscript
   func _load_audio_library():
       # Add your new audio file
       sfx_library["your_sound_name"] = load("res://assets/audio/your_file.wav")
   ```
3. **Use it in your code**:
   ```gdscript
   AudioManager.play_sfx("your_sound_name")
   ```

## Audio File Recommendations

For a complete audio experience, consider adding:

### Music
- `workshop_theme.wav` - Calm, creative music for workshop
- `city_theme.wav` - Lively Renaissance music for Florence
- `natural_areas_theme.wav` - Peaceful outdoor music

### Sound Effects
- `paint_mixing.wav` - Mixing paint sounds
- `canvas_stretch.wav` - Canvas preparation
- `brush_stroke.wav` - Painting sounds
- `paper_rustle.wav` - Sketching sounds
- `footstep_stone.wav` - Walking on stone floors
- `door_open.wav` - Door opening/closing
- `item_pickup.wav` - Picking up items
- `level_up.wav` - Dedicated level up fanfare

### Ambient
- `workshop_ambient.wav` - Workshop background (tools, distant sounds)
- `city_ambient.wav` - City sounds (people, carts, bells)
- `nature_ambient.wav` - Birds, wind, water

## Audio Settings

Players can control audio volume through the AudioManager:

```gdscript
# Set volumes (0.0 to 1.0)
AudioManager.set_music_volume(0.7)
AudioManager.set_sfx_volume(0.8)
AudioManager.set_ambient_volume(0.5)
```

Default volumes:
- Music: 70%
- SFX: 80%
- Ambient: 50%

## Troubleshooting

### No Sound Playing
1. Check that audio files are in `assets/audio/`
2. Verify files are imported as AudioStreamWAV in Godot
3. Check that AudioManager is in autoload (project.godot)
4. Ensure volume is not set to 0

### Audio Cutting Out
- Increase `MAX_SFX_PLAYERS` in AudioManager if many sounds play simultaneously
- Currently set to 8 concurrent sounds

### Music Not Looping
- For WAV files, set loop mode in Godot's import settings
- Right-click audio file → Reimport → Set Loop Mode

## Testing Checklist

- [ ] Music plays when entering Workshop
- [ ] UI click sound on interactions
- [ ] Crafting success sound when completing crafts
- [ ] Skill up sound when skills increase
- [ ] Achievement sound when unlocking achievements
- [ ] Music fades smoothly when toggling
- [ ] Multiple sounds can play simultaneously
- [ ] Volume controls work correctly

## Next Steps

1. **Test the audio** - Run the Workshop scene or test scene
2. **Add more audio files** - Enhance the experience with more sounds
3. **Adjust volumes** - Fine-tune the audio balance
4. **Add audio settings UI** - Let players control volumes in-game
