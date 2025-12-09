# Knowledge Graph Feature Testing Guide

This document provides detailed instructions for testing every feature of the Neural Knowledge Graph implementation.

## Prerequisites

1. **Flutter Environment**: Ensure Flutter is installed and configured
2. **Run the App**: `flutter run -d windows` (or your target platform)
3. **Navigate to Knowledge Graph**: Click "Knowledge Graph" in the left sidebar

---

## Test Suite Overview

| Category | Tests | Priority |
|----------|-------|----------|
| Demo Mode | 5 tests | High |
| Node Management | 12 tests | High |
| Link Management | 10 tests | High |
| Node Shapes | 6 tests | High |
| Link Styles | 8 tests | High |
| Navigation & Gestures | 8 tests | Medium |
| Physics Simulation | 4 tests | Medium |
| Visual Rendering | 6 tests | Medium |

---

## 1. Demo Mode Tests

### Test 1.1: Initial Demo Data Loading
**Steps:**
1. Open the Knowledge Graph page
2. Wait for the page to fully load

**Expected Results:**
- 5 hub nodes visible (Recipes, Code, Ideas, Research, Projects)
- 7 note nodes visible (scattered around hubs)
- Edges connecting notes to their hub topics with labels
- Node/link count badge shows "12 nodes · 8 links"

### Test 1.2: Hub Node Identification
**Steps:**
1. Look for larger nodes with different shapes
2. Identify each hub by shape and color

**Expected Results:**
- Recipes hub: Hexagon shape
- Code hub: Diamond shape
- Ideas hub: Star shape
- Research hub: Square shape
- Projects hub: Circle shape

### Test 1.3: Demo Link Labels
**Steps:**
1. Observe the edges between nodes
2. Look for text labels on edges

**Expected Results:**
- Topic links show "belongs to" label
- Cross-links show "related" label
- Labels have white background for readability

### Test 1.4: Reload Demo Data
**Steps:**
1. Click the overflow menu (⋮)
2. Select "Reload Demo"

**Expected Results:**
- Graph resets to initial demo state
- All custom nodes/links are removed
- Demo data reappears

### Test 1.5: Clear All
**Steps:**
1. Click the overflow menu (⋮)
2. Select "Clear All"
3. Confirm in the dialog

**Expected Results:**
- All nodes and links are removed
- Empty state message appears
- "Load Demo" button available

---

## 2. Node Management Tests

### Test 2.1: Enter Add Node Mode
**Steps:**
1. Click the + button in the app bar
2. Observe the overlay

**Expected Results:**
- "Tap to place node" overlay appears
- Touch icon visible
- Close button (X) available

### Test 2.2: Add Node Dialog
**Steps:**
1. Enter add node mode
2. Tap anywhere on the canvas

**Expected Results:**
- Add Node dialog opens
- Title field (required)
- Description field (optional)
- Node Type selector (Note/Hub/Idea)
- Shape selector (6 shapes)
- Color selector (8 colors)

### Test 2.3: Create Note Node
**Steps:**
1. Open Add Node dialog
2. Enter title: "My Test Note"
3. Enter description: "Test description"
4. Select type: "Note"
5. Select shape: Circle
6. Select color: Blue
7. Click "Add"

**Expected Results:**
- Dialog closes
- New node appears at tap location
- Node has correct title, shape, color
- Snackbar confirms "Added: My Test Note"

### Test 2.4: Create Hub Node
**Steps:**
1. Add a node with type "Hub"

**Expected Results:**
- Hub node is larger than note nodes
- Hub has specified shape and color

### Test 2.5: Create Idea Node
**Steps:**
1. Add a node with type "Idea"

**Expected Results:**
- Idea node appears with specified properties

### Test 2.6: Title Required Validation
**Steps:**
1. Open Add Node dialog
2. Leave title empty
3. Click "Add"

**Expected Results:**
- Snackbar shows "Title is required"
- Dialog remains open

### Test 2.7: Select Node
**Steps:**
1. Tap on any node

**Expected Results:**
- Node shows orange selection ring
- Node details panel appears at bottom
- Shows title, type, shape, link count

### Test 2.8: Edit Node
**Steps:**
1. Select a node
2. Click "Edit" button in details panel

**Expected Results:**
- Edit Node dialog opens
- Current values pre-filled
- Can modify title, description, shape, color

### Test 2.9: Save Node Edits
**Steps:**
1. Edit a node's title and color
2. Click "Save"

**Expected Results:**
- Dialog closes
- Node updates with new values
- Details panel shows updated info

### Test 2.10: Focus on Node
**Steps:**
1. Pan far away from nodes
2. Select a node
3. Click "Focus" button

**Expected Results:**
- Viewport pans to center on the node

### Test 2.11: Delete Node
**Steps:**
1. Select a node
2. Click "Delete" button

**Expected Results:**
- Node is removed from graph
- All connected links are also removed
- Snackbar confirms deletion

### Test 2.12: Cancel Add Node Mode
**Steps:**
1. Enter add node mode
2. Click the X button in overlay

**Expected Results:**
- Overlay disappears
- Normal interaction mode restored

---

## 3. Link Management Tests

### Test 3.1: Start Linking Mode
**Steps:**
1. Select a node
2. Click "Link" button in details panel

**Expected Results:**
- "Tap another node to link" overlay appears
- Source node has green glow

### Test 3.2: Add Link Dialog
**Steps:**
1. Start linking from a node
2. Tap another node

**Expected Results:**
- Add Link dialog opens
- Label field (optional)
- Line Thickness selector (Thin/Normal/Thick)
- Arrow Style selector (None/Single/Double)
- Color selector (optional)

### Test 3.3: Create Link with Label
**Steps:**
1. Create a link between two nodes
2. Enter label: "depends on"
3. Select Thick line
4. Select Single Arrow
5. Click "Add Link"

**Expected Results:**
- Link appears between nodes
- "depends on" label visible on link
- Arrow points to target node
- Link is thick

### Test 3.4: Create Link with Color
**Steps:**
1. Create a link and select a color

**Expected Results:**
- Link appears in selected color
- Arrow is also colored

### Test 3.5: Prevent Duplicate Links
**Steps:**
1. Create a link between Node A and Node B
2. Try to create another link between them

**Expected Results:**
- Snackbar shows "Link already exists"
- No duplicate link created

### Test 3.6: Cancel Linking Mode
**Steps:**
1. Start linking from a node
2. Tap on empty canvas or same node

**Expected Results:**
- "Linking cancelled" message
- Normal mode restored

### Test 3.7: Open Manage Links Dialog
**Steps:**
1. Click the link icon (🔗) in app bar

**Expected Results:**
- Manage Links dialog opens
- Lists all links with source → target
- Shows link labels if present
- Delete button for each link

### Test 3.8: Delete Specific Link
**Steps:**
1. Open Manage Links dialog
2. Click trash icon on a link

**Expected Results:**
- Link is removed from list
- Link disappears from graph
- "Link deleted" message

### Test 3.9: Clear All Links
**Steps:**
1. Open Manage Links dialog
2. Click "Clear All Links"
3. Confirm in dialog

**Expected Results:**
- All links are removed
- Nodes remain in place
- "All links cleared" message

### Test 3.10: Empty Links State
**Steps:**
1. Clear all links
2. Open Manage Links dialog

**Expected Results:**
- Shows "No links in the graph"
- "Clear All Links" button hidden

---

## 4. Node Shapes Tests

### Test 4.1: Circle Shape
**Steps:**
1. Create a node with Circle shape

**Expected Results:**
- Node renders as a perfect circle

### Test 4.2: Square Shape
**Steps:**
1. Create a node with Square shape

**Expected Results:**
- Node renders as a square

### Test 4.3: Diamond Shape
**Steps:**
1. Create a node with Diamond shape

**Expected Results:**
- Node renders as a rotated square (diamond)

### Test 4.4: Hexagon Shape
**Steps:**
1. Create a node with Hexagon shape

**Expected Results:**
- Node renders as a 6-sided polygon

### Test 4.5: Star Shape
**Steps:**
1. Create a node with Star shape

**Expected Results:**
- Node renders as a 5-pointed star

### Test 4.6: Rectangle Shape
**Steps:**
1. Create a node with Rectangle shape

**Expected Results:**
- Node renders as a horizontal rectangle (wider than tall)

---

## 5. Link Styles Tests

### Test 5.1: Thin Line Style
**Steps:**
1. Create a link with Thin style

**Expected Results:**
- Link appears with 1px width

### Test 5.2: Normal Line Style
**Steps:**
1. Create a link with Normal style

**Expected Results:**
- Link appears with 2px width (default)

### Test 5.3: Thick Line Style
**Steps:**
1. Create a link with Thick style

**Expected Results:**
- Link appears with 4px width

### Test 5.4: No Arrow Style
**Steps:**
1. Create a link with None arrow style

**Expected Results:**
- Link is a plain line with no arrows

### Test 5.5: Single Arrow Style
**Steps:**
1. Create a link with Single Arrow style

**Expected Results:**
- Arrow appears at target node end
- Arrow points into the target

### Test 5.6: Double Arrow Style
**Steps:**
1. Create a link with Double Arrow style

**Expected Results:**
- Arrows at both ends
- Bidirectional relationship shown

### Test 5.7: Link Label Display
**Steps:**
1. Create links with labels
2. Zoom in to at least 50%

**Expected Results:**
- Labels visible on links
- White background behind text
- Text is readable

### Test 5.8: Link Label Zoom Scaling
**Steps:**
1. Create a link with label
2. Zoom out below 50%

**Expected Results:**
- Labels may hide at very low zoom
- Improves performance

---

## 6. Navigation & Gesture Tests

### Test 6.1: Pan Canvas
**Steps:**
1. Click and drag on empty canvas area

**Expected Results:**
- Entire graph moves with drag
- Smooth panning

### Test 6.2: Zoom In Button
**Steps:**
1. Click zoom in (+) button multiple times

**Expected Results:**
- Graph zooms in (nodes appear larger)
- Each click increases by 20%

### Test 6.3: Zoom Out Button
**Steps:**
1. Click zoom out (-) button multiple times

**Expected Results:**
- Graph zooms out (nodes appear smaller)
- Each click decreases by 20%

### Test 6.4: Pinch to Zoom
**Steps:**
1. Use two fingers to pinch (on touch device)
   or scroll wheel (on desktop)

**Expected Results:**
- Smooth zoom in/out
- Centered on gesture point

### Test 6.5: Recenter to Nodes
**Steps:**
1. Pan far away from all nodes
2. Click the center focus button

**Expected Results:**
- Viewport pans to center of all nodes
- All nodes become visible

### Test 6.6: Zoom Limits
**Steps:**
1. Zoom in to maximum
2. Zoom out to minimum

**Expected Results:**
- Minimum zoom: 10%
- Maximum zoom: 500%
- Cannot exceed limits

### Test 6.7: Node Tap Selection
**Steps:**
1. Tap directly on a node

**Expected Results:**
- Node becomes selected
- Orange glow and ring appear
- Details panel opens

### Test 6.8: Empty Canvas Tap
**Steps:**
1. Tap on empty canvas (not on a node)

**Expected Results:**
- Any selected node is deselected
- Details panel closes

---

## 7. Physics Simulation Tests

### Test 7.1: Initial Node Movement
**Steps:**
1. Load graph and observe immediately

**Expected Results:**
- Nodes drift slightly as physics settles
- Motion is smooth (~60fps)

### Test 7.2: Repulsion Force
**Steps:**
1. Create two nodes very close together

**Expected Results:**
- Nodes push apart automatically
- Minimum spacing maintained

### Test 7.3: Attraction Force
**Steps:**
1. Observe linked nodes

**Expected Results:**
- Linked nodes stay relatively close
- Spring-like attraction

### Test 7.4: Physics Settling
**Steps:**
1. Wait 10-20 seconds

**Expected Results:**
- Nodes eventually stop moving
- Graph reaches stable state

---

## 8. Visual Rendering Tests

### Test 8.1: Node Colors
**Steps:**
1. Create nodes with different colors

**Expected Results:**
- 8 distinct colors available
- Colors render correctly

### Test 8.2: Node Labels
**Steps:**
1. Observe node titles on graph

**Expected Results:**
- Titles visible at zoom > 40%
- White text with shadow for readability

### Test 8.3: Selection Glow
**Steps:**
1. Select a node

**Expected Results:**
- Orange glow around selected node
- Orange ring around node

### Test 8.4: Linking Glow
**Steps:**
1. Start linking from a node

**Expected Results:**
- Green glow on source node

### Test 8.5: Theme Compatibility
**Steps:**
1. Switch between light and dark themes

**Expected Results:**
- Graph visible in both themes
- Background adapts to theme

### Test 8.6: Details Panel
**Steps:**
1. Select a node

**Expected Results:**
- Bottom sheet with node info
- Shows: title, type, shape, link count
- Action buttons: Edit, Link, Focus, Delete

---

## Running Unit Tests

```bash
# Run all knowledge graph tests
flutter test test/knowledge_graph_test.dart

# Run with coverage
flutter test --coverage test/knowledge_graph_test.dart

# Run specific test group
flutter test test/knowledge_graph_test.dart --name "GraphNode"
```

---

## Test Results Checklist

### Demo Mode
| Test | Status | Notes |
|------|--------|-------|
| 1.1 Initial Demo Data | ☐ | |
| 1.2 Hub Node Identification | ☐ | |
| 1.3 Demo Link Labels | ☐ | |
| 1.4 Reload Demo Data | ☐ | |
| 1.5 Clear All | ☐ | |

### Node Management
| Test | Status | Notes |
|------|--------|-------|
| 2.1 Enter Add Node Mode | ☐ | |
| 2.2 Add Node Dialog | ☐ | |
| 2.3 Create Note Node | ☐ | |
| 2.4 Create Hub Node | ☐ | |
| 2.5 Create Idea Node | ☐ | |
| 2.6 Title Required Validation | ☐ | |
| 2.7 Select Node | ☐ | |
| 2.8 Edit Node | ☐ | |
| 2.9 Save Node Edits | ☐ | |
| 2.10 Focus on Node | ☐ | |
| 2.11 Delete Node | ☐ | |
| 2.12 Cancel Add Node Mode | ☐ | |

### Link Management
| Test | Status | Notes |
|------|--------|-------|
| 3.1 Start Linking Mode | ☐ | |
| 3.2 Add Link Dialog | ☐ | |
| 3.3 Create Link with Label | ☐ | |
| 3.4 Create Link with Color | ☐ | |
| 3.5 Prevent Duplicate Links | ☐ | |
| 3.6 Cancel Linking Mode | ☐ | |
| 3.7 Open Manage Links Dialog | ☐ | |
| 3.8 Delete Specific Link | ☐ | |
| 3.9 Clear All Links | ☐ | |
| 3.10 Empty Links State | ☐ | |

### Node Shapes
| Test | Status | Notes |
|------|--------|-------|
| 4.1 Circle Shape | ☐ | |
| 4.2 Square Shape | ☐ | |
| 4.3 Diamond Shape | ☐ | |
| 4.4 Hexagon Shape | ☐ | |
| 4.5 Star Shape | ☐ | |
| 4.6 Rectangle Shape | ☐ | |

### Link Styles
| Test | Status | Notes |
|------|--------|-------|
| 5.1 Thin Line Style | ☐ | |
| 5.2 Normal Line Style | ☐ | |
| 5.3 Thick Line Style | ☐ | |
| 5.4 No Arrow Style | ☐ | |
| 5.5 Single Arrow Style | ☐ | |
| 5.6 Double Arrow Style | ☐ | |
| 5.7 Link Label Display | ☐ | |
| 5.8 Link Label Zoom Scaling | ☐ | |

### Navigation & Gestures
| Test | Status | Notes |
|------|--------|-------|
| 6.1 Pan Canvas | ☐ | |
| 6.2 Zoom In Button | ☐ | |
| 6.3 Zoom Out Button | ☐ | |
| 6.4 Pinch to Zoom | ☐ | |
| 6.5 Recenter to Nodes | ☐ | |
| 6.6 Zoom Limits | ☐ | |
| 6.7 Node Tap Selection | ☐ | |
| 6.8 Empty Canvas Tap | ☐ | |

### Physics Simulation
| Test | Status | Notes |
|------|--------|-------|
| 7.1 Initial Node Movement | ☐ | |
| 7.2 Repulsion Force | ☐ | |
| 7.3 Attraction Force | ☐ | |
| 7.4 Physics Settling | ☐ | |

### Visual Rendering
| Test | Status | Notes |
|------|--------|-------|
| 8.1 Node Colors | ☐ | |
| 8.2 Node Labels | ☐ | |
| 8.3 Selection Glow | ☐ | |
| 8.4 Linking Glow | ☐ | |
| 8.5 Theme Compatibility | ☐ | |
| 8.6 Details Panel | ☐ | |

---

## Bug Reporting Template

```markdown
## Bug Report

**Feature:** [e.g., Node Management]
**Test Case:** [e.g., Test 2.3: Create Note Node]
**Platform:** [e.g., Windows 11, Flutter 3.24]

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Result:**
What should happen

**Actual Result:**
What actually happened

**Screenshots:**
(Attach if helpful)

**Console Errors:**
(Paste any error messages)
```

---

## Version Information

- **Feature Branch:** `feature/knowledge-graph`
- **Last Updated:** December 2024
- **Flutter Version:** 3.24+
- **Total Manual Tests:** 53
- **Unit Tests:** test/knowledge_graph_test.dart
