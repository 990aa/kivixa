# Changelog

All notable changes to the Kivixa project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

--- 

## Template for Future Entries

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security updates

---

## [0.1.0] - 2025-11-25

### Initial Release
---

## [0.1.1] - 2025-12-16

### Added
- **Native Rust Integration**: Added `kivixa_native` library for high-performance AI tasks.
- **Stylus Support**: Added support for secondary stylus button to toggle Lasso Select tool.
- **Full Screen Mode**: App now launches in full screen on desktop and immersive mode on mobile.
- **Documentation**: Added comprehensive documentation for Rust implementation and release process.

### Fixed
- **Floating Browser**: Fixed "Open in Main Browser" functionality, navigation buttons, and new tab state management.
- **Resize Cursor**: Improved resize handle sensitivity for better user experience.
- **Stylus**: Fixed eraser toggle and improved button detection during drag events.

---
## [0.1.2] - 2025-12-27

### Added
- **Markdown Video Playback**: Videos now play inline in markdown preview with full controls (play/pause, seek, fullscreen)
- **Media Dimensions**: Added width/height fields to media upload dialog for precise sizing
- **Text Alignment**: Added alignment toolbar buttons (left, center, right, justify) in markdown editor
- **Text File Media Improvements**: Full image display without cropping, actual dimensions on insert

### Fixed
- **Text File Embeds**: Fixed duplicate image creation during resize operations
- **Text File Resize**: Fixed ParentDataWidget assertion errors when resizing media
- **Image Display**: Images now show full content with proper aspect ratio (BoxFit.contain)

### Changed
- Media insert now uses HTML tags for extended features (video playback, custom dimensions)
- Improved resize handles with explicit positioning to prevent layout conflicts

---

## [0.1.3] - 2025-12-29

### Added
- **App Lifecycle Manager**: New service for managing app-wide lifecycle events
  - Idle detection with 5-minute timeout (configurable)
  - Section-based resource management (register/activate/deactivate)
  - Automatic image cache clearing on idle/background
  - `ActivityDetector` widget for tracking user interactions
  - `LifecycleAwareMixin` for easy widget integration
- **Calendar Live Updates**: Events now sync instantly across the app via `CalendarEventNotifier`
- **Browser Per-Tab History**: Each browser tab maintains its own navigation history stack

### Changed
- **Performance: SharedPreferences Caching**: Services now cache SharedPreferences instance to avoid repeated async lookups
  - `BrowserService`, `MultiTimerService`, `ChainedRoutineService`, `QuickNotesService`
- **Performance: Debounced Saves**: All save operations now debounce by 500ms to batch rapid disk writes
- **Performance: Isolate JSON Parsing**: Heavy JSON parsing offloaded to isolates via `compute()`
  - Bookmarks, history, tabs in BrowserService
  - Timer lists in MultiTimerService
  - Routine lists in ChainedRoutineService
  - Notes lists in QuickNotesService
- **UI: RepaintBoundary**: Added to `PreviewCard` to isolate repaints and reduce jank
- **Updates Dialog**: Renamed from `ReleaseNotesDialog` with added refresh button

### Fixed
- **Browser Keyboard Shortcuts**: Now reliably captured with `KeyboardListener` wrapper
- **Browser Navigation**: Back/forward buttons use per-tab history instead of WebView native navigation
- **Calendar Events**: Creating/deleting events now updates UI immediately

---
## [0.1.5] - 2026-01-18

### Added

- **Multi-Model Support**: Users can now download and switch between multiple AI models
  - **Phi-4 Mini** (default): General purpose, writing, math/LaTeX assistance (~2.5 GB)
  - **Qwen2.5 3B**: Writing, notes, code generation, Lua scripting (~1.9 GB)
  - **Function Gemma 270M**: Ultra-fast MCP/tool calling specialist (~180 MB)
  - **Gemma 2B**: General purpose, code generation (~1.5 GB)
  - **Gemma 7B**: Larger general purpose model (~4.7 GB)
- **Model Categories**: Models are now tagged with categories (General, Agent/MCP, Writing, Math, Code)
- **Quick Model Switcher**: Click the model chip in chat to instantly switch between downloaded models
- **Enhanced Model Selection Page**: Browse models by category, see download status, manage models
- **Model Management**: Download, load, and delete models from the Models page
- **AI Model Context Protocol (MCP)**: Full implementation of MCP for advanced AI capabilities.
  - **Multi-Model Support**: Integrated Phi-4 (Reasoning), Function Gemma (Tools), and Qwen (Code).
  - **Tool System**: Added 8 core MCP tools including File Operations (Read/Write/List), Lua Scripting (Calendar/Timer), and Markdown Export.
  - **Security Layer**: Implemented strict path sandboxing, extension allow-lists, and file size limits.
  - **User Safety**: Added confirmation dialogs for all sensitive file operations and tool executions.
  - **Documentation**: Added comprehensive guides for AI MCP usage (`docs/AI_MCP_GUIDE.md`) and testing (`docs/MCP_TESTING_GUIDE.md`).
- **MCP Chat Interface**:
  - `MCPChatController`: New controller handling tool execution, parsing, and status updates.
  - `ModelRouter`: Intelligent routing system to select the best model for specific tasks (Conversation, Tool Use, Coding).
  - **Pure Dart Implementation**: robust standalone Dart services for MCP and Model Routing with comprehensive test coverage.
- **Testing**:
  - Added 28 unit tests for Dart MCP services (`test/mcp_service_test.dart`).
  - Added 10 Rust integration tests for core native MCP logic.

### Changed
- Chat header now shows a dropdown to quickly switch between downloaded models
- Model selection page redesigned with category filters and better model cards
- Default model remains Phi-4 Mini for backward compatibility
- **Architecture**: Refactored AI services to support standalone operation without mandatory native bindings initially.

### Fixed
- **Native Library Loading**: Fixed DLL/SO loading on Windows and Linux with platform-specific path resolution
- **Build Script**: The `scripts/build_native.ps1` now correctly copies native libraries to the right output directories

---
## [0.1.6] - 2026-01-25

### Added
- **Folder Colors**: Users can now assign any custom color to folders using a full-spectrum color picker.
- **Whiteboard Orientation**: Added ability to toggle between Portrait and Landscape modes in Whiteboard settings.
- **Floating Math**: New floating tool for calculations with support for basic operations, exponents, and percentage.
- **Math Module**: Comprehensive mathematics module with Rust backend for high-performance calculations.
  - **General Tab**: Scientific calculator, expression evaluation, trigonometry, logarithms, and unit conversions
  - **Algebra Tab**: Polynomial operations, equation solving (linear, quadratic, polynomial), factorization, and simplification
  - **Calculus Tab**: 
    - Numerical derivatives (first, second, nth order)
    - Definite and indefinite integrals
    - **Partial Derivatives**: Compute partial derivatives with respect to multiple variables (∂f/∂x, ∂f/∂y, etc.)
    - **Multiple Integrals**: Double and triple integrals over rectangular regions
    - Limits with left/right-sided approach
    - Taylor series expansion
  - **Statistics Tab**: 
    - Descriptive statistics (mean, median, mode, standard deviation, variance)
    - Probability distributions (normal, exponential, binomial, Poisson)
    - Hypothesis testing:
      - One-sample and two-sample **t-tests**
      - One-sample and two-sample **z-tests** (known population standard deviation)
      - **Chi-squared test** for categorical data
      - **ANOVA** (Analysis of Variance) for comparing multiple group means
    - Confidence intervals for mean, proportion, and variance
    - Linear and polynomial regression with R², slope, intercept
  - **Discrete Tab**: Combinatorics (permutations, combinations, factorials), number theory (GCD, LCM, primality), modular arithmetic
  - **Graphing Tab**: 2D function plotting, parametric curves, polar coordinates, implicit functions
  - **Tools Tab**: Number system conversion (binary, octal, decimal, hex), constants reference, formula library
- **Native Math Library**: New `kivixa_math` Rust library with:
  - Complex number arithmetic and operations
  - Matrix operations using nalgebra (determinant, inverse, eigenvalues, LU/QR decomposition)
  - Statistical distributions via statrs (normal, exponential, binomial, poisson)
  - High-precision calculations with BigInt support
  - Parallel computation for large datasets using rayon
- **Math Build Script**: Dedicated `scripts/build_math.ps1` with flags for Release, Copy, GenerateBindings, Clean, and All operations
- **Comprehensive Tests**: 
  - 49 Rust unit tests covering all math modules
  - 27 Flutter widget tests for math UI components

### Changed
- **Update Dialog**: Removed automatic update dialog on startup. Updates can now be checked manually via "Settings > Updates".
- **Floating Hub**: Renamed "Calculator" tool to "Math".
- **Build Scripts**: Updated `build_native.ps1` and `build_math.ps1` with:
  - `-SkipClean` flag to preserve build cache
  - Profile directory support for Windows
  - Copies to `rust_builder` plugin directories for proper Flutter integration
  - Copies to all jniLibs locations for Android (arm64-v8a, armeabi-v7a)
- **Code Cleanup**: Removed unused expression evaluation helper functions (replaced by Rust backend)

### Fixed
- **Settings**: Fixed font size of settings page title for consistency.
- **Models**: Fixed issue where switching models in floating hub assistant wouldn't persist.
- **MCP**: Fixed MCP mode toggle in floating assistant window.
- **Android Build**: Fixed cross-compilation for Android targets on nightly Rust toolchain.
- **Library Loading**: Native libraries now copied to all required directories for Flutter to detect them.

---
## [0.1.8] - 2026-01-31

### Fixed
- **Android**: Fixed loading indicator alignment in AI interface.
- **Android**: Fixed back button behavior; now supports double-tap to exit and proper navigation stack handling.
- **Android**: Fixed file browsing on Android 13+ devices using native file picker.
- **Android**: Fixed system status bar color inconsistencies.
- **Settings**: Fixed "Update available" message appearing even when the application is up to date.

---
## [0.2.0] - 2026-01-31

### Added
- **Audio Intelligence Module** - Complete native Rust audio processing pipeline ("Ear" & "Voice"):
  - **Speech-to-Text (STT)** - Whisper-based transcription engine
    - Support for multiple Whisper model sizes (Tiny, Base, Small, Medium, Large)
    - Real-time streaming transcription with timestamp tracking
    - Word-level timestamps for semantic audio indexing
    - Search through transcriptions by text content
    - Language detection and multi-language support
  - **Text-to-Speech (TTS)** - Kokoro neural speech synthesis
    - Multiple voice styles (Default, Female, Male, Custom)
    - Adjustable speech rate and pitch control
    - High-quality 24kHz audio output
    - Word boundary tracking for lip-sync applications
    - Phoneme-level synthesis control
  - **Voice Activity Detection (VAD)** - Silero-style voice detection
    - Energy-based speech detection with adaptive thresholds
    - Zero-crossing rate analysis for speech quality
    - State machine for speech segment tracking
    - Automatic noise floor calibration
    - Configurable speech/silence duration thresholds
  - **Audio Ring Buffer** - Streaming audio pipeline
    - 30-second circular buffer optimized for Whisper
    - Thread-safe audio capture and processing
    - Support for raw bytes, i16, and f32 sample formats
    - Automatic sample rate conversion (rubato)
  - **Phonemizer** - Text-to-phoneme conversion
    - English phoneme support (39 phonemes)
    - Dictionary-based lookup with G2P fallback
    - Number and abbreviation expansion
    - Stress markers and syllable boundaries
- **Native Audio Library** (`native_audio`) - New Rust library for audio processing:
  - Thread-safe shared engine wrappers for concurrent access
  - 90 comprehensive unit tests covering all modules
  - Flutter Rust Bridge integration for Dart interop
  - Cross-platform support (Windows, Android)
- **Audio Build Script** - New `scripts/build_audio.ps1` with:
  - Windows and Android cross-compilation
  - Release/Debug build modes
  - Flutter Rust Bridge code generation
  - Automatic library copying to proper directories
- **Audio Intelligence Frontend** - Complete Flutter UI components for audio features:
  - **AudioNeuralEngine** - Central service managing STT, TTS, and VAD
    - Singleton pattern for app-wide audio state
    - Real-time transcription streaming with `SpeechRecognitionResult`
    - Audio visualizer data streaming for waveforms
    - VAD state tracking (silent, speaking, stopped)
    - Configurable VAD threshold and voice selection
  - **AudioRecordingService** - Microphone capture management
    - Recording state machine (stopped, preparing, recording, paused, stopping)
    - Configurable audio formats (Whisper 16kHz mono, High Quality 48kHz stereo)
    - Raw audio data streaming for real-time processing
    - Duration tracking
  - **AudioPlaybackService** - Audio playback control
    - Playback state management (stopped, loading, playing, paused, completed)
    - Volume and speed control with clamping
    - Position and duration tracking with streams
  - **AudioWaveform** - Real-time audio visualizer widget
    - Four visualization styles: Bars, Line, Circular, Orb
    - Customizable colors and bar count
    - Idle animation support
    - External data stream support
  - **NeuralDictationBar** - Smart keyboard accessory
    - Text and Command dictation modes
    - Live confidence indicator
    - Auto-insert into TextEditingController
    - Enable/disable command mode toggle
  - **VoiceNoteBlock** - Voice memo recording and playback
    - Karaoke-style transcript highlighting
    - Search within transcripts
    - Speaker identification support (via speakerId)
    - Expandable transcript view
  - **VoiceSearch** - Voice-powered search
    - VoiceSearchButton for toolbar integration
    - VoiceSearchModal with animated listening indicator
    - Configurable idle/listening icons
    - Real-time transcription preview
  - **WalkieTalkieMode** - Hands-free AI conversation
    - Full-screen immersive interface
    - Dual animated orbs (user speaking, AI responding)
    - Conversation turn history
    - State machine (idle, listening, processing, responding, paused)
  - **ReadAloud** - TTS accessibility features
    - ReadAloudController with speed (0.5x-2.0x) and voice selection
    - Sentence-by-sentence navigation
    - ReadAloudMiniPlayer with collapsible UI
    - ReadAloudAction for toolbar integration
    - FloatingReadAloudButton for quick access
    - MarkdownToolbarReadAloud integration for markdown editors
- **Comprehensive Test Suite** - 9 test files with 101 passing tests:
  - Unit tests for data models and enums
  - Widget tests for all UI components
  - Service integration tests
  - Tests properly skip animations and native dependencies

### Changed
- Updated README.md with expanded Audio Intelligence documentation
- All audio components export via `lib/components/audio/audio_components.dart`
- All audio services export via `lib/services/audio/audio_services.dart`

---
## [0.3.0] - 2026-03-28

### Added
- **New AI Models in Model Manager**:
  - **Qwen3.5 4B Distilled** with category tagging and download metadata
  - **Qwen3.5 2B Distilled** with category tagging and download metadata
  - **Qwen3.5 0.8B Distilled** with category tagging and download metadata
  - **Phi-4 Mini Reasoning** (Q4_K_M) with direct GGUF link and recommendations
  - **Gemma 3 4B IT** (Q4_K_M) with category tagging and download metadata
  - **DeepSeek R1 Distill Qwen 1.5B** (Q4_K_M) with reasoning-focused metadata
  - **SmolLM2 1.7B Instruct** (Q4_K_M) with compact-device recommendations
- **Model Selection Suggestions**: Added per-model recommendation text to help users decide which model to download.
- **UI Enhancements for Model Catalog**:
  - New reusable `ModelCatalogCard` component
  - Short description display for model cards and setup download widget
  - Suggestion banner shown inside each model card
- **Reasoning Visibility Controls**:
  - Added parsing for `<think>` / `<thinking>` blocks in assistant outputs
  - Added collapsible reasoning panels in both standard chat and MCP chat interfaces
- **Test Coverage**:
  - Added widget tests for model card rendering and action state transitions
  - Added non-network tests that validate download task construction and model link wiring
  - Added parser tests for reasoning/thinking extraction behavior

### Changed
- Updated MCP code-generation model alias recommendation to Qwen3.5 (`qwen3.5-4b`) while preserving existing routing behavior.
- Updated model router labels/aliases to recognize Qwen3.5 plus DeepSeek/SmolLM2/Gemma-3 naming variants.
- Native inference now prefers model-provided llama.cpp chat templates (`apply_chat_template`) with model-aware legacy fallback formatting.
- Updated native inference/mcp docs and tests to reflect expanded model-family detection and routing names.

### Removed
- Removed **Gemma 7B** from frontend model catalog and backend model metadata.

---
## [0.3.2] - 2026-03-28

### Changed
- Implement ChatInferenceGateway and ChatModelGateway interfaces with corresponding gateway classes
- Streamline position calculation in _ModelSwitcherChipState
- Update icon types to IconData and refine test gateway implementation

---
## [0.3.3] - 2026-03-29

### Fixed
- Android release build failure caused by `SharedPreferencesPlugin` registration symbol mismatch in generated plugin registrant code.
- Font Awesome icon type mismatches across pen/highlighter/pencil/shape-pen tools that broke release compilation.
- Async context usage in AI chat model-switch menu flow (`use_build_context_synchronously`) by switching to state `mounted` checks.
- Floating model switcher test warning for unused optional parameter in fake inference gateway.

---
## [0.3.11] - 2026-04-03

### Fixed
- Folder rename now preserves existing folder color and supports explicit color changes in the rename dialog.
- Markdown preview/split gray pane issue on desktop resolved via a desktop-safe preview fallback.
- Text editor gray-after-edit regression fixed by sanitizing legacy/invalid Quill size attributes on load/restore.
- Windows browser infinite-loading behavior hardened.

---
## [0.3.12] - 2026-04-03

### Changed
- Implemented quick-notes reopen/edit behavior so clicking a saved note opens the same editor type (text or handwriting), allows editing, and saves updates.
- Added TranslateGemma 4B IT model to backend catalog with full metadata, verified URL, and size.

---
## [0.3.13] - 2026-04-03

### Changed
- Main AI quick actions (Smart Search, Summarize, Discover) are now clickable prompt starters that auto-fill the chat composer.
- MCP tool options are now clickable prompt starters that auto-fill the MCP chat composer with tool-specific task prompts.
- Added shared prompt-prefill wiring in both chat interfaces to apply prefilled text and focus the input field.

### Added
- Added comprehensive prompt-autofill and sandbox workflow coverage in `test/ai_prompt_autofill_test.dart`, including:
  - prompt-template coverage for all visible main/MCP options,
  - UI autofill behavior validation for both chat composers,
  - sandboxed dummy file/folder MCP operations,
  - qwen 3.5 distilled 0.8B prompt-run flow using fake gateways and cleanup.
- Added `MCPService.resetForTests()` to support deterministic, isolated MCP sandbox tests.

---
## [0.3.14] - 2026-04-03

### Changed
- Settings page: renamed the "Editor" preference category label to "Handwritten Note".
- Settings page Advanced section: removed "Check for kivixa updates", "Faster updates", and "View logs" entries while keeping the top Settings update status behavior unchanged.
- Browse import flow: added support for importing `.md`, `.txt`, and `.docx` notes from the plus-menu Import Note action.
- Browse import flow: imported notes now create in-app copies with preserved base names so edits in Kivixa do not modify the original external file.
- README: updated model list and AI model credits to include TranslateGemma 4B IT and its GGUF distribution attribution.

### Added
- Text editor: triple-tap now selects the full current line.
- Markdown editor: added top-right export action (same export icon position as text editor) with markdown export menu support.

### Fixed
- Text/document import robustness: `.txt` and `.docx` imports now open directly in the text editor with content converted into Kivixa's editable text-note format.
- Flutter Rust Bridge codegen version alignment for Rust modules.

---
## [0.4.1] - 2026-04-04

### Changed
- AI and MCP chat composers now support prompt history recall with keyboard arrows:
  - `Arrow Up` walks backward through previously sent user prompts.
  - `Arrow Down` walks forward through prompt history and restores draft text at the end.
  - Applies to both main chat pages and floating assistant chat/MCP windows.
- AI and MCP chat composers now include a left-side `+` attachment action:
  - Supports multi-file selection with all file types.
  - Shows attachment preview chips above the composer before sending.
  - Each attachment chip now has a remove (`x`) action.
- Attachment context is now injected into model-bound user messages across AI and MCP controllers, including extracted text (when available) and binary metadata previews.
- Chat export payloads now include attachment metadata for user prompts.

### Added
- Added shared attachment processing service (`ChatAttachmentService`) to normalize file metadata and build model-ready attachment context.
- Added detailed regression coverage for:
  - AI composer attachment add/remove/send behavior and prompt-history keyboard navigation.
  - MCP composer attachment add/remove/send behavior and prompt-history keyboard navigation.
  - Floating assistant integration path (AI and MCP) for attachment-capable composer availability.
  - Attachment serialization/unit behavior and model payload injection.

---
## [0.5.0] - 2026-04-04

### Added
- **New On-Device Models**:
  - Added **SmolLM3 3B** model option.
  - Added **SmolVLM2 500M Video Instruct** as a merged multimodal card with GGUF + mmproj companion assets.
- **Multimodal Native Inference Path**:
  - Added image-attachment detection and multimodal prompt tokenization/evaluation via llama.cpp `mtmd` in native Rust inference.
  - Added fallback to standard text generation when vision inference prerequisites are unavailable.
- **Bundled Download Support**:
  - Added aggregate progress/download state handling for multi-asset model cards (e.g., model + mmproj).
- **Coverage Improvements**:
  - Added/updated tests for markdown chat rendering, model metadata export assertions, MCP header behavior, and native vision parsing paths.

### Changed
- **AI/MCP Chat UI**:
  - Assistant and user messages now render markdown content in both standard AI chat and MCP chat.
  - Reasoning panels now render markdown consistently.
  - MCP mode now uses a unified top bar row for status/actions; duplicate header rendering removed.
- **Chat Export Payloads**:
  - Exported JSON now includes per-assistant-response model metadata (`modelName`, `modelId`).
- **Model Download UX**:
  - Download dialog can be dismissed while downloads continue in background.
  - Added completion/failure notification wiring for background model downloads.
- **Native Build Configuration**:
  - Enabled `mtmd` support in Rust llama bindings and added missing vendored CMake entries for mtmd tool compilation.

### Fixed
- **Rust Test Stability**:
  - Serialized MCP file-operation tests to avoid global-state races under parallel test execution.
- **Rust Lint/Cleanliness**:
  - Addressed strict clippy findings and conditional-feature warnings in native API/inference paths.

---
## [0.6.0] - 2026-04-07

### Changed
- Updated the Qwen3.5 4B Claude 4.6 Opus reasoning-distilled model source to the Qwopus v3 GGUF link across model metadata, routing, and validation tests.
- Added Gemma 4 E2B IT (Q4_K_M) to the model catalog and strongest recommendations.
- Expanded model alias routing and native inference detection/fallback handling for Qwopus and Gemma 4 identifiers.
- Productivity Clock now includes a dedicated Custom Chains tab with full routine creation, editing, and deletion workflows.
- Presets and routines tabs now allow editing and deleting both built-in and custom entries.
- Added timer settings actions to restore default presets/routines and delete all custom routines.

### Added
- Added advanced routine-chain editing UI that supports block-level insert, edit, and delete operations before saving.
- Added focused productivity service tests for quick preset CRUD/reset flows and chained routine CRUD/block operations.
- Added native Rust inference tests covering Qwopus model-type detection and Gemma 4 fallback prompt formatting.

---
## [0.7.0] - 2026-04-07

### Changed
- Added microphone dictation controls to AI and MCP chat composers (including floating assistant via shared chat widgets).
- Added per-response "Read response aloud" actions to AI and MCP assistant messages.
- Added document-level read-aloud controls and floating read-aloud FAB integration to both text and markdown editors.
- Added editor dictation controls for text and markdown editing flows.
- Expanded read-aloud mini-player with persisted speed, sentence navigation, and voice selection controls.
- Added new Audio Intelligence preferences in settings:
  - master enable/disable toggle,
  - voice profile (female/male/custom),
  - custom voice selection,
  - speech speed,
  - VAD sensitivity,
  - auto-play assistant responses,
  - read-aloud FAB toggle.
- Added "Advanced Audio Models" shortcut in settings to open the dedicated audio models/voices page.
- Updated release workflow to build/package `kivixa_audio` for Android and Windows, including native artifact verification checks.

### Added
- Dart tests for read-aloud voice selection/profile resolution and audio UI control availability in chat/editor surfaces.
- Rust tests for `synthesize_with_voice` success and unknown-voice failure handling.

---
## [0.7.1] - 2026-04-07

### Changed
- Hardened the GitHub release F-Droid publishing step to update `config.yml` through structured Python YAML processing instead of indentation-sensitive heredoc replacement.
- Updated F-Droid publish automation to preserve existing signing fields while enforcing Kivixa repo branding (`repo_name`, `repo_description`, archive metadata, and `icon.png`).
- Narrowed F-Droid git staging to expected publication assets (`README.md`, `config.yml`, metadata, repo/archive outputs, and `.nojekyll`) to avoid accidental commits.

### Fixed
- Fixed release workflow failures in F-Droid publishing caused by malformed generated YAML (`ScannerError: could not find expected ':'`).
- Fixed stale/default F-Droid repository presentation by normalizing app/repo metadata and branding to Kivixa.
- Fixed legacy artifact accumulation in F-Droid outputs by removing temporary artifact caches and pruning APKs older than `0.4.0` from both `repo/` and `archive/`.

---
## [0.8.0] - 2026-04-09

### Added
- Added two new downloadable on-device AI models to Model Manager:
  - **Llama 3.2 3B Instruct** (`Llama-3.2-3B-Instruct-Q4_K_M.gguf`)
  - **Qwen2.5 1.5B Instruct** (`qwen2.5-1.5b-instruct-q4_k_m.gguf`)
- Added both new models to the **MCP / Agent Brain** category so they are available in agent-focused filtering.
- Added shared model-picker support directly in MCP chat surfaces using the same `ModelSwitcherChip` UI/interaction pattern used in standard AI chat.
- Added regression tests covering:
  - exact Hugging Face links and filenames for the new models,
  - download task/url wiring (downloadable task construction),
  - MCP/Agent category presence,
  - frontend catalog card rendering for the new model entries.

### Changed
- Updated README model list to include Llama 3.2 3B Instruct and Qwen2.5 1.5B Instruct.
- Updated AI model credits/attributions in README for the new model sources.
- MCP mode is now isolated in native backend inference using a dedicated mode sentinel so strict tool-calling guidance is only applied in MCP sessions.
- MCP backend now injects a lean tool schema + few-shot tool-call examples and enforces an MCP-only grammar-constrained JSON output path for supported local models.
- Main AI chat system prompting is now explicitly unrestricted for general-purpose requests (including essays, writing, coding, and non-note prompts) while still using note context when relevant.
- MCP tool-call parsing now supports both `{"tool": ..., "parameters": ...}` and `{"tool": ..., "args": ...}` payload variants while rejecting unknown tool names.

### Fixed
- Floating assistant MCP initialization no longer fails in test/runtime contexts where `FileManager.documentsDirectory` has not been initialized yet (safe fallback handling).

---
## [0.8.2] - 2026-04-09


### Added
- Added platform speech fallback dependencies for dictation/read-aloud (`speech_to_text`, `flutter_tts`, and `record`) plus required Android/iOS microphone and speech permission metadata.
- Added MCP regression tests for escaped multiline `args` payload parsing and Function Gemma-style direct `write_file` paragraph prompts.

### Changed
- Audio dictation now uses real microphone streaming via `AudioRecordingService` and forwards PCM chunks to `AudioNeuralEngine` instead of simulated timer-based samples.
- Read-aloud playback now uses native synthesis-to-WAV playback first, with automatic platform TTS fallback when native synthesis is unavailable or silent.
- `AudioNeuralEngine` initialization now supports fallback-only mode when native Rust audio is unavailable, with lazy speech recognizer setup and safer teardown.
- Read-aloud sentence playback in editors now routes through the shared playback service so fallback TTS is consistently applied.
- MCP direct prompt handling now materializes implicit content for natural-language write-file requests (for example, paragraph-style prompts) before tool execution.
- Native MCP grammar was upgraded to a more robust JSON-safe grammar for escaped strings, nested objects/arrays, and whitespace variations.

### Fixed
- MCP grammar sampler initialization failures no longer abort response generation; inference now logs a warning and falls back to unconstrained sampling.
- Resolved strict clippy findings in native/native_audio Rust code paths so `cargo check`, `cargo clippy`, `cargo fmt`, `cargo test`, and `cargo audit` pass in both crates.

---
## [0.8.3] - 2026-04-11

### Added
- Added a shared voice-preference utility path (`voice_preference_utils`) used by playback/read-aloud selection logic for female, male, and custom profiles.
- Added new Flutter regression tests for advanced audio voice settings UI interactions and voice preference utility coverage.
- Added expanded Rust TTS/API tests validating character-voice availability, audible synthesis output, punctuation-driven duration changes, and per-voice waveform differentiation.

### Changed
- Reworked native Rust TTS to provide a full built-in voice catalog (`af_heart`, `af_sky`, `am_adam`, `am_michael`, `bf_emma`, `bm_george`, plus compatibility aliases), with deterministic ordering for stable frontend selection.
- Replaced silent placeholder TTS waveform generation with voice-conditioned procedural synthesis including smoother envelopes, harmonic shaping, breath/noise blending, and punctuation-aware prosody/pause behavior.
- Updated Advanced Audio Models -> Voices UI to a horizontal voice catalog layout with direct preview and explicit `Set Preferred` actions per voice.
- Wired advanced voice selection to persistent global settings so chosen custom voice becomes the default for all TTS/read-aloud paths.
- Improved fallback platform-TTS voice mapping to respect selected profile/voice intent via locale/gender-aware matching when native synthesis is unavailable.

### Fixed
- Fixed profile switching issues where female/custom preferences could still sound unchanged by ensuring shared voice resolution logic is used end-to-end.
- Fixed settings-page custom voice behavior that previously exposed only generic male/female choices by exposing backend character voices in selection surfaces.
- Fixed Advanced Audio Models voice preview actions that previously produced no audio by routing previews through the playback service with real synthesis.
- Fixed Rust quality gate instability by adding explicit native crate license metadata and a repository `deny.toml`, enabling `cargo deny` to pass alongside check/clippy/fmt/test/audit.

---
## [0.8.4] - 2026-04-11

### Added
- Added a shared live dictation buffer utility to support in-place partial transcription updates and safe final-result deduplication.
- Added regression coverage for live transcription buffering behavior and floating assistant merged action-bar controls.

### Changed
- Aligned main AI chat top bar sizing and spacing with MCP mode by using a unified page-level status bar pattern.
- Aligned AI composer/input bar visuals and controls with MCP composer styling, including floating assistant usage.
- Simplified floating assistant controls into a single merged action row and removed quick-action chips/labels (`Summarize`, `Code`, `Ideas`, `MCP Mode`).

### Fixed
- Fixed dictation insertion lag by enabling real-time partial speech-to-text insertion in AI chat, MCP chat, text editor, and markdown editor.
- Fixed duplicate final transcript commits that could occur when stopping dictation after a streamed final update.

---
## [0.8.5] - 2026-04-11

### Added
- Added regression coverage for floating window drag commit behavior, quick notes responsive resizing, and settings title style stability.

### Changed
- Reworked shared floating window interaction flow to use local per-frame drag/resize rect updates with commit-on-end persistence for smoother movement and resize behavior.
- Updated floating Math and Productivity Timer windows to use the same clamped layout and positioning model as browser and assistant overlays.
- Enabled quick notes window resizing from all sides while preserving its existing local drag behavior.

### Fixed
- Removed dynamic italic styling from settings titles for switch, dropdown, selection, color, and directory controls so labels remain visually stable when values differ from defaults.
- Kept quality gates clean for this update with passing Flutter analyze and passing Rust checks in native, native_audio, and native_math.

---
## [0.8.6] - 2026-04-11

### Changed
- Added Flutter regression coverage for media-kit playback completion heuristics, speech-fallback final transcript handling, and voice-preview busy-state lifecycle behavior.

### Added
- Updated media-kit playback state handling to finalize on explicit completion signals instead of transient startup `playing=false` stream events.
- Updated dictation start flow in AI chat, MCP chat, markdown editor, text editor, and shared dictation widgets to require successful microphone-capture startup before entering active listening state.

### Fixed
- Fixed read-aloud and advanced voice-preview sessions that could flash and stop early due to premature playback-state transitions.
- Fixed fallback speech-to-text sessions dropping final transcript insertion when recognizer auto-stop occurred before the UI stop action.
- Fixed flaky native graph unit-test ordering by serializing access to shared global graph state during tests.

---
## [0.8.8] - 2026-04-14

### Added
- Added regression coverage for `NotificationService`, `AppLockService` edge cases, folder color service failure paths, and drag-end selection behavior.

### Changed
- Improved interactive canvas ergonomics with explicit `rotateEnabled` control.
- Stabilized integrated PR follow-ups with additional lint and test hardening.

### Fixed
- Fixed path validation hardening in MCP file access flows to block traversal attempts.
- Fixed tolerant URL decoding for file names containing bare `%` characters.
- Fixed Windows webview file-access behavior that could cause infinite loading loops.

### Security
- Migrated app lock PIN hashing to PBKDF2 for stronger credential protection.
- Replaced string-based MAC selection with explicit `HMac(SHA256Digest(), 64)` configuration.
- Applied constant-time comparison and related crypto review fixes for PIN verification.

---
## [0.8.9] - 2026-04-14

### Added
- Added configurable lead-time reminders for calendar events, tasks, and project deadlines.
- Added exact-time notification scheduling support for both calendar items and project deadlines.
- Added optional project deadline date-time metadata in the project manager create/edit flow.
- Added productivity timer notification actions (pause, resume, stop) directly from Android notifications.

### Changed
- Expanded notification settings with sound profiles (`Default`, `Alarm`, `Ringtone`, `Silent`) and Android vibrate-only mode.
- Updated productivity notification messaging to include richer runtime context: current timer state, active subroutine, upcoming chained block, and active parallel timer count.
- Changed terms/privacy acceptance behavior so version bumps no longer force blocking re-acceptance popups for existing accepted users.

### Fixed
- Fixed project deadline reminder lifecycle handling so updates/deletes cancel stale project notification IDs before rescheduling.

### Tests
- Added and updated tests for notification settings serialization/sanitization, exact-time scheduling behavior, project deadline notifications, deadline model serialization, and non-blocking terms version migration behavior.
---
## [0.8.10] - 2026-04-14

### Added
- Added a compact settings search bar with section filtering by query text, category, description, and keywords.
- Added bundled Android raw notification sounds for profile-backed playback: `kivixa_default`, `kivixa_alarm`, and `kivixa_ringtone`.
- Added focused regression coverage for productivity clock tab layout, unified notification settings interactions, and settings-search matching behavior.

### Changed
- Removed the redundant `Chains` tab from the productivity clock while keeping routine creation in the `Routines` tab (`+` action) unchanged.
- Unified notification management into a single settings surface that includes app-level notifications, calendar reminders, sound/vibration behavior, and productivity timer notification controls.
- Replaced lead-time reminder chips with a dropdown-style multi-select picker using checked menu options.
- Removed duplicate timer notification permission and timer sound controls from the productivity timer section after centralizing them in notification settings.

### Fixed
- Fixed Android notification sound delivery by mapping sound profiles to bundled raw resources and profile-specific audio usage attributes.
- Fixed notification vibration behavior to apply explicit vibration enable/disable settings consistently.
- Fixed productivity timer notifications ignoring the global app notification master toggle; timer notifications are now gated by the same app-level notifications setting.

### Tests
- Added widget coverage to verify the productivity clock no longer renders a `Chains` tab and still exposes routine creation in `Routines`.
- Added widget coverage for lead-time reminder multi-select dropdown behavior and productivity timer sound toggle wiring.
- Added search matcher and source-regression tests for settings search/filter integration.
- Expanded notification service tests for sound profile resource mapping, vibration behavior, and audio usage configuration.

---
## [0.8.13] - 2026-04-21

### Added
- Centralized `kivixa_notification.mp3` as the single official notification sound on all devices, replacing `kivixa_alarm.wav`, `kivixa_default.wav`, and `kivixa_ringtone.wav`.
- Added downloadable custom sound options for timer, calendar, and project reminders (`Wind Chimes`, `Chiming Out`, `Soft Plucks`), with `Star Dust` as the default bundled asset.
- Introduced `NotificationFeedbackMode` allowing users to choose between "Vibrate only" and "Vibrate + Sound" options, merging legacy notification sound and vibration controls.
- Added an explicit "Dismiss" action to productivity timer and reminder notifications to allow users to manually stop long-playing sounds and vibrations.

### Changed
- Unified the "App Notifications" master toggle by removing `notificationsEnabled`, deferring entirely to individual feature-level toggles (e.g., calendar, timer).
- Removed redundant "Notification Permission" and "Enable Notifications" toggles from the UI and backend logic to simplify notification settings.
- Timer sound alerts are now fully integrated with the newly implemented custom downloaded sounds.

---
