# Step 4 Quick Start Instructions

## What We Just Created

✅ **MasterArtistAgent.gd** - The AI orchestrator that generates tasks
✅ **test_master_artist_agent.gd** - A test script to verify it works
✅ **STEP4_BEGINNER_GUIDE.md** - Detailed explanations of every concept and function

## Getting Started: 3 Easy Steps

### Step 1: Register MasterArtistAgent as Autoload

1. Open Godot
2. Go to **Project → Project Settings**
3. Click the **Autoload** tab
4. Click the folder icon next to "Path"
5. Navigate to and select: `res://scripts/systems/MasterArtistAgent.gd`
6. In "Node Name", type: `MasterArtistAgent`
7. Click **Add**
8. Click **Close**

**Why:** This makes `MasterArtistAgent` available globally throughout your game, like `GameManager` and `TaskManager`.

---

### Step 2: Create and Run the Test Scene

1. In Godot, create a new scene: **Scene → New Scene**
2. Add a **Node** as the root (right-click in Scene tree → "Add Child Node" → search "Node")
3. Rename it to: `MasterArtistAgentTest`
4. With the node selected, attach a script:
   - Click the "Attach Script" icon (scroll/paper with + sign)
   - In the path field, paste: `res://scripts/tests/test_master_artist_agent.gd`
   - Click **Load** (not Create)
5. Save the scene: **Scene → Save Scene**
   - Navigate to `res://scenes/tests/`
   - Name it: `MasterArtistAgentTest.tscn`
   - Click **Save**

---

### Step 3: Test It!

**Before running:**
1. ✅ Make sure **LM Studio** is running
2. ✅ Ensure you've **loaded a model** in LM Studio (like Gemma 3 4B)
3. ✅ Verify the **Local Server** is ON (green checkmark in LM Studio)

**Run the test:**
1. With `MasterArtistAgentTest.tscn` open, press **F6** (or click "Run Current Scene")
2. You should see "🧪 MasterArtistAgent Test Ready" in the console
3. Press **SPACE** to generate a task
4. Watch the console output for:
   - Debug messages showing context gathering
   - LLM call and response
   - Validation results
   - Generated task details

**Expected output:**
```
✅ MasterArtistAgent initialized
🧪 MasterArtistAgent Test Ready
Press SPACE to generate a task

[You press SPACE]

==================================================
🎨 Testing MasterArtistAgent...
==================================================

📊 Game Context Built:
  Skills: {...}
  Inventory items: 0
  Completed tasks: 0
  Active tasks: 0
  Relationship: 0

📝 Prompt Messages Built:
  System: 302 chars
  Developer: 1453 chars
  User: 245 chars

🤖 Calling LLM...
  Endpoint: http://127.0.0.1:1234/v1/chat/completions

✅ LLM Response Received:
  Length: 587 characters
  Preview: {"task_id": "task_gather_first_pigments"...

🔍 Validating AI response...
✅ Validation passed!
  Task: Gather Your First Pigments
  Type: GATHERING, Difficulty: BEGINNER
  Objectives: 2

==================================================
✅ SUCCESS! Generated task:
==================================================
📋 ID: task_gather_first_pigments
📝 Title: Gather Your First Pigments
📄 Description: Begin your artistic journey by collecting...
```

---

## Troubleshooting

### Problem: "Failed to send request"
**Solution:** LM Studio isn't running or the server isn't enabled.
- Open LM Studio
- Go to the "Local Server" tab
- Click "Start" if it shows a Start button
- Look for green checkmark and "Server is running at http://localhost:1234"

### Problem: "Invalid JSON received"
**Solution:** The model added markdown formatting.
- This is already handled in the code (strips ```json blocks)
- Try running again (press Space)
- If it persists, try a different model in LM Studio

### Problem: "Missing required field"
**Solution:** The model didn't follow the format perfectly.
- This is normal for local LLMs
- Try running again
- Consider using a larger/better model
- Check that your model is instruction-tuned (like Gemma 3, Llama, etc.)

### Problem: Nothing happens / no output
**Solution:** Check the Godot console (at the bottom)
- Look for error messages in red
- Check that `MasterArtistAgent` appears in the Autoload list (Project Settings → Autoload)
- Verify the test script is attached to the node

---

## What Happens Next?

After you've verified Step 4 is working:

1. **Step 5** - Convert the validated JSON into a full `TaskData` object
   - Map strings to enums (CRAFTING → TaskData.TaskType.CRAFTING)
   - Populate all objectives, rewards, and requirements
   
2. **Step 6** - Wire the agent into your MasterArtist NPC
   - Make the NPC call `MasterArtistAgent.generate_task()`
   - Handle success and failure cases
   - Display the generated task to the player

3. **Step 7** - Add developer ergonomics
   - Debug toggle
   - Better logging
   - Error recovery

4. **Step 8** - Create a full game test
   - Test in actual gameplay
   - Verify task completion works
   - Test edge cases

---

## Key Files Created

| File | Location | Purpose |
|------|----------|---------|
| `MasterArtistAgent.gd` | `scripts/systems/` | Main AI orchestrator |
| `test_master_artist_agent.gd` | `scripts/tests/` | Test harness |
| `STEP4_BEGINNER_GUIDE.md` | `.kiro/specs/task15-master-artist-agent/` | Detailed guide |
| `STEP4_QUICKSTART.md` | `.kiro/specs/task15-master-artist-agent/` | This file! |

---

## Need Help?

📖 **Read:** [STEP4_BEGINNER_GUIDE.md](.kiro/specs/task15-master-artist-agent/STEP4_BEGINNER_GUIDE.md)
   - Explains every concept in detail
   - Shows what each function does
   - Includes common issues and solutions

🧪 **Experiment:** Modify the test script
   - Try adding test inventory items
   - Change skill levels
   - See how the AI adapts

🔍 **Debug:** Set `debug_mode = true` in `MasterArtistAgent.gd` (line 13)
   - Already enabled by default
   - Shows detailed logs of every step

---

## Success Criteria

You know Step 4 is complete when:
- ✅ You can run the test scene without errors
- ✅ Pressing Space calls the LLM
- ✅ You see "✅ Validation passed!" in the console
- ✅ A task with title, description, and dialogue is generated
- ✅ The generated task uses valid item IDs and task types

Once these work, you're ready for Step 5! 🎉
