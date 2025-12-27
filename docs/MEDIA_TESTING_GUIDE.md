# Media Features Manual Testing Guide

This document provides comprehensive manual testing instructions for the media embedding features in Kivixa. Follow these tests to ensure all functionality works correctly on both Windows and Android platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Image Upload and Display Tests](#image-upload-and-display-tests)
3. [Video Upload and Display Tests](#video-upload-and-display-tests)
4. [Resize and Transform Tests](#resize-and-transform-tests)
5. [Drag and Move Tests](#drag-and-move-tests)
6. [Comment System Tests](#comment-system-tests)
7. [Local Path Link Tests](#local-path-link-tests)
8. [Web Image URL Tests](#web-image-url-tests)
9. [Large Image Preview Tests](#large-image-preview-tests)
10. [Settings Configuration Tests](#settings-configuration-tests)
11. [Performance Tests](#performance-tests)
12. [Cross-Platform Tests](#cross-platform-tests)
13. [Edge Case Tests](#edge-case-tests)

---

## Prerequisites

Before testing, ensure you have:

1. **Test Images**: Prepare various images:
   - Small image (< 500KB, 800x600)
   - Medium image (1-5MB, 1920x1080)
   - Large image (> 5MB, 4000x3000)
   - Various formats: PNG, JPG, GIF, WebP, BMP

2. **Test Videos**: Prepare various videos:
   - Short video (< 30 seconds)
   - Medium video (1-5 minutes)
   - Various formats: MP4, MOV, WebM

3. **Web URLs**: Have accessible web image URLs ready:
   - https://picsum.photos/800/600 (random image)
   - https://via.placeholder.com/500x300.png (placeholder)

4. **Local Paths**: Know absolute paths to test files:
   - Windows: `C:\Users\YourName\Pictures\test.jpg`
   - Android: `/storage/emulated/0/Pictures/test.jpg`

---

## Image Upload and Display Tests

### Test 1.1: Upload Image via File Picker

**Steps:**
1. Open a new Markdown file
2. Click the Image icon in the toolbar
3. Select "Local File" option
4. Click "Choose Image" button
5. Select an image file from device storage
6. Enter optional alt text
7. Click "Insert"

**Expected Results:**
- ✅ File picker opens and shows images
- ✅ Selected image is copied to app storage
- ✅ Image markdown syntax is inserted at cursor position
- ✅ Image displays correctly in preview mode
- ✅ Image displays correctly in split view

---

### Test 1.2: Upload Image via URL

**Steps:**
1. Open a new Markdown file
2. Click the Image icon in the toolbar
3. Select "URL" option
4. Enter a valid image URL
5. Enter optional alt text
6. Click "Insert"

**Expected Results:**
- ✅ Image markdown with URL is inserted
- ✅ Image loads from web in preview
- ✅ Loading indicator shows during fetch
- ✅ Image displays after loading completes

---

### Test 1.3: Multiple Images in Document

**Steps:**
1. Insert 5-10 images in a single document
2. Mix local and web images
3. Scroll through the document
4. Switch between Edit/Preview/Split modes

**Expected Results:**
- ✅ All images display correctly
- ✅ No lag when scrolling
- ✅ Images maintain correct positions
- ✅ Mode switching is smooth

---

## Video Upload and Display Tests

### Test 2.1: Upload Local Video

**Steps:**
1. Open a new Markdown file
2. Click the Video icon in the toolbar
3. Select "Local File" option
4. Choose a video file
5. Click "Insert"

**Expected Results:**
- ✅ Video is copied to app storage
- ✅ Video player widget appears
- ✅ Play button is visible
- ✅ Video thumbnail/preview shows

---

### Test 2.2: Video Playback Controls

**Steps:**
1. Click play button on embedded video
2. Test pause/resume functionality
3. Drag progress bar to seek
4. Click volume icon for volume control
5. Adjust volume slider
6. Click fullscreen button

**Expected Results:**
- ✅ Play/pause toggles correctly
- ✅ Progress bar updates during playback
- ✅ Seeking works smoothly
- ✅ Volume control adjusts audio
- ✅ Fullscreen mode activates

---

### Test 2.3: Video Auto-Hide Controls

**Steps:**
1. Start video playback
2. Wait 3 seconds without interaction
3. Move mouse over video (Windows) or tap (Android)
4. Pause the video

**Expected Results:**
- ✅ Controls fade out after 3 seconds during playback
- ✅ Controls reappear on hover/tap
- ✅ Controls stay visible when paused

---

## Resize and Transform Tests

### Test 3.1: Image Selection and Handles

**Steps:**
1. Insert an image in a document
2. Click on the image
3. Observe the selection state

**Expected Results:**
- ✅ Border appears around image when selected
- ✅ 8 resize handles appear (4 corners + 4 edges)
- ✅ Rotation handle appears at top
- ✅ Move handle (4-way arrow) appears in center
- ✅ Control overlay appears (preview, comment, delete)

---

### Test 3.2: Corner Resize (Aspect Ratio)

**Steps:**
1. Select an image
2. Drag a corner handle (e.g., bottom-right)
3. Observe dimensions while dragging
4. Release to confirm

**Expected Results:**
- ✅ Image resizes from the corner
- ✅ Opposite corner stays fixed
- ✅ Markdown syntax updates with new width/height values
- ✅ Minimum size constraint is enforced (50x50)

---

### Test 3.3: Shift + Corner Resize (Lock Aspect Ratio)

**Steps:**
1. Select an image with known dimensions (e.g., 400x300)
2. Hold Shift key
3. Drag a corner handle
4. Release

**Expected Results:**
- ✅ Aspect ratio is maintained during resize
- ✅ Image scales proportionally
- ✅ Width/Height ratio stays constant

---

### Test 3.4: Edge Resize (Single Dimension)

**Steps:**
1. Select an image
2. Drag a left/right edge handle
3. Drag a top/bottom edge handle

**Expected Results:**
- ✅ Only width changes when dragging left/right
- ✅ Only height changes when dragging top/bottom
- ✅ Image may distort (aspect ratio not locked)

---

### Test 3.5: Rotation

**Steps:**
1. Select an image
2. Drag the rotation handle at top
3. Rotate clockwise and counter-clockwise
4. Try to align to 0°, 45°, 90°, 180°, 270°

**Expected Results:**
- ✅ Image rotates smoothly
- ✅ Rotation snaps to 15° increments
- ✅ Markdown syntax updates with rotation value
- ✅ Rotation persists after deselection

---

### Test 3.6: Markdown Syntax Updates

**Steps:**
1. Insert image: `![Alt](path.jpg)`
2. Resize to 300x200
3. Rotate 45°
4. Check Edit mode

**Expected Results:**
- ✅ Syntax becomes: `![Alt|width=300,height=200,rotation=45.0](path.jpg)`
- ✅ All parameters are preserved on save
- ✅ Reopening file restores all transforms

---

## Drag and Move Tests

### Test 4.1: Move via Pan Gesture

**Steps:**
1. Select an image
2. Drag from the image body (not handles)
3. Move to different position
4. Release

**Expected Results:**
- ✅ Image moves with cursor/finger
- ✅ Shadow appears during drag
- ✅ Position offset updates in markdown (x, y)

---

### Test 4.2: Move via 4-Way Arrow Handle

**Steps:**
1. Select an image
2. Locate the center move handle (4-way arrow icon)
3. Drag from this handle specifically
4. Move image to new position

**Expected Results:**
- ✅ Move cursor appears when hovering handle
- ✅ Image moves smoothly
- ✅ Same behavior as pan gesture

---

### Test 4.3: Position Persistence

**Steps:**
1. Move an image to position (100, 50)
2. Deselect the image
3. Close and reopen the file

**Expected Results:**
- ✅ Markdown contains `x=100.0,y=50.0`
- ✅ Position is restored on file open
- ✅ Image appears at saved position

---

## Comment System Tests

### Test 5.1: Add Comment (Windows)

**Steps:**
1. Insert an image
2. Hover mouse over the image
3. Wait for comment overlay (500ms delay)
4. Click "Add comment" button
5. Enter comment text
6. Click "Save"

**Expected Results:**
- ✅ Comment box appears after hover delay
- ✅ Edit mode allows text entry
- ✅ Comment is saved to markdown syntax
- ✅ Comment icon appears after saving

---

### Test 5.2: Add Comment (Android)

**Steps:**
1. Insert an image
2. Select the image
3. Tap comment icon in control overlay
4. Enter comment text
5. Tap "Save"

**Expected Results:**
- ✅ Comment dialog opens on tap
- ✅ Soft keyboard appears
- ✅ Comment is saved correctly
- ✅ Comment icon visible after saving

---

### Test 5.3: View Comment (Windows)

**Steps:**
1. Hover over image with existing comment
2. Wait for comment to appear

**Expected Results:**
- ✅ Comment box shows after 500ms
- ✅ Comment text is displayed
- ✅ Edit and Delete buttons visible
- ✅ Box hides when mouse leaves

---

### Test 5.4: Edit Comment

**Steps:**
1. Open comment box (hover/tap)
2. Click edit icon
3. Modify text
4. Save

**Expected Results:**
- ✅ Edit mode activates
- ✅ Existing text is editable
- ✅ Changes persist after save
- ✅ Markdown updates with encoded comment

---

### Test 5.5: Delete Comment

**Steps:**
1. Open comment box
2. Click delete icon
3. Confirm deletion

**Expected Results:**
- ✅ Comment is removed
- ✅ Markdown parameter removed
- ✅ Comment icon no longer appears

---

### Test 5.6: Comment URL Encoding

**Steps:**
1. Add comment with special characters: `Hello "World" & <Test>`
2. Check raw markdown

**Expected Results:**
- ✅ Special characters are URL-encoded
- ✅ Comment displays correctly after parsing
- ✅ No markdown syntax corruption

---

## Local Path Link Tests

### Test 6.1: Insert Absolute Path Reference

**Steps:**
1. In markdown, type: `![Photo](C:\Users\Me\Photos\image.jpg)` (Windows)
   Or: `![Photo](/home/user/photos/image.jpg)` (Linux/Android)
2. Switch to preview mode

**Expected Results:**
- ✅ Image loads from the specified path
- ✅ Image displays correctly
- ✅ Error message if file doesn't exist

---

### Test 6.2: Local Path with Resize

**Steps:**
1. Insert absolute path reference
2. Select the image in preview
3. Resize and rotate
4. Check that transforms work

**Expected Results:**
- ✅ Same resize/rotate behavior as uploaded images
- ✅ Transforms persist in markdown
- ✅ Original file is not modified

---

### Test 6.3: Invalid Path Handling

**Steps:**
1. Insert: `![Missing](C:\nonexistent\file.png)`
2. Switch to preview

**Expected Results:**
- ✅ Error placeholder appears
- ✅ "File not found" message displayed
- ✅ Retry button available
- ✅ No crash or freeze

---

## Web Image URL Tests

### Test 7.1: Insert Web Image URL

**Steps:**
1. Insert: `![Web](https://picsum.photos/800/600)`
2. Switch to preview

**Expected Results:**
- ✅ Loading indicator appears
- ✅ Image fetches from web
- ✅ Image displays after loading
- ✅ Transforms work on web images

---

### Test 7.2: Web Image with Dimensions

**Steps:**
1. Insert: `![Web|width=400,height=300](https://picsum.photos/800/600)`
2. Preview the image

**Expected Results:**
- ✅ Image displays at 400x300
- ✅ Resizing updates dimensions
- ✅ Original URL preserved

---

### Test 7.3: Invalid URL Handling

**Steps:**
1. Insert: `![Bad](https://invalid.url/nonexistent.jpg)`
2. Preview the document

**Expected Results:**
- ✅ Error placeholder appears after timeout
- ✅ "Failed to load" message
- ✅ Retry button available
- ✅ No app crash

---

### Test 7.4: Web Image Mode - Download Locally

**Steps:**
1. Go to Settings > Media Settings
2. Set "Web Image Mode" to "Download Locally"
3. Insert a new web image URL
4. Disconnect from internet
5. Reopen the file

**Expected Results:**
- ✅ Image loads initially from web
- ✅ Image is cached locally
- ✅ Offline access works
- ✅ Cache size shows in settings

---

### Test 7.5: Web Image Mode - Fetch on Demand

**Steps:**
1. Go to Settings > Media Settings
2. Set "Web Image Mode" to "Fetch on Demand"
3. Insert a new web image URL
4. Close and reopen file
5. Observe loading behavior

**Expected Results:**
- ✅ Image fetches from web each time
- ✅ No local cache created
- ✅ Memory cache used during session
- ✅ Offline shows placeholder/error

---

### Test 7.6: Clear Web Cache

**Steps:**
1. Download several web images
2. Go to Settings > Media Settings
3. Observe cache size
4. Click "Clear" button

**Expected Results:**
- ✅ Cache size shows correctly
- ✅ Clearing shows progress
- ✅ Cache size becomes 0 after clear
- ✅ Previously cached images need re-download

---

## Large Image Preview Tests

### Test 8.1: Auto-Detect Large Image

**Steps:**
1. Insert an image larger than 2000x2000 pixels
2. Select the image
3. Observe UI options

**Expected Results:**
- ✅ Preview mode toggle appears
- ✅ Full-size display may be slow
- ✅ App suggests preview mode for large images

---

### Test 8.2: Enable Preview Mode

**Steps:**
1. Insert large image (4000x3000)
2. Double-click to toggle preview mode
   Or click preview toggle button
3. Observe the preview container

**Expected Results:**
- ✅ Image displays in constrained container
- ✅ Container size from settings (default 300px)
- ✅ Minimap appears showing visible region
- ✅ Control buttons visible (toggle minimap, reset zoom, exit)

---

### Test 8.3: Pan Within Preview

**Steps:**
1. Enable preview mode on large image
2. Drag within the preview container
3. Pan to see different parts of image

**Expected Results:**
- ✅ Image pans smoothly
- ✅ Minimap updates to show visible region
- ✅ Scroll position saves to markdown
- ✅ Position restored on file reopen

---

### Test 8.4: Zoom Within Preview

**Steps:**
1. Enable preview mode
2. Pinch to zoom (touch) or scroll wheel (mouse)
3. Zoom in and out

**Expected Results:**
- ✅ Zoom works smoothly
- ✅ Min zoom: 0.5x
- ✅ Max zoom: 4.0x
- ✅ Minimap shows zoom level

---

### Test 8.5: Reset Zoom

**Steps:**
1. Zoom and pan in preview mode
2. Click "Reset zoom" button

**Expected Results:**
- ✅ View resets to default
- ✅ Zoom returns to 1.0x
- ✅ Position resets to origin

---

### Test 8.6: Exit Preview Mode

**Steps:**
1. Enable preview mode
2. Click exit preview button
3. Or double-click image

**Expected Results:**
- ✅ Returns to full interactive mode
- ✅ All transforms preserved
- ✅ Preview mode flag cleared in markdown

---

### Test 8.7: Preview Container Resize

**Steps:**
1. Enable preview mode
2. Select the preview container
3. Resize using handles

**Expected Results:**
- ✅ Container resizes
- ✅ Preview dimensions update (pw, ph in markdown)
- ✅ Image content adjusts

---

## Settings Configuration Tests

### Test 9.1: Media Settings Page

**Steps:**
1. Navigate to Settings
2. Find "Media Settings" section

**Expected Results:**
- ✅ Section title visible
- ✅ All options listed:
  - Web Image Mode
  - Delete Media with Notes
  - Large Image Preview Size
- ✅ Help tips displayed

---

### Test 9.2: Delete Media with Notes Setting

**Steps:**
1. Enable "Delete Media with Notes"
2. Upload an image to a note
3. Delete the note
4. Check app storage directory

**Expected Results:**
- ✅ Uploaded media file is deleted
- ✅ Thumbnail is also deleted
- ✅ Storage space freed

---

### Test 9.3: Preview Size Slider

**Steps:**
1. Adjust "Large Image Preview Size" slider
2. Values range 100-500px
3. Apply changes

**Expected Results:**
- ✅ Slider shows current value
- ✅ Changes apply to new preview containers
- ✅ Setting persists across app restart

---

## Performance Tests

### Test 10.1: Multiple Images Performance

**Steps:**
1. Create document with 20+ images
2. Scroll through quickly
3. Monitor for lag/stutter

**Expected Results:**
- ✅ Smooth scrolling (60fps)
- ✅ No visible stutter
- ✅ Images load progressively
- ✅ Memory usage stays reasonable

---

### Test 10.2: Large File Performance

**Steps:**
1. Insert 10MB+ image
2. Resize multiple times
3. Rotate back and forth
4. Save and reopen file

**Expected Results:**
- ✅ Resize is smooth
- ✅ Rotation is smooth
- ✅ No memory crash
- ✅ File operations complete

---

### Test 10.3: Video Performance

**Steps:**
1. Embed multiple videos
2. Play video while scrolling
3. Switch between videos

**Expected Results:**
- ✅ Only visible videos load
- ✅ Non-visible videos pause
- ✅ Smooth switching
- ✅ No audio overlap

---

### Test 10.4: Memory Cleanup

**Steps:**
1. Open document with many images
2. Navigate away
3. Return to document
4. Check memory usage

**Expected Results:**
- ✅ Memory released when navigating away
- ✅ Cache properly managed
- ✅ No memory leaks

---

## Cross-Platform Tests

### Test 11.1: Windows-Specific Features

**Steps:**
1. Test hover behavior for comments
2. Test right-click context menus
3. Test keyboard shortcuts (Shift, Escape)
4. Test mouse cursor changes on handles

**Expected Results:**
- ✅ Hover triggers after delay
- ✅ Cursor changes appropriately
- ✅ Shift locks aspect ratio
- ✅ Escape deselects

---

### Test 11.2: Android-Specific Features

**Steps:**
1. Test tap-based comment system
2. Test touch gestures for resize/rotate
3. Test pinch-to-zoom
4. Test long-press alternatives

**Expected Results:**
- ✅ Tap shows comment icon
- ✅ Touch gestures work
- ✅ Pinch zoom works
- ✅ UI adapts to touch

---

### Test 11.3: File Path Compatibility

**Steps:**
1. Create note with images on Windows
2. Sync/transfer to Android (if applicable)
3. Check path resolution

**Expected Results:**
- ✅ App storage paths resolve correctly
- ✅ Web URLs work on both
- ✅ Absolute local paths platform-specific

---

## Edge Case Tests

### Test 12.1: Empty Image Path

**Steps:**
1. Manually create: `![Alt]()`
2. Preview document

**Expected Results:**
- ✅ Error placeholder shown
- ✅ No crash
- ✅ Clear error message

---

### Test 12.2: Very Small Resize

**Steps:**
1. Try resizing image to 10x10
2. Check enforcement

**Expected Results:**
- ✅ Minimum 50x50 enforced
- ✅ Resize stops at minimum
- ✅ No visual glitches

---

### Test 12.3: Very Large Resize

**Steps:**
1. Try resizing to 5000x5000
2. Check enforcement

**Expected Results:**
- ✅ Maximum 2000x2000 enforced
- ✅ Resize stops at maximum
- ✅ App remains responsive

---

### Test 12.4: Corrupted Image File

**Steps:**
1. Insert reference to corrupted image file
2. Preview document

**Expected Results:**
- ✅ Error placeholder shown
- ✅ No crash
- ✅ Other content loads normally

---

### Test 12.5: Network Interruption

**Steps:**
1. Start loading web image
2. Disconnect network mid-load
3. Reconnect and retry

**Expected Results:**
- ✅ Loading handles timeout
- ✅ Error shown appropriately
- ✅ Retry works after reconnect

---

### Test 12.6: Rapid Selection Toggle

**Steps:**
1. Click image rapidly multiple times
2. Observe selection state

**Expected Results:**
- ✅ Selection toggles correctly
- ✅ No visual glitches
- ✅ Handles appear/disappear smoothly

---

### Test 12.7: Concurrent Transforms

**Steps:**
1. Select image
2. Start resizing
3. While resizing, try rotating
4. Try moving while resizing

**Expected Results:**
- ✅ Only one transform at a time
- ✅ Gestures don't conflict
- ✅ State remains consistent

---

## Test Checklist Summary

| Category | Total Tests | Passed | Failed | Notes |
|----------|-------------|--------|--------|-------|
| Image Upload | 3 | | | |
| Video Upload | 3 | | | |
| Resize/Transform | 6 | | | |
| Drag/Move | 3 | | | |
| Comments | 6 | | | |
| Local Paths | 3 | | | |
| Web Images | 6 | | | |
| Large Preview | 7 | | | |
| Settings | 3 | | | |
| Performance | 4 | | | |
| Cross-Platform | 3 | | | |
| Edge Cases | 7 | | | |
| **TOTAL** | **54** | | | |

---

## Known Issues and Workarounds

Document any discovered issues here:

1. Issue: [Description]
   - Workaround: [Solution]
   - Status: [Open/Fixed]

---

## Reporting Bugs

When reporting issues found during testing:

1. **Test ID**: Which test failed (e.g., Test 3.5)
2. **Platform**: Windows/Android
3. **Steps to Reproduce**: Exact steps taken
4. **Expected Result**: What should have happened
5. **Actual Result**: What actually happened
6. **Screenshots/Logs**: If applicable
7. **Device Info**: OS version, device model

---

*Last Updated: December 25, 2025*
*Version: 1.0*
