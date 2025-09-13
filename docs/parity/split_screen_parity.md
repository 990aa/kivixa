# Split Screen Parity Checklist

This document covers orientation toggle, divider drag, swap, edge-close, and session restore, mapped to `SplitLayoutService` and `SplitScreenPersistence` with test notes.

## Split Screen Features

| Feature | Backend Service | Test Notes | UI Review |
| --- | --- | --- | :---: |
| Toggle Orientation | `SplitLayoutService` | Verify layout changes correctly (horizontal/vertical) | ☐ |
| Divider Drag | `SplitLayoutService` | Test drag limits and resizing behavior | ☐ |
| Swap Panes | `SplitLayoutService` | Ensure content in panes is swapped correctly | ☐ |
| Edge-Close | `SplitLayoutService` | Dragging to edge should close one pane and maximize the other | ☐ |
| Session Restore | `SplitScreenPersistence` | Verify split layout and content are restored on app restart | ☐ |
| ... | ... | ... | ☐ |

## Service Mapping

*   **`SplitLayoutService`**: Manages the active state of the split view, including the orientation, divider position, and pane contents.
*   **`SplitScreenPersistence`**: Saves and restores the last known split screen state across sessions, ensuring a consistent user experience.
