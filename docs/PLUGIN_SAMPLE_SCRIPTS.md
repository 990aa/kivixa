# Plugin Sample Scripts

This document contains sample Lua scripts to test all Plugin API functionalities in Kivixa.
Copy and paste these scripts into the **Script Runner** (accessible from the Plugins page).

---

## Security: Sandboxed File Access

**All file operations are sandboxed within the Kivixa data folder.** This means:

- ✅ Paths like `/PluginTests/Note` → Creates inside `Kivixa/PluginTests/Note`
- ✅ Paths like `Journal/2024/Jan` → Creates inside `Kivixa/Journal/2024/Jan`
- ❌ Path traversal (`../`) is blocked
- ❌ Absolute paths outside Kivixa are blocked

Scripts cannot access, modify, or delete files outside the Kivixa data folder. This protects your system from malicious or buggy scripts.

---

## How to Access the Plugin System

### Step 1: Open the Plugins Page

1. **Launch Kivixa** on Windows
2. **Navigate to Settings:**
   - Click the **Settings** tab in the bottom navigation bar (gear icon ⚙️)
   - On larger screens, use the navigation rail on the left
3. **Scroll down** to the **"Extensions"** section (near the bottom, after "Advanced" section)
4. **Click "Lua Plugins"** button
5. The **Plugins Page** opens with three tabs:
   - **Installed** - Shows plugins in the plugins folder
   - **Create** - Create a new plugin file
   - **Script** - Run one-off Lua scripts (Script Runner)

### Step 2: Using the Script Runner

1. On the Plugins Page, tap the **code icon** (</>) button in the app bar
2. A dialog opens with a text editor
3. **Paste any script** from this document into the editor
4. Click the **"Run"** button (play icon ▶️)
5. Results appear as a snackbar message

### Step 3: Viewing Plugin Results

After running a plugin or script:
1. A snackbar shows a brief result message
2. The **"Recent Results"** section appears at the top of the Plugins page
3. **Tap on any recent result card** to see:
   - Full result message (scrollable)
   - Execution timestamp
   - Option to "Run Again"

### Step 4: Creating a Permanent Plugin

1. On the Plugins Page, tap the **+ button** in the app bar
2. Enter a **Plugin Name** (e.g., "daily-journal")
3. Optionally enter a description
4. Write or paste your Lua code
5. Click **"Create"** to save the plugin
6. The plugin appears in the list and can be run anytime

---

## Table of Contents

1. [Basic Output & Logging](#1-basic-output--logging)
2. [Note Statistics](#2-note-statistics)
3. [Create a Note](#3-create-a-note)
4. [Read a Note](#4-read-a-note)
5. [Write/Update a Note](#5-writeupdate-a-note)
6. [Delete a Note](#6-delete-a-note)
7. [Find Notes by Pattern](#7-find-notes-by-pattern)
8. [Get Recent Notes](#8-get-recent-notes)
9. [Get Notes Older Than X Days](#9-get-notes-older-than-x-days)
10. [Get All Notes](#10-get-all-notes)
11. [Create a Folder](#11-create-a-folder)
12. [Move a Note](#12-move-a-note)
13. [Combined Workflow: Daily Journal Generator](#13-combined-workflow-daily-journal-generator)
14. [Combined Workflow: Archive Completed Tasks](#14-combined-workflow-archive-completed-tasks)
15. [Combined Workflow: Note Cleanup Report](#15-combined-workflow-note-cleanup-report)
16. [Calendar: Get Today's Events](#16-calendar-get-todays-events)
17. [Calendar: Add an Event](#17-calendar-add-an-event)
18. [Calendar: Update an Event](#18-calendar-update-an-event)
19. [Calendar: Delete an Event](#19-calendar-delete-an-event)
20. [Calendar: Complete a Task](#20-calendar-complete-a-task)
21. [Calendar: Week Overview](#21-calendar-week-overview)
22. [Productivity Timer: Get Stats](#22-productivity-timer-get-stats)
23. [Productivity Timer: Start Session](#23-productivity-timer-start-session)
24. [Productivity Timer: Control Session](#24-productivity-timer-control-session)
25. [Productivity Timer: Session History](#25-productivity-timer-session-history)

---

## 1. Basic Output & Logging

**What it does:** Tests basic Lua execution, print output, and the App:log() function.

```lua
-- Basic Output Test
print("Hello from Lua!")
print("Testing basic arithmetic: 2 + 2 = " .. (2 + 2))

-- Test logging
App:log("This message appears in the app logs")

return "Basic test completed successfully!"
```

**How to verify:**
- The script runner shows "Basic test completed successfully!" as the result
- To check logs: Go to **Settings** → scroll to **Advanced** → click **"View Logs"**
- Look for "Hello from Lua!" and the log message in the log viewer

---

## 2. Note Statistics

**What it does:** Retrieves and displays statistics about your notes database.

```lua
-- Get Statistics
local stats = App:getStats()

local result = "=== Note Statistics ===\n"
result = result .. "Total Notes: " .. (stats.totalNotes or 0) .. "\n"
result = result .. "Total Folders: " .. (stats.totalFolders or 0) .. "\n"

return result
```

**How to verify:**
- Compare the numbers with your actual file count:
  1. Go to the **Browse** tab (folder icon in bottom navigation)
  2. Count the total files and folders visible
  3. The numbers should match the count of .md, .kvx, and .kvtx files

---

## 3. Create a Note

**What it does:** Creates a new markdown note at a specified path.

```lua
-- Create a Test Note
local path = "/PluginTests/TestNote"
local content = [[
# Test Note Created by Plugin

This note was automatically created by a Lua plugin.

## Features Tested
- [x] Note creation
- [x] Markdown formatting
- [x] Nested folder creation

Created at: ]] .. os.date("%Y-%m-%d %H:%M:%S")

local success = App:writeNote(path, content)

if success then
    return "✅ Note created at: " .. path
else
    return "❌ Failed to create note"
end
```

**How to verify:**
1. Go to the **Browse** tab (folder icon in bottom navigation)
2. Look for folder "PluginTests" in the file list
3. Tap on "PluginTests" to open it
4. Tap on "TestNote" to open the file
5. The note should contain the markdown content with creation timestamp

---

## 4. Read a Note

**What it does:** Reads and returns the content of an existing note.

```lua
-- Read a Note
-- First, let's create one to ensure it exists
local testPath = "/PluginTests/ReadTest"
App:writeNote(testPath, "Line 1: Hello\nLine 2: World\nLine 3: From Lua!")

-- Now read it back
local content = App:readNote(testPath)

if content then
    local lineCount = 0
    for _ in content:gmatch("[^\n]+") do
        lineCount = lineCount + 1
    end
    
    return "=== Note Content ===\n" .. content .. "\n\n(Total lines: " .. lineCount .. ")"
else
    return "❌ Note not found or could not be read"
end
```

**How to verify:**
- Result should show the exact content: "Line 1: Hello\nLine 2: World\nLine 3: From Lua!"
- Line count should be 3

---

## 5. Write/Update a Note

**What it does:** Creates a note, then updates it with new content.

```lua
-- Write/Update Test
local path = "/PluginTests/UpdateTest"

-- Create initial content
App:writeNote(path, "Version 1: Original content")
local v1 = App:readNote(path)

-- Update with new content
App:writeNote(path, "Version 2: Updated content at " .. os.date("%H:%M:%S"))
local v2 = App:readNote(path)

local result = "=== Update Test ===\n"
result = result .. "Before: " .. (v1 or "nil") .. "\n"
result = result .. "After: " .. (v2 or "nil") .. "\n"

if v2 and v2:match("Version 2") then
    return result .. "\n✅ Update successful!"
else
    return result .. "\n❌ Update failed"
end
```

**How to verify:**
1. Go to the **Browse** tab
2. Navigate to: PluginTests → UpdateTest
3. Open "UpdateTest" in the editor
4. Content should show "Version 2: Updated content at [time]"
5. Go back to **Settings** → **Lua Plugins** → **Script** tab
6. Re-run the script and check that the time changes

---

## 6. Delete a Note

**What it does:** Creates a note, verifies it exists, deletes it, and verifies deletion.

```lua
-- Delete Test
local path = "/PluginTests/ToBeDeleted"

-- Create a note first
App:writeNote(path, "This note will be deleted")

-- Verify it exists
local beforeDelete = App:readNote(path)
local existsBefore = beforeDelete ~= nil

-- Delete it
local deleteResult = App:deleteNote(path)

-- Verify it's gone
local afterDelete = App:readNote(path)
local existsAfter = afterDelete ~= nil

local result = "=== Delete Test ===\n"
result = result .. "Existed before delete: " .. tostring(existsBefore) .. "\n"
result = result .. "Delete returned: " .. tostring(deleteResult) .. "\n"
result = result .. "Exists after delete: " .. tostring(existsAfter) .. "\n"

if existsBefore and deleteResult and not existsAfter then
    return result .. "\n✅ Delete successful!"
else
    return result .. "\n❌ Delete test failed"
end
```

**How to verify:**
- All three conditions should be met: existed before, delete returned true, doesn't exist after
- Go to **Browse** tab → navigate to PluginTests
- The "ToBeDeleted" file should not exist (you may need to refresh by pulling down)

---

## 7. Find Notes by Pattern

**What it does:** Searches for notes containing a specific pattern in their path/name.

```lua
-- Find Notes by Pattern
-- First, create some test notes
App:writeNote("/PluginTests/Search/Apple", "Apple note")
App:writeNote("/PluginTests/Search/Banana", "Banana note")
App:writeNote("/PluginTests/Search/ApplePie", "Apple Pie recipe")
App:writeNote("/PluginTests/Search/Cherry", "Cherry note")

-- Search for "Apple"
local matches = App:findNotes("Apple")

local result = "=== Search Results for 'Apple' ===\n"
result = result .. "Found " .. #matches .. " matches:\n\n"

for i, path in ipairs(matches) do
    result = result .. i .. ". " .. path .. "\n"
end

return result
```

**How to verify:**
- Should find at least 2 notes: one with "Apple" and one with "ApplePie"
- All results should contain "Apple" (case-insensitive)

---

## 8. Get Recent Notes

**What it does:** Retrieves the most recently modified notes.

```lua
-- Get Recent Notes
-- Create a few notes with different times
App:writeNote("/PluginTests/Recent/Note1", "Created first")
App:writeNote("/PluginTests/Recent/Note2", "Created second")  
App:writeNote("/PluginTests/Recent/Note3", "Created third - most recent")

-- Get 5 most recent notes
local recent = App:getRecentNotes(5)

local result = "=== 5 Most Recent Notes ===\n\n"

for i, path in ipairs(recent) do
    result = result .. i .. ". " .. path .. "\n"
end

if #recent == 0 then
    result = result .. "(No notes found)"
end

return result
```

**How to verify:**
- The notes we just created should appear near the top
- Note3 should be the most recent (appears first or near first)
- List should show at most 5 notes

---

## 9. Get Notes Older Than X Days

**What it does:** Finds notes that haven't been modified in the specified number of days.

```lua
-- Get Old Notes
-- Note: This only finds notes older than the specified days
-- For testing, use 0 days to find notes not modified today

local days = 0  -- Change this to test different thresholds
local oldNotes = App:getNotesOlderThan(days)

local result = "=== Notes Older Than " .. days .. " Days ===\n\n"
result = result .. "Found " .. #oldNotes .. " old notes:\n\n"

-- Show first 10 only
local limit = math.min(#oldNotes, 10)
for i = 1, limit do
    result = result .. i .. ". " .. oldNotes[i] .. "\n"
end

if #oldNotes > 10 then
    result = result .. "\n... and " .. (#oldNotes - 10) .. " more"
end

return result
```

**How to verify:**
- With days=0, shows notes not modified today
- Increase days to see progressively older notes
- Notes just created should NOT appear when days=1 or higher

---

## 10. Get All Notes

**What it does:** Retrieves a complete list of all notes in your workspace.

```lua
-- Get All Notes
local allNotes = App:getAllNotes()

local result = "=== All Notes in Workspace ===\n\n"
result = result .. "Total: " .. #allNotes .. " notes\n\n"

-- Categorize by folder
local folders = {}
for _, path in ipairs(allNotes) do
    local folder = path:match("^(/[^/]+)") or "/"
    folders[folder] = (folders[folder] or 0) + 1
end

result = result .. "By top-level folder:\n"
for folder, count in pairs(folders) do
    result = result .. "  " .. folder .. ": " .. count .. " notes\n"
end

return result
```

**How to verify:**
- Total should match App:getStats().totalNotes
- Each folder count should roughly match what you see in Browse

---

## 11. Create a Folder

**What it does:** Creates a new folder structure.

```lua
-- Create Folder Test
local folderPath = "PluginTests/Folders/Deep/Nested/Structure"
local success = App:createFolder(folderPath)

-- Verify by creating a note inside it
local notePath = "/" .. folderPath .. "/TestFile"
App:writeNote(notePath, "File in nested folder")

local verification = App:readNote(notePath)

local result = "=== Create Folder Test ===\n"
result = result .. "Folder path: " .. folderPath .. "\n"
result = result .. "Create returned: " .. tostring(success) .. "\n"
result = result .. "Can write to folder: " .. tostring(verification ~= nil) .. "\n"

if success and verification then
    return result .. "\n✅ Folder creation successful!"
else
    return result .. "\n❌ Folder creation failed"
end
```

**How to verify:**
1. Go to **Browse** tab
2. Navigate to: PluginTests → Folders → Deep → Nested → Structure
3. "TestFile" should exist in the deepest folder
4. Open it to verify it has content

---

## 12. Move a Note

**What it does:** Moves a note from one location to another.

```lua
-- Move Note Test
local sourcePath = "/PluginTests/Move/OriginalLocation"
local destPath = "/PluginTests/Move/NewLocation"

-- Create source note
App:writeNote(sourcePath, "This note will be moved\nContent should stay intact")

-- Verify source exists
local beforeMove = App:readNote(sourcePath)

-- Move the note
local moveResult = App:moveNote(sourcePath, destPath)

-- Verify results
local sourceAfter = App:readNote(sourcePath)
local destAfter = App:readNote(destPath)

local result = "=== Move Note Test ===\n"
result = result .. "Source existed: " .. tostring(beforeMove ~= nil) .. "\n"
result = result .. "Move returned: " .. tostring(moveResult) .. "\n"
result = result .. "Source after (should be nil): " .. tostring(sourceAfter) .. "\n"
result = result .. "Dest after (should have content): " .. tostring(destAfter ~= nil) .. "\n"

if beforeMove and moveResult and not sourceAfter and destAfter then
    result = result .. "\nContent preserved: " .. (destAfter == beforeMove and "✅ Yes" or "❌ No")
    return result .. "\n\n✅ Move successful!"
else
    return result .. "\n\n❌ Move failed"
end
```

**How to verify:**
1. Go to **Browse** tab
2. Navigate to: PluginTests → Move
3. Check that "OriginalLocation" does NOT exist
4. Check that "NewLocation" exists with the correct content

---

## 13. Combined Workflow: Daily Journal Generator

**What it does:** Creates a daily journal entry with a template.

```lua
-- Daily Journal Generator
local today = os.date("%Y-%m-%d")
local dayName = os.date("%A")
local monthName = os.date("%B")
local year = os.date("%Y")

local journalPath = "/Journal/" .. year .. "/" .. monthName .. "/" .. today

-- Check if today's journal exists
local existing = App:readNote(journalPath)

if existing then
    return "📓 Today's journal already exists at: " .. journalPath
end

-- Create journal template
local template = [[
# Daily Journal - ]] .. today .. [[


## 🌅 Morning Intentions
- [ ] 
- [ ] 
- [ ] 

## 📝 Notes & Thoughts


## ✅ Accomplishments
- 

## 📚 What I Learned


## 🙏 Gratitude
1. 
2. 
3. 

## 🌙 Evening Reflection


---
*Created on ]] .. dayName .. ", " .. os.date("%B %d, %Y at %H:%M") .. [[*
]]

local success = App:writeNote(journalPath, template)

if success then
    return "📓 Created today's journal at: " .. journalPath .. "\n\nOpen it and start writing!"
else
    return "❌ Failed to create journal"
end
```

**How to verify:**
1. Go to **Browse** tab
2. Navigate to: Journal → [current year] → [current month] → [today's date]
3. Open the note - should have the complete journal template
4. Go back to **Settings** → **Lua Plugins** → **Script** tab
5. Run again - should say "already exists"

---

## 14. Combined Workflow: Archive Completed Tasks

**What it does:** Scans notes for completed checkbox tasks and moves them to an archive.

```lua
-- Archive Completed Tasks
-- First, create a test todo note
local todoPath = "/PluginTests/TodoList"
local todoContent = [[
# My Todo List

## Work
- [x] Complete project proposal
- [ ] Review pull requests
- [x] Send weekly report
- [ ] Schedule team meeting

## Personal
- [x] Buy groceries
- [ ] Call mom
- [x] Pay bills

## Unchecked
- [ ] This is not done
- [ ] Neither is this
]]

App:writeNote(todoPath, todoContent)

-- Read and process
local content = App:readNote(todoPath)
if not content then
    return "❌ Could not read todo list"
end

local completedTasks = {}
local remainingLines = {}

for line in content:gmatch("[^\n]*") do
    if line:match("%[%s*[xX]%s*%]") then
        table.insert(completedTasks, line)
    else
        table.insert(remainingLines, line)
    end
end

if #completedTasks == 0 then
    return "No completed tasks found to archive"
end

-- Update original note (remove completed)
App:writeNote(todoPath, table.concat(remainingLines, "\n"))

-- Add to archive
local archivePath = "/PluginTests/Archive/CompletedTasks"
local archiveContent = App:readNote(archivePath) or "# Completed Tasks Archive\n"

archiveContent = archiveContent .. "\n\n## Archived on " .. os.date("%Y-%m-%d %H:%M") .. "\n"
for _, task in ipairs(completedTasks) do
    archiveContent = archiveContent .. task .. "\n"
end

App:writeNote(archivePath, archiveContent)

local result = "=== Archive Results ===\n"
result = result .. "Found " .. #completedTasks .. " completed tasks:\n\n"
for _, task in ipairs(completedTasks) do
    result = result .. "  " .. task .. "\n"
end
result = result .. "\n✅ Moved to: " .. archivePath

return result
```

**How to verify:**
1. Go to **Browse** tab
2. Navigate to: PluginTests → TodoList
3. The file should only have unchecked items (lines with `- [ ]`)
4. Navigate to: PluginTests → Archive → CompletedTasks
5. Should have the archived checked items with timestamp (lines with `- [x]`)

---

## 15. Combined Workflow: Note Cleanup Report

**What it does:** Generates a comprehensive report about your notes for cleanup purposes.

```lua
-- Note Cleanup Report
local stats = App:getStats()
local allNotes = App:getAllNotes()
local oldNotes = App:getNotesOlderThan(30)
local recentNotes = App:getRecentNotes(5)

local report = [[
# 📊 Note Cleanup Report
Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[


## Summary
- **Total Notes:** ]] .. (stats.totalNotes or 0) .. [[

- **Total Folders:** ]] .. (stats.totalFolders or 0) .. [[

- **Notes older than 30 days:** ]] .. #oldNotes .. [[


## 🕐 Recently Modified (Top 5)
]]

for i, path in ipairs(recentNotes) do
    report = report .. i .. ". " .. path .. "\n"
end

report = report .. [[

## ⏰ Potentially Stale Notes (30+ days old)
]]

if #oldNotes > 0 then
    local limit = math.min(#oldNotes, 10)
    for i = 1, limit do
        report = report .. "- " .. oldNotes[i] .. "\n"
    end
    if #oldNotes > 10 then
        report = report .. "- ... and " .. (#oldNotes - 10) .. " more\n"
    end
else
    report = report .. "None found! All notes are recent.\n"
end

-- Folder analysis
report = report .. [[

## 📁 Notes by Folder
]]

local folders = {}
for _, path in ipairs(allNotes) do
    local folder = path:match("^(/[^/]+)") or "/root"
    folders[folder] = (folders[folder] or 0) + 1
end

local sortedFolders = {}
for folder, count in pairs(folders) do
    table.insert(sortedFolders, {folder = folder, count = count})
end
table.sort(sortedFolders, function(a, b) return a.count > b.count end)

for _, item in ipairs(sortedFolders) do
    report = report .. "- " .. item.folder .. ": " .. item.count .. " notes\n"
end

report = report .. [[

---
*Run this script periodically to keep your notes organized!*
]]

-- Save the report
local reportPath = "/Reports/CleanupReport-" .. os.date("%Y%m%d")
App:writeNote(reportPath, report)

return "📊 Report generated and saved to:\n" .. reportPath .. "\n\n" .. report
```

**How to verify:**
1. Result shows the full report in the script runner output
2. Go to **Browse** tab
3. Navigate to: Reports → CleanupReport-[today's date in YYYYMMDD format]
4. The saved note should match the displayed output

---

## 16. Calendar: Get Today's Events

**What it does:** Retrieves all calendar events and tasks scheduled for today.

```lua
-- Get Today's Calendar Events
local today = os.date("*t")
local events = App:getEventsForDate(today.year, today.month, today.day)

local result = "=== Today's Calendar (" .. os.date("%Y-%m-%d") .. ") ===\n\n"

if #events == 0 then
    result = result .. "No events scheduled for today.\n"
else
    for i, event in ipairs(events) do
        local prefix = event.type == "task" and "✅ " or "📅 "
        result = result .. prefix .. event.title
        
        if event.startHour then
            result = result .. " @ " .. string.format("%02d:%02d", event.startHour, event.startMinute or 0)
        elseif event.isAllDay then
            result = result .. " (All day)"
        end
        
        if event.isCompleted then
            result = result .. " [DONE]"
        end
        
        result = result .. "\n"
    end
end

return result
```

**How to verify:**
1. Result displays events currently scheduled in the Calendar for today
2. Open **Calendar** tab to verify the events listed match

---

## 17. Calendar: Add an Event

**What it does:** Creates a new event in the calendar.

```lua
-- Add a Calendar Event
local today = os.date("*t")

local eventId = App:addCalendarEvent(
    "Team Standup",           -- title
    today.year,               -- year
    today.month,              -- month
    today.day,                -- day
    {
        description = "Daily sync meeting",
        startHour = 9,
        startMinute = 30,
        endHour = 10,
        endMinute = 0,
        type = "event",       -- "event" or "task"
        colorHex = "#4CAF50"  -- Optional: green color
    }
)

if eventId then
    return "✅ Event created successfully!\nID: " .. eventId
else
    return "❌ Failed to create event"
end
```

**How to verify:**
1. Result shows the created event ID
2. Open **Calendar** tab and navigate to today
3. The "Team Standup" event should appear at 9:30 AM

---

## 18. Calendar: Update an Event

**What it does:** Modifies an existing calendar event.

```lua
-- Update a Calendar Event
-- First, get today's events to find the ID
local today = os.date("*t")
local events = App:getEventsForDate(today.year, today.month, today.day)

if #events == 0 then
    return "No events to update today"
end

-- Update the first event
local eventToUpdate = events[1]
local success = App:updateCalendarEvent(
    eventToUpdate.id,
    {
        title = eventToUpdate.title .. " (Updated)",
        description = "Modified by Lua script",
        startHour = 14,
        startMinute = 0
    }
)

if success then
    return "✅ Updated event: " .. eventToUpdate.title .. "\nNew time: 14:00"
else
    return "❌ Failed to update event"
end
```

**How to verify:**
1. Result shows success message with event name
2. Open **Calendar** tab and verify the event was updated

---

## 19. Calendar: Delete an Event

**What it does:** Removes an event from the calendar.

```lua
-- Delete a Calendar Event
local today = os.date("*t")
local events = App:getEventsForDate(today.year, today.month, today.day)

if #events == 0 then
    return "No events to delete today"
end

-- Find an event with "(Updated)" in the title to delete
local eventToDelete = nil
for _, event in ipairs(events) do
    if event.title:find("%(Updated%)") then
        eventToDelete = event
        break
    end
end

if not eventToDelete then
    return "No '(Updated)' events found to delete"
end

local success = App:deleteCalendarEvent(eventToDelete.id)

if success then
    return "🗑️ Deleted event: " .. eventToDelete.title
else
    return "❌ Failed to delete event"
end
```

**How to verify:**
1. Result shows the deleted event name
2. Open **Calendar** tab and verify the event was removed

---

## 20. Calendar: Complete a Task

**What it does:** Marks a calendar task as completed.

```lua
-- Complete a Task
-- First, add a sample task
local today = os.date("*t")
local taskId = App:addCalendarEvent(
    "Test Task from Lua",
    today.year,
    today.month,
    today.day,
    {
        type = "task",
        description = "This task will be completed"
    }
)

if not taskId then
    return "Failed to create test task"
end

-- Now complete it
local success = App:completeTask(taskId, true)

if success then
    return "✅ Task marked as completed!\nTask ID: " .. taskId
else
    return "❌ Failed to complete task"
end
```

**How to verify:**
1. Open **Calendar** tab and look for today's tasks
2. The "Test Task from Lua" should show as completed (checked)

---

## 21. Calendar: Week Overview

**What it does:** Shows events for the next 7 days.

```lua
-- Weekly Calendar Overview
local result = "=== Week Overview ===\n\n"
local today = os.date("*t")
local daysOfWeek = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

for i = 0, 6 do
    -- Calculate date for each day
    local dayOffset = i * 24 * 60 * 60
    local targetTime = os.time(today) + dayOffset
    local targetDate = os.date("*t", targetTime)
    
    local dayName = daysOfWeek[targetDate.wday]
    local dateStr = os.date("%Y-%m-%d", targetTime)
    
    local events = App:getEventsForDate(targetDate.year, targetDate.month, targetDate.day)
    
    if i == 0 then
        result = result .. "📌 TODAY - " .. dayName .. " (" .. dateStr .. ")\n"
    else
        result = result .. "\n" .. dayName .. " (" .. dateStr .. ")\n"
    end
    
    if #events == 0 then
        result = result .. "   (no events)\n"
    else
        for _, event in ipairs(events) do
            local prefix = event.type == "task" and "  ✅ " or "  📅 "
            result = result .. prefix .. event.title
            if event.startHour then
                result = result .. " @ " .. string.format("%02d:%02d", event.startHour, event.startMinute or 0)
            end
            result = result .. "\n"
        end
    end
end

return result
```

**How to verify:**
1. Result shows a 7-day calendar summary
2. Events should match what's shown in the Calendar tab for each day

---

## 22. Productivity Timer: Get Stats

**What it does:** Retrieves your productivity timer statistics.

```lua
-- Productivity Timer Statistics
local stats = App:getTimerStats()
local state = App:getTimerState()

local result = "=== Productivity Dashboard ===\n\n"

-- Current session status
result = result .. "📊 Current Status\n"
result = result .. "   State: " .. (state.state or "idle") .. "\n"
if state.isRunning or state.isPaused then
    result = result .. "   Session: " .. (state.sessionType or "focus") .. "\n"
    result = result .. "   Remaining: " .. math.floor(state.remainingMinutes or 0) .. " minutes\n"
    result = result .. "   Cycle: " .. (state.currentCycle or 1) .. "/" .. (state.totalCycles or 1) .. "\n"
end

result = result .. "\n📈 Today\n"
result = result .. "   Focus time: " .. (stats.todayFocusMinutes or 0) .. " minutes\n"
result = result .. "   Sessions: " .. (stats.todaySessions or 0) .. "\n"

result = result .. "\n🏆 All Time\n"
result = result .. "   Total focus: " .. math.floor((stats.totalFocusMinutes or 0) / 60) .. " hours\n"
result = result .. "   Total sessions: " .. (stats.totalSessions or 0) .. "\n"
result = result .. "   Completed: " .. (stats.completedSessions or 0) .. "\n"
result = result .. "   Completion rate: " .. math.floor((stats.completionRate or 0) * 100) .. "%\n"

result = result .. "\n🔥 Streaks\n"
result = result .. "   Current streak: " .. (stats.currentStreak or 0) .. " days\n"
result = result .. "   Longest streak: " .. (stats.longestStreak or 0) .. " days\n"

return result
```

**How to verify:**
1. Open **Productivity** tab to compare statistics
2. Values should match your actual timer statistics

---

## 23. Productivity Timer: Start Session

**What it does:** Starts a new focus timer session.

```lua
-- Start a Productivity Timer Session
local state = App:getTimerState()

if state.isRunning then
    return "⚠️ Timer is already running!\n" ..
           "Session: " .. (state.sessionType or "unknown") .. "\n" ..
           "Remaining: " .. math.floor(state.remainingMinutes or 0) .. " minutes"
end

-- Configuration
local DURATION_MINUTES = 25  -- Pomodoro default
local SESSION_TYPE = "focus" -- Options: focus, deepWork, sprint, meeting, study, workout

local success = App:startTimer(DURATION_MINUTES, SESSION_TYPE)

if success then
    return "✅ Started " .. DURATION_MINUTES .. " minute " .. SESSION_TYPE .. " session!\n\n" ..
           "Good luck with your focused work!"
else
    return "❌ Failed to start timer"
end
```

**How to verify:**
1. Open **Productivity** tab
2. Timer should be running with the specified duration

---

## 24. Productivity Timer: Control Session

**What it does:** Demonstrates pausing, resuming, and stopping the timer.

```lua
-- Control the Productivity Timer
local state = App:getTimerState()
local action = ""
local success = false

if state.isRunning and not state.isPaused then
    -- Timer is running, pause it
    success = App:pauseTimer()
    action = "paused"
elseif state.isPaused then
    -- Timer is paused, resume it
    success = App:resumeTimer()
    action = "resumed"
else
    -- Timer is idle, nothing to control
    return "⚠️ No active timer session.\nUse App:startTimer() to begin a session."
end

if success then
    return "✅ Timer " .. action .. " successfully!"
else
    return "❌ Failed to " .. action:gsub("d$", "") .. " timer"
end
```

**How to verify:**
1. Run while timer is active to pause it
2. Run again to resume
3. Open **Productivity** tab to verify state changes

---

## 25. Productivity Timer: Session History

**What it does:** Shows your focus time history for the past week.

```lua
-- Productivity Session History
local history = App:getSessionHistory(7)  -- Last 7 days
local stats = App:getTimerStats()

local result = "=== Focus Time History (Last 7 Days) ===\n\n"

local totalWeek = 0
local days = {}

-- Collect days from history
for date, minutes in pairs(history) do
    table.insert(days, {date = date, minutes = minutes})
    totalWeek = totalWeek + minutes
end

-- Sort by date (newest first)
table.sort(days, function(a, b) return a.date > b.date end)

if #days == 0 then
    result = result .. "No sessions recorded in the last 7 days.\n"
else
    for _, day in ipairs(days) do
        local hours = math.floor(day.minutes / 60)
        local mins = day.minutes % 60
        local bar = string.rep("█", math.min(math.floor(day.minutes / 15), 20))
        result = result .. day.date .. ": " .. bar .. " " .. hours .. "h " .. mins .. "m\n"
    end
    
    result = result .. "\n📊 Weekly Total: " .. totalWeek .. " minutes"
    result = result .. " (" .. math.floor(totalWeek / 60) .. " hours " .. (totalWeek % 60) .. " minutes)\n"
    result = result .. "📈 Daily Average: " .. math.floor(totalWeek / 7) .. " minutes\n"
end

return result
```

**How to verify:**
1. Compare the history with your Productivity tab's weekly view
2. Check that daily totals match your recorded sessions

---

## Troubleshooting

### Script doesn't run
- Check for Lua syntax errors (missing `end`, unmatched quotes)
- Make sure the script returns a string for output

### Note not found
- Paths should start with `/`
- Don't include file extensions (`.md`, `.kvx`)
- Paths are case-sensitive

### Changes not visible
- Refresh the Browse page
- Close and reopen notes to see updates

### App:readNote returns nil
- Verify the note exists
- Check the path is correct
- Note might have a different extension

---

## Quick Reference

### Note Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `App:readNote(path)` | string | string or nil | Read note content |
| `App:writeNote(path, content)` | string, string | boolean | Create/update note |
| `App:deleteNote(path)` | string | boolean | Delete a note |
| `App:findNotes(pattern)` | string | table | Search notes by pattern |
| `App:getRecentNotes(count)` | number | table | Get N recent notes |
| `App:getNotesOlderThan(days)` | number | table | Get stale notes |
| `App:getAllNotes()` | none | table | List all notes |
| `App:createFolder(path)` | string | boolean | Create folder structure |
| `App:moveNote(from, to)` | string, string | boolean | Move/rename note |
| `App:getStats()` | none | table | Get {totalNotes, totalFolders} |
| `App:log(message)` | string | none | Log to console |
| `App:notify(message)` | string | none | Show notification |

### Calendar Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `App:getCalendarEvents()` | none | table | Get all calendar events |
| `App:getEventsForDate(year, month, day)` | number, number, number | table | Get events for specific date |
| `App:getEventsForMonth(year, month)` | number, number | table | Get all events in a month |
| `App:addCalendarEvent(title, year, month, day, options)` | string, number, number, number, table | string or nil | Create event, returns ID |
| `App:updateCalendarEvent(id, updates)` | string, table | boolean | Update existing event |
| `App:deleteCalendarEvent(id)` | string | boolean | Delete an event |
| `App:completeTask(id, completed)` | string, boolean | boolean | Mark task complete/incomplete |

**Calendar Event Options (for addCalendarEvent):**
```lua
{
    description = "Event description",
    startHour = 9,        -- 0-23
    startMinute = 30,     -- 0-59
    endHour = 10,
    endMinute = 0,
    type = "event",       -- "event", "task", or "reminder"
    colorHex = "#4CAF50", -- Hex color code
    isAllDay = false,     -- All-day event flag
    repeatType = "none"   -- "none", "daily", "weekly", "monthly", "yearly"
}
```

**Calendar Event Fields (returned from get functions):**
```lua
{
    id = "abc123",
    title = "Meeting",
    description = "Team sync",
    year = 2025, month = 1, day = 15,
    startHour = 9, startMinute = 30,
    endHour = 10, endMinute = 0,
    type = "event",       -- or "task", "reminder"
    isAllDay = false,
    isCompleted = false,  -- For tasks
    colorHex = "#4CAF50"
}
```

### Productivity Timer Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `App:getTimerStats()` | none | table | Get productivity statistics |
| `App:getTimerState()` | none | table | Get current timer state |
| `App:startTimer(minutes, sessionType)` | number, string | boolean | Start a focus session |
| `App:pauseTimer()` | none | boolean | Pause current session |
| `App:resumeTimer()` | none | boolean | Resume paused session |
| `App:stopTimer()` | none | boolean | Stop and reset timer |
| `App:getSessionHistory(days)` | number | table | Get focus time per day |

**Timer State Fields:**
```lua
{
    state = "running",      -- "idle", "running", "paused", "break"
    isRunning = true,
    isPaused = false,
    sessionType = "focus",  -- "focus", "deepWork", "sprint", "meeting", "study", "workout"
    remainingMinutes = 20.5,
    totalMinutes = 25,
    currentCycle = 2,
    totalCycles = 4
}
```

**Timer Stats Fields:**
```lua
{
    todayFocusMinutes = 90,
    todaySessions = 3,
    totalFocusMinutes = 2400,
    totalSessions = 120,
    completedSessions = 100,
    completionRate = 0.83,
    currentStreak = 5,
    longestStreak = 14
}
```

**Session Types:**
- `"focus"` - Standard focus session
- `"deepWork"` - Deep work session
- `"sprint"` - Quick sprint session
- `"meeting"` - Meeting timer
- `"study"` - Study session
- `"workout"` - Exercise timer
