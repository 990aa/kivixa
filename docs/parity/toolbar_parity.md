# Toolbar Parity Checklist

This document maps every required toolbar action, toolbox behavior, brush parameters, palettes, favorites, and layers controls to the corresponding backend services and storage.

## Toolbar Actions

| Action | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Select Tool | `ToolbarSettings` | `settings.db` | ☐ |
| Undo/Redo | `SafeUndoRedoService` | In-memory/stroke store | ☐ |
| Zoom In/Out | `ViewportStateService` | In-memory | ☐ |
| Pan | `ViewportStateService` | In-memory | ☐ |
| ... | ... | ... | ☐ |

## Toolbox Behavior

| Behavior | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Open/Close Toolbox | `ToolbarSettings` | `settings.db` | ☐ |
| Pin Toolbox | `ToolbarSettings` | `settings.db` | ☐ |
| Preset Selection | `ToolPresetsService` | `presets.db` | ☐ |
| ... | ... | ... | ☐ |

## Brush Parameters

| Parameter | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Size | `BrushParamsStore` | `settings.db` | ☐ |
| Opacity | `BrushParamsStore` | `settings.db` | ☐ |
| Color | `ColorPalettesService` | `palettes.db` | ☐ |
| ... | ... | ... | ☐ |

## Palettes

| Feature | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Create Palette | `ColorPalettesService` | `palettes.db` | ☐ |
| Select Color | `ColorPalettesService` | `palettes.db` | ☐ |
| Delete Palette | `ColorPalettesService` | `palettes.db` | ☐ |
| ... | ... | ... | ☐ |

## Favorites

| Feature | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Add Favorite Brush | `FavoritesService` | `favorites.db` | ☐ |
| Select Favorite | `FavoritesService` | `favorites.db` | ☐ |
| Remove Favorite | `FavoritesService` | `favorites.db` | ☐ |
| ... | ... | ... | ☐ |

## Layers Controls

| Control | Backend Service | Storage | UI Review |
| --- | --- | --- | :---: |
| Add Layer | `LayersService` | Document-specific | ☐ |
| Delete Layer | `LayersService` | Document-specific | ☐ |
| Merge Layers | `LayersService` | Document-specific | ☐ |
| Layer Opacity | `LayersService` | Document-specific | ☐ |
| ... | ... | ... | ☐ |
