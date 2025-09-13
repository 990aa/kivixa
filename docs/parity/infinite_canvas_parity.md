# Infinite Canvas Parity Checklist

This document describes the core features of the infinite canvas, including expansion, navigation, and content management, mapping them to the relevant services and performance expectations.

## Feature Checklist

| Feature | Description | Relevant Services/Files | Performance Notes | UI Review |
| --- | --- | --- | --- | :---: |
| **8-Direction Expansion** | The canvas should automatically expand when the user pans or draws near any of the eight directional edges (N, NE, E, SE, S, SW, W, NW). | `InfiniteCanvasCreationService`, `ViewportStateService` | Expansion should be seamless with no noticeable lag. New chunks should be allocated and rendered on demand. | ☐ |
| **Minimap Locator** | A minimap should be available to show the user's current viewport location within the entire canvas. It should allow quick navigation by tapping or dragging. | `MinimapPlanBuilder`, `MinimapIndexBuilder`, `ViewportStateService` | Minimap rendering should be efficient and not impact main canvas performance. Updates should be real-time during panning and zooming. | ☐ |
| **Template Switching** | Users should be able to change the background template (e.g., grid, lined, dot) of the canvas at any time without losing content. | `TemplatesService`, `ModifyTemplateService` | Template change should be instant. The service should efficiently re-render the background without affecting the stroke/content layer. | ☐ |
| **Export Bounds** | When exporting, the user should be able to define the export area. The default bounds should tightly enclose all existing content on the canvas. | `ExportManager`, `RenderPlanBuilder` | Calculating content bounds should be fast, even with a large number of strokes. Export rendering should be performed off the main thread to avoid UI freezes. | ☐ |
| **Infinite Zoom** | The user should be able to zoom in and out smoothly without hitting an arbitrary limit. | `ViewportStateService` | Renders should remain crisp at all zoom levels. Performance should be maintained by optimizing stroke rendering based on the current zoom level (Level of Detail). | ☐ |
| **Object Manipulation** | Users can select, move, resize, and rotate content on the canvas. | `StrokeStore`, `SafeUndoRedoService` | Transformations should be smooth and responsive. Undo/redo operations must be reliable. | ☐ |
