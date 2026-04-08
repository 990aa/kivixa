# Landing Screenshot Requirements

Source analyzed: KIVIXA_README.md (feature sections and sub-capabilities).

## Goal
Build a complete, high-quality screenshot catalog from the real app for landing-page use, with consistent naming and full feature coverage.

## Quality Standard (for all captures)
- Resolution: desktop captures at 2560x1600 minimum; mobile captures at 1440x3120 minimum.
- Output format: PNG.
- UI quality: no clipping, no overlays hiding core UI, no debug banners, no dev tools visible.
- Content quality: realistic sample data, readable typography, and meaningful states (not empty screens unless intentionally demonstrating emptiness).
- Visual consistency: same theme/font scale per batch; include both light and dark only where explicitly required.

## Naming Convention
Use lowercase kebab-case with section prefixes:
- ai-*.png
- notes-*.png
- media-*.png
- lifegit-*.png
- plugin-*.png
- projects-*.png
- calendar-*.png
- canvas-*.png
- pdf-*.png
- productivity-*.png
- clock-*.png
- math-*.png
- quicknotes-*.png
- settings-*.png
- browser-*.png

## Coverage Matrix

### Core Workspace and Navigation
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Main workspace with file tree and note editor | workspace-notes.png | workspace-notes.png | present |
| Workspace in dark mode with same content | workspace-notes-dark-mode.png | workspace-notes-dark-mode.png | present |
| Floating Hub expanded with quick actions | floating-hub.png | floating-hub.png | present |
| New file/folder creation dialog states | notes-new-items-dialog.png | new-(folder,md,txt,handwritten).png | present (rename recommended) |

### On-Device AI and MCP
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| AI chat conversation with grounded response | ai-chat.png | ai-chat.png | present |
| AI model picker list with current selection | ai-model-picker.png | ai-model-picker.png | present |
| MCP tools panel with confirmation flow | ai-mcp-tools.png | mcp-tools.png | present (rename recommended) |
| Model download manager with progress, speed, ETA | ai-model-download-manager.png | - | missing |
| Prompt history navigation in composer | ai-prompt-history.png | - | missing |
| Attachment-aware composer with multiple files attached | ai-attachments-composer.png | - | missing |
| Attachment-aware response showing extracted context usage | ai-attachments-response.png | - | missing |
| Semantic search by meaning result page | ai-semantic-search.png | - | missing |
| Auto-categorization suggestions on notes | ai-auto-categorization.png | - | missing |
| Smart summary card generated from long note | ai-smart-summary.png | - | missing |

### Knowledge Graph and Vector Search
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Knowledge graph canvas with linked note and labeled edges | knowledge-graph.png | knowledge-graph.png | present |
| Semantic/vector search cluster or related-note results view | ai-vector-search-clusters.png | - | missing |

### Notes, Documents, and Media
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Rich markdown editor with formatting blocks | notes-markdown-editor.png | markdown-editor.png | present (rename recommended) |
| Text editor with syntax highlighting | notes-text-editor.png | - | missing |
| Handwritten note canvas | notes-handwritten-canvas.png | - | missing |
| Bidirectional note linking/backlinks view | notes-note-linking.png | - | missing |
| Embedded image with resize/rotate handles | media-image-transform.png | - | missing |
| Embedded video player in document | media-video-embed.png | - | missing |
| Media annotation comment bubble + expanded comment | media-comment-annotations.png | - | missing |
| Web image mode settings (download locally/fetch on demand) | media-web-image-modes.png | - | missing |
| Large image preview with minimap/pan-zoom | media-large-image-preview.png | - | missing |
| Split-screen dual editor mode | productivity-split-screen.png | - | missing |

### Life Git and Versioning
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Version history timeline/slider | lifegit-version-history.png | version-history.png | present (rename recommended) |
| File version control panel | lifegit-file-version-control.png | file-version-control.png | present (rename recommended) |
| Commit details/comment entry flow | lifegit-commit-comment.png | committing-comment.png | present (rename recommended) |
| Historical diff comparison view | lifegit-diff-compare.png | - | missing |
| Restore-preview confirmation screen | lifegit-restore-preview.png | - | missing |

### Scriptable Plugins and Projects
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Plugin manager with enabled/disabled scripts | plugin-manager.png | - | missing |
| Script runner with Lua execution output | plugin-script-runner.png | - | missing |
| Project dashboard overview | projects-dashboard.png | - | missing |
| Project task board/list with statuses | projects-task-management.png | - | missing |

### Calendar and Digital Canvas
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Calendar month view with events | calendar-month-view.png | productivity-calendar.png | present (rename recommended) |
| Event editor with recurrence options | calendar-event-editor.png | - | missing |
| Calendar week/day detail view | calendar-week-view.png | - | missing |
| Digital canvas with drawing tools visible | canvas-drawing-tools.png | - | missing |
| Canvas layer/background settings panel | canvas-layers-background.png | - | missing |

### PDF and Productivity
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| PDF open with annotations visible | pdf-annotate-view.png | - | missing |
| PDF export workflow screen | pdf-export-flow.png | - | missing |
| File manager with search/filter controls | productivity-file-manager-search.png | - | missing |
| Recent files view | productivity-recent-files.png | - | missing |

### Productivity Clock
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Main clock/timer tab | clock-main-timer.png | productivity-clock.png | present (rename recommended) |
| Multi-timer orchestration tab | clock-multi-timer.png | - | missing |
| Chained routines tab | clock-routines.png | - | missing |
| Stats/analytics tab | clock-stats.png | - | missing |
| Floating clock widget overlay | clock-floating-widget.png | - | missing |

### Math Module
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| General/scientific calculator view | math-general-calculator.png | math-module.png | present (rename recommended) |
| Graphing mode with plotted function | math-graphing-view.png | math-module-graph.png | present (rename recommended) |
| Statistics/hypothesis testing screen | math-statistics-tests.png | - | missing |
| Calculus tools screen (derivatives/integrals) | math-calculus-tools.png | - | missing |

### Quick Notes, Settings, and Browser
| Required Screen | Suggested Filename | Existing Asset | Status |
|---|---|---|---|
| Quick notes widget/card in Browse page | quicknotes-widget.png | quick-notes.png | present (rename recommended) |
| Quick notes handwriting mode | quicknotes-handwriting-mode.png | - | missing |
| Theme/font customization settings | settings-customization.png | - | missing |
| Privacy/security settings page | settings-privacy-security.png | - | missing |
| In-app browser main view with URL bar/nav | browser-main-view.png | - | missing |
| In-app browser find-in-page panel | browser-find-in-page.png | - | missing |
| In-app browser developer console panel | browser-dev-console.png | - | missing |
| Floating browser window overlay | browser-floating-window.png | - | missing |

## Minimum Launch Set for Landing Refresh
If only one batch is shipped first, capture these first:
- workspace-notes.png
- ai-chat.png
- ai-model-picker.png
- ai-mcp-tools.png
- notes-markdown-editor.png
- lifegit-version-history.png
- calendar-month-view.png
- clock-main-timer.png
- math-general-calculator.png
- math-graphing-view.png
- knowledge-graph.png
- browser-main-view.png

## Gap Summary
- Existing screenshots: 17
- Required for full feature coverage from README: 60
- Missing screenshots to produce: 43

## Validation Checklist
- Every top-level README feature section has at least one screenshot.
- Every screenshot filename follows naming convention.
- Every output image is sharp at desktop retina scale.
- No screenshot contains placeholder/demo text that misrepresents current app behavior.
