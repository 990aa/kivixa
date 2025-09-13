# Gestures Parity Checklist

This document enumerates quick swipe right, double-tap fit, two/three-finger undo/redo, and long-press actions, and references the gesture settings/services and device capability reports already implemented.

## Gestures

| Gesture | Action | Backend Service / Setting | Device Capability | UI Review |
| --- | --- | --- | --- | :---: |
| Quick Swipe Right | (User Defined) | `GestureSettingsService` | Touchscreen | ☐ |
| Double-Tap | Fit to screen / Zoom | `GestureSettingsService`, `ViewportStateService` | Touchscreen | ☐ |
| Two-Finger Tap | Undo | `GestureSettingsService`, `SafeUndoRedoService` | Multi-touch | ☐ |
| Three-Finger Tap | Redo | `GestureSettingsService`, `SafeUndoRedoService` | Multi-touch | ☐ |
| Long-Press | (User Defined) / Context Menu | `LongpressActionsService` | Touchscreen | ☐ |
| Two-Finger Pan | Pan canvas | `ViewportStateService` | Multi-touch | ☐ |
| Two-Finger Pinch | Zoom canvas | `ViewportStateService` | Multi-touch | ☐ |
| ... | ... | ... | ... | ☐ |

## Device Capability Reports

Device capabilities for gestures (e.g., touchscreen, multi-touch support) are checked at runtime. The `GestureSettingsService` can disable certain gestures if the device does not support them.
