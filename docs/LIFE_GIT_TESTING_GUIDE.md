# Life Git Testing Guide

This guide provides step-by-step instructions for testing all Life Git features in Kivixa.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Accessing Life Git Features](#accessing-life-git-features)
3. [Testing Manual Commits](#testing-manual-commits)
4. [Testing Time Travel](#testing-time-travel)
5. [Testing Version History Page](#testing-version-history-page)
6. [Testing Full Backup](#testing-full-backup)
7. [Testing Garbage Collection](#testing-garbage-collection)
8. [Verifying Storage Statistics](#verifying-storage-statistics)

---

## Prerequisites

Before testing, ensure that:
1. Kivixa is running on Windows
2. You have created at least one note (Markdown or Text file)
3. The app has write permissions to the documents directory

---

## Accessing Life Git Features

### From Settings Page

1. **Launch Kivixa**
2. **Navigate to Settings:**
   - Click the **Settings** tab in the bottom navigation bar (gear icon)
   - Or use the navigation rail on larger screens
3. **Scroll down to "Extensions" section** (near the bottom, after "Advanced" section)
4. You'll see three items:
   - **Lua Plugins** - Opens the plugin management page
   - **Version History** - Opens the Life Git history page
   - **Life Git Storage** card - Shows storage statistics (commits, snapshots, size)

### From Within an Editor

1. **Open any Markdown file (.md):**
   - Go to **Browse** tab
   - Click on any markdown file, or create one:
     - Tap the **+** button
     - Select **Markdown Note**
     - Give it a name like "Test Note"
   
2. **In the Markdown Editor toolbar (top-right), you'll see:**
   - **Commit button** (commit icon) - Creates a version snapshot in Life Git
   - **History button** (clock icon) - Opens Time Travel mode
   - **Manage History button** (clock with lines icon) - Opens full history page

3. **Open any Text Document (.kvtx):**
   - Go to **Browse** tab
   - Tap the **+** button
   - Select **Text Document**
   - Same toolbar buttons appear

---

## Testing Manual Commits

Life Git creates version snapshots when you click the **Commit** button. This gives you control over when versions are saved, preventing unnecessary commits from auto-save.

### Step 1: Create a New Markdown Note

1. Go to **Browse** → **+** → **Markdown Note**
2. Name it: `test-version-control`
3. Wait for the editor to open

### Step 2: Add Initial Content

1. Type the following content:
   ```markdown
   # My Test Note
   
   This is version 1 of my note.
   ```
2. Click the **Commit** button (commit icon) in the toolbar
3. A snackbar shows "Version committed"
4. The content is now saved in version history

### Step 3: Make Changes and Commit Again

1. Add more content:
   ```markdown
   # My Test Note
   
   This is version 1 of my note.
   
   ## Added in Version 2
   
   This paragraph was added later.
   ```
2. Click the **Commit** button again
3. A new version snapshot is created

### Step 4: Verify Commits Were Created

1. Click the **Manage History** button (clock with lines icon) in the toolbar
2. You should see at least 2 commits in the history list
3. Each commit shows:
   - Short hash (e.g., `a1b2c3d4`)
   - Message (e.g., "Manual commit: test-version-control")
   - Age (e.g., "Just now", "2 minutes ago")

### Note: Auto-Save vs Manual Commit

- **Auto-save** still works: Your content is saved to disk after 2 seconds of inactivity
- **Manual commit** creates a version: Only when you click the Commit button
- This prevents cluttering version history with tiny incremental changes

---

## Testing Time Travel

Time Travel lets you preview and restore previous versions of a file.

### Step 1: Open Time Travel Mode

1. Open a file that has multiple versions (from the previous test)
2. Click the **History** button (clock icon) in the editor toolbar
3. The **Time Travel slider** appears at the top of the editor

### Step 2: Navigate Through History

1. The slider shows:
   - Left end: Oldest version
   - Right end: Current version (Now)
   - Hash badge showing current commit
   
2. **Drag the slider to the left** to go back in time
3. Watch the editor content change as you navigate
4. Below the slider, you'll see:
   - Commit message
   - Age of the commit

### Step 3: Preview Historical Version

1. Slide to any historical version
2. The editor now shows that version's content
3. You're in **read-only preview mode** - any changes you make won't affect history

### Step 4: Restore a Historical Version

1. Navigate to a version you want to restore
2. Click the **"Restore This"** button
3. The file content is restored to that version
4. A snackbar confirms "Restored version [hash]"
5. You can then click the **Commit** button to save this as a new version

### Step 5: Exit Time Travel Without Restoring

1. Open Time Travel mode again
2. Navigate to any historical version
3. Click the **X button** or **"Exit Time Travel"**
4. The editor returns to your current (live) version

---

## Testing Version History Page

The Version History page shows all commits across all files.

### Step 1: Access Version History

1. Go to **Settings** tab
2. Scroll to **Extensions** section
3. Click **"Version History"**

### Step 2: View All Commits

1. The page shows:
   - Total commits count
   - Total snapshots count
   - Total storage size
   - List of all commits (newest first)

2. Each commit displays:
   - Commit hash (monospace font)
   - Commit message
   - Timestamp
   - Number of files in that commit

### Step 3: Filter by File

1. Click on a specific commit
2. View the files that were changed in that commit
3. Click on a file to see its content at that point in time

### Step 4: Access File-Specific History

1. From the Markdown/Text editor, click **Manage History** (clock with lines)
2. This opens the Version History page **filtered to that specific file**
3. You'll only see commits that include changes to that file

---

## Testing Full Backup

Create a complete backup of all your notes.

### Step 1: Open Version History Page

1. Go to **Settings** → **Version History**

### Step 2: Create Full Backup

1. Click the **"Full Backup"** button in the app bar (or floating action button)
2. A dialog appears asking for a backup message
3. Enter: `Manual backup before cleanup`
4. Click **"Create Backup"**

### Step 3: Verify Backup

1. The new backup commit appears at the top of the list
2. It contains snapshots of ALL files in your notes directory
3. The message shows your custom backup message

---

## Testing Garbage Collection

Garbage Collection removes orphaned blobs that are no longer referenced by any commit.

### Step 1: Open Version History Page

1. Go to **Settings** → **Version History**

### Step 2: Run Garbage Collection

1. Click the **menu button** (three dots) in the app bar
2. Select **"Garbage Collection"**
3. A dialog explains what GC does
4. Click **"Run GC"**

### Step 3: View Results

1. A snackbar shows how many orphaned blobs were removed
2. Example: "Removed 3 orphaned blobs"
3. If no orphans exist: "No orphaned blobs found"

---

## Verifying Storage Statistics

### From Settings Page

1. Go to **Settings** tab
2. Scroll to **Extensions** section
3. Look at the **"Life Git Storage"** card:
   - **Commits**: Total number of commits created
   - **Snapshots**: Total number of file snapshots (blobs)
   - **Size**: Total storage used (e.g., "2.5 MB")

### From Version History Page

1. Go to **Settings** → **Version History**
2. The header shows the same statistics:
   - Commits count
   - Snapshots count
   - Storage size

---

## Troubleshooting

### "No history available" in Time Travel

**Cause**: No versions have been committed yet.

**Solution**:
1. Click the Commit button in the toolbar to create your first version
2. Try Time Travel again

### Commits not appearing

**Cause**: You haven't clicked the Commit button.

**Solution**:
1. Make a change to the file
2. Click the **Commit** button in the toolbar
3. Check history to see the new commit

### Storage size seems high

**Cause**: Many versions accumulate over time.

**Solution**:
1. Run Garbage Collection (Settings → Version History → Menu → Garbage Collection)
2. This removes orphaned blobs but keeps all referenced snapshots

### Time Travel slider not responding

**Cause**: History might not be fully loaded.

**Solution**:
1. Wait for the loading indicator to disappear
2. If it shows "No history available", save the file first

---

## Test Checklist

Use this checklist to verify all features work correctly:

- [ ] **Settings Page Access**
  - [ ] "Lua Plugins" button navigates to plugins page
  - [ ] "Version History" button navigates to history page
  - [ ] "Life Git Storage" card shows statistics

- [ ] **Manual Commits (Markdown)**
  - [ ] New markdown file created
  - [ ] Content added
  - [ ] Commit button clicked
  - [ ] Snapshot created (check history)

- [ ] **Manual Commits (Text)**
  - [ ] New text document created
  - [ ] Content added
  - [ ] Commit button clicked
  - [ ] Snapshot created

- [ ] **Time Travel (Markdown)**
  - [ ] Time Travel button visible in toolbar
  - [ ] Commit button visible in toolbar
  - [ ] Slider appears when Time Travel clicked
  - [ ] Slider navigates through history
  - [ ] Content updates as slider moves
  - [ ] "Restore This" works correctly
  - [ ] Exit button returns to current version

- [ ] **Time Travel (Text)**
  - [ ] Same as Markdown tests above

- [ ] **Version History Page**
  - [ ] Accessible from Settings
  - [ ] Shows all commits
  - [ ] Shows storage statistics
  - [ ] Commit details are displayed

- [ ] **Full Backup**
  - [ ] Backup button accessible
  - [ ] Custom message can be entered
  - [ ] Backup commit created with all files

- [ ] **Garbage Collection**
  - [ ] GC option accessible from menu
  - [ ] Runs without errors
  - [ ] Shows result count

---

## Technical Details

### Storage Location

Life Git data is stored in:
```
[Documents Directory]/.lifegit/
├── objects/           # Content-addressable blobs (SHA-256)
│   ├── a1/
│   │   └── b2c3d4...  # Blob files
│   └── ...
├── commits/           # Commit JSON files
│   └── [hash]         # Individual commit files
├── refs/
│   └── main           # Branch reference
└── HEAD               # Current branch pointer
```

### Commit Structure

Each commit contains:
```json
{
  "hash": "sha256-hash-of-commit",
  "message": "Auto-save: filename",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "parentHash": "previous-commit-hash",
  "snapshots": [
    {
      "path": "/path/to/file.md",
      "blobHash": "sha256-of-content",
      "exists": true,
      "modifiedAt": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

### Commit Timing

- **Auto-save**: Content saved to disk 2 seconds after last keystroke
- **Manual commit**: Creates version snapshot when Commit button is clicked
- **Commit creation**: One commit per Commit button press
