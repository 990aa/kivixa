# Page Flow Parity Checklist

This document demonstrates the expected behavior for page addition workflows, mapping the UI state machine and underlying settings to the backend services for later validation.

## Feature Checklist

| Feature | Description | Backend Service | Settings Storage | UI Review |
| --- | --- | --- | --- | :---: |
| **Auto-Add-on-Write** | When a user is writing near the bottom of the last page, a new page is automatically added, allowing for a continuous writing experience. | `PageFlowService`, `PageAdditionModes` | `SettingsService` (`page_flow.auto_add_enabled`) | ☐ |
| **Swipe-Up-to-Add** | A user can swipe up from the bottom of the screen to manually trigger the page addition process. | `PageFlowService`, `GestureSettingsService` | `SettingsService` (`gestures.swipe_up_add_page_enabled`) | ☐ |
| **"Release to Add" Overlay** | During the swipe-up gesture, a translucent overlay appears with the text "Release to Complete Adding". This state machine ensures intentionality. | `PageFlowService` | N/A (UI State) | ☐ |
| **State: Gesture Start** | User initiates a swipe from the bottom edge of the screen. | `GestureSettingsService` | N/A | ☐ |
| **State: Threshold Met** | User drags their finger past a certain threshold, and the "Release to Add" overlay appears. If they release before this, the action is cancelled. | `PageFlowService` | N/A | ☐ |
| **State: Action Confirmed** | User releases their finger while the overlay is active. A new page is added to the document. | `PageFlowService` | N/A | ☐ |
| **State: Action Cancelled** | User drags their finger back below the threshold before releasing. The overlay disappears, and no page is added. | `PageFlowService` | N/A | ☐ |
