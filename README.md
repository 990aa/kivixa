<div align="center">

<img src="assets/icon/icon.png" alt="Kivixa Logo" width="200" height="200">

# Kivixa

*Pronounced: kee-VEE-ha (/kiˈviːhɑː/)*

### A Modern Cross-Platform Notes & Productivity Application

*Seamlessly blend notes, sketches, and creativity across all your devices*

[![Flutter](https://img.shields.io/badge/Flutter-3.35.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-View%20License-blue)](LICENSE.md)
[![Version](https://img.shields.io/badge/Version-0.1.6%2B1006--beta-orange)](CHANGELOG.md)

[![Download Windows](https://img.shields.io/badge/Download-Windows-2ea44f?logo=windows)](https://github.com/990aa/kivixa/releases/download/v0.1.6%2B1006/Kivixa-Setup-0.1.6.exe)

**Android Downloads:**
[![Android ARM64](https://img.shields.io/badge/Android-ARM64-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/v0.1.6%2B1006/Kivixa-Android-0.1.6-arm64.apk)
[![Android ARMv7](https://img.shields.io/badge/Android-ARMv7-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/v0.1.6%2B1006/Kivixa-Android-0.1.6-armv7.apk)
[![Android x86_64](https://img.shields.io/badge/Android-x86_64-3DDC84?logo=android&logoColor=white)](https://github.com/990aa/kivixa/releases/download/v0.1.6%2B1006/Kivixa-Android-0.1.6-x86_64.apk)
[![F-Droid Repo](https://img.shields.io/badge/F--Droid-Add%20Repo-F5BB00?logo=fdroid)](https://990aa.github.io/kivixa/)

</div>

---

## Features

### **On-Device AI**
Kivixa features a powerful on-device AI engine with multi-model support and Model Context Protocol (MCP) for intelligent, action-capable AI assistance without requiring an internet connection.

- **Multi-Model Support**
  - **Phi-4 Mini** - Default model for reasoning, conversation, and general assistance
  - **Qwen 2.5 3B** - Specialized for writing, notes, and code generation
  - **Function Gemma 270M** - Ultra-fast, optimized for MCP tool calling (~180MB)
  - **Gemma 2B / 7B** - Google's efficient general-purpose models
  - Automatic model routing based on task classification
  - Seamless model switching for optimal performance

- **Model Context Protocol (MCP)**
  - **AI-Powered Tool Execution** - Let AI perform actions on your behalf
  - **File Operations** - Read, write, delete files; create folders
  - **Directory Listing** - Browse and explore your notes folder
  - **Markdown Export** - Export AI responses as formatted documents
  - **Lua Scripting Integration** - Execute calendar and timer scripts
  - **Safety First** - All tool executions require user confirmation
  - **Sandboxed Operations** - File access restricted to notes folder

- **Smart Model Manager**
  - Automatic download with resume support for AI models
  - Background downloading - continues even when app is minimized
  - Progress tracking with speed and ETA display
  - GPU acceleration via Vulkan (Android/Windows/Linux) and Metal (macOS)

- **AI-Powered Features**
  - **Semantic Search** - Find notes by meaning, not just keywords
  - **Auto-Categorization** - Automatic topic extraction for organization
  - **Smart Summaries** - Generate concise summaries of long notes
  - **Question Answering** - Ask questions about your note content
  - **Title Suggestions** - AI-generated title recommendations
  - **MCP Chat Mode** - Toggle tool-enabled AI for file operations

- **Knowledge Graph Visualization**
  - **Interactive Mind Mapping** - Create visual knowledge networks
    - Pan and zoom navigation with touch/mouse gestures
    - Drag nodes to reposition them on the canvas
    - Grid background toggle for precise alignment
  - **Multiple Node Types**
    - Hub nodes for central topics
    - Note nodes that can link to your actual notes
    - Idea nodes for brainstorming
    - 6 shape options: Circle, Square, Diamond, Hexagon, Star, Rectangle
    - 8 color options with visual customization
  - **Rich Node Content**
    - Add titles and descriptions to each node
    - Link Note nodes to actual notes from your Browse section
    - View and open linked notes directly from the graph
    - Supports handwritten (.kvx), markdown (.md), and text files
  - **Flexible Link System**
    - Connect nodes with customizable links
    - Add text labels to links (e.g., "relates to", "depends on")
    - 3 line thickness options: Thin, Normal, Thick
    - Arrow styles: None, Single Arrow, Double Arrow
    - Custom link colors
    - Manage links dialog to view/delete connections
  - **Navigation & Organization**
    - Recenter view to all nodes
    - Focus on selected node
    - Clear all nodes/links or load demo data
    - Persistent storage - your graph is saved automatically

- **Vector Database**
  - Local vector embeddings for all your notes
  - Lightning-fast similarity search
  - Automatic clustering of related content
  - Persistent cache for instant startup

- **Privacy-First AI**
  - Runs 100% on-device - no data leaves your device
  - No internet required after initial model download
  - No API keys or subscriptions needed
  - Your notes stay private

### **Notes & Documents**
- **Rich Markdown Editor** - Create beautiful formatted documents with AppFlowy Editor
  - Text formatting (bold, italic, underline, strikethrough)
  - Block formatting (lists, checkboxes, quotes, code blocks)
  - Hyperlink support
  - Real-time autosave
- **Floating Text Boxes** - Add moveable, resizable text boxes anywhere on the canvas
- **File Organization** - Intuitive folder system with move, rename, and delete operations
- **Multiple Formats** - Support for `.kvx` (native), `.md` (markdown), `.txt` (text), and PDF files
- **Text File Editor** - Full-featured text editor with syntax highlighting
- **Note Linking** - Connect related notes together with bidirectional links

### **Media Embedding**
- **Image & Video Upload** - Embed media directly into markdown and text files
  - Upload from local storage or paste from web URLs
  - Insert local absolute paths (`![Alt](C:\path\to\image.jpg)`)
  - Automatic file management with dedicated media storage
  - Videos are fully playable within embedded player with volume control
- **Interactive Media Controls**
  - **Resize**: Drag corner/edge handles to adjust dimensions
  - **Rotate**: Rotate images with 15° snapping for precision
  - **Move Handle**: 4-way arrow in center for precise repositioning
  - **Drag**: Reposition media anywhere within the document
  - **Aspect Ratio Lock**: Hold Shift while resizing to maintain proportions
  - **Keyboard Support**: Escape to deselect, Shift for aspect lock
- **Comment Annotations**
  - Add optional comments to any image or video
  - Hover to reveal (Windows) or tap icon (Android)
  - Edit and delete comments easily
  - URL-encoded for special character support
- **Web Image Modes** (configurable in Settings)
  - **Download Locally**: Cache images for offline access
  - **Fetch on Demand**: Load from web each time (saves storage)
  - Cache management with size display and clear option
- **Large Image Preview**
  - Scrollable preview for images > 2000px
  - Pan and zoom within a constrained container
  - Minimap showing visible region
  - Toggle between preview and full display modes
  - Configurable preview container size (100-500px)
- **Extended Markdown Syntax**
  - `![alt|width=300,height=200,rotation=45,x=10,y=20](path)`
  - All transforms persist in standard markdown files
  - Compatible with other markdown viewers (shows default)
- **Performance Optimized**
  - LRU caching for loaded images
  - Thumbnail generation for heavy media
  - Lazy loading via visibility detection
  - Isolated repaints with RepaintBoundary
  - Auto-hide video controls during playback


### **Life Git (Version Control)**
- **Time Travel** - Roll back any note to any previous version with an intuitive slider
- **Auto-Snapshots** - Automatic versioning when you stop typing (2-second debounce)
- **Content-Addressable Storage** - Git-like blob storage using SHA-256 hashing
- **Commit History** - Browse all changes with timestamps and commit messages
- **Version Comparison** - Preview any historical version before restoring
- **Per-File History** - Track changes for individual files
- **Zero Configuration** - Just write, Life Git handles versioning automatically

### **Scriptable Plugin System**
- **Lua Scripting** - Automate tasks with Lua 5.3 scripts
- **Built-in App API** - Access your notes programmatically:
  - `App:createNote(path)` - Create new notes
  - `App:readNote(path)` - Read note content
  - `App:writeNote(path, content)` - Write to notes
  - `App:getAllNotes()` - List all notes
  - `App:findNotes(query)` - Search notes
  - `App:getRecentNotes(count)` - Get recent notes
  - `App:moveNote(from, to)` - Move notes
  - `App:deleteNote(path)` - Delete notes
  - `App:getStats()` - Get workspace statistics
- **Example Plugins Included** - Archive tasks, daily summaries, move overdue items
- **Plugin Manager** - Enable/disable and run plugins from the UI
- **Script Runner** - Execute ad-hoc Lua code directly

### **Project Manager**
- **Project Dashboard** - Organize your work into dedicated projects
- **Task Management** - Create and track tasks within projects
- **Progress Tracking** - Visual indicators for project completion status
- **Project Categories** - Organize projects with custom categories

### **Calendar & Events**
- **Interactive Calendar** - View and manage events with day, week, and month views
- **Event Management** - Create, edit, and delete events with custom colors
- **Recurring Events** - Support for daily, weekly, monthly, and yearly recurrence
- **Reminders** - Get notified before important events
- **Calendar Navigation** - Easy navigation between dates with jump-to-date feature

### **Digital Canvas**
- **Advanced Drawing Tools**
  - Pen with pressure sensitivity
  - Highlighter for emphasis
  - Laser pointer for presentations
  - Eraser with multiple modes
  - Shape tools and selection
- **Professional Canvas Features**
  - Infinite canvas with smooth pan & zoom
  - Layer support for complex artwork
  - Background customization (colors, patterns, images)
  - Grid and snap-to-grid options
  - Transform tools (rotate, scale, move)

### **PDF Integration**
- Import and annotate PDF documents
- Export notes as PDFs
- Maintain annotations across devices
- High-quality rendering

### **Productivity**
- **Smart Autosave** - Never lose your work with automatic saving
- **Split Screen View** - Open and edit two files simultaneously side-by-side
  - Support for different file types (handwritten, markdown, text)
  - Horizontal and vertical split modes
  - Resizable panes with drag-to-adjust divider
  - Swap panes functionality
- **File Manager** - Powerful organization with search and filtering
- **Recent Files** - Quick access to your latest work
- **Cross-Platform Sync** - Work seamlessly across devices
- **Keyboard Shortcuts** - Boost productivity with keybindings

### **Productivity Clock**
A comprehensive productivity timer system with advanced features for focused work sessions.

- **Core Timer Features**
  - **Pomodoro Technique** - Classic 25-minute focus sessions with breaks
  - **Multiple Timer Templates** - Pomodoro (25/5), 52/17 Method, Ultradian (90/20)
  - **Custom Durations** - Set any work/break duration you prefer
  - **Session Types** - Focus, Short Break, Long Break, Flow, and Custom modes
  - **Progress Tracking** - Visual circular progress indicator
  - **Floating Clock Widget** - Always-visible timer overlay while working

- **Context-Aware Timers**
  - **Session Tags** - Tag sessions with context (Coding, Reading, Writing, Meeting, Research, Design, Learning, Planning, Exercise)
  - **Filter Stats by Tag** - Analyze productivity by activity type
  - **Custom Tags** - Create your own context tags with custom colors and icons

- **Quick-Switch Presets**
  - **Code Preset** - 90-minute deep work with 20-minute breaks
  - **Reading Preset** - 45-minute reading with 10-minute breaks
  - **Deep Design Preset** - 2-hour creative sessions with 25-minute breaks
  - **Sprint Preset** - Quick 25-minute bursts with 5-minute breaks
  - **Meetings Preset** - 30-minute time-boxed meetings with 5-minute prep

- **Multi-Timer Orchestration**
  - **Parallel Clocks** - Run main focus timer with secondary reminders
  - **Built-in Presets** - Tea timer, Commit reminder, Eye rest (20-20-20), Stretch, Water break, Standup, Posture check, Meeting alert
  - **Custom Timers** - Create unlimited secondary countdown timers
  - **Independent Control** - Start, pause, stop each timer separately

- **Chained Routines**
  - **Sequential Timed Blocks** - Create routines as a sequence of activities
  - **Built-in Routines**:
    - Morning Routine (Meditate → Exercise → Journal → Plan Day)
    - Evening Wind-Down (Review Day → Light Reading → Gratitude → Breathe)
    - Study Session (Review Notes → Active Learning → Practice → Quiz)
    - Creative Session (Warm Up → Deep Work → Review → Document)
    - Work Sprint (Plan → Sprint 1 → Break → Sprint 2 → Review)
  - **Auto-Advance** - Automatically transitions between blocks
  - **Custom Routines** - Create your own structured workflows

- **Statistics & Analytics**
  - **Daily Goals** - Set and track focus time goals
  - **Session History** - View completed sessions with duration and tags
  - **Completion Rate** - Track session completion percentage
  - **Tag Analytics** - See time distribution across activities
  - **Progress Visualization** - Charts and graphs for productivity insights

- **Smart Notifications**
  - **Session Reminders** - Notification when sessions complete
  - **Break Alerts** - Reminders to take breaks
  - **Routine Progress** - Updates on routine block transitions
  - **Permission Controls** - Enable/disable notifications from settings

- **Dual Access**
  - **Floating Clock** - Compact overlay accessible from any screen
  - **Clock Page** - Full sidebar page with tabs (Timer, Multi-Timer, Routines, Stats, Settings)
  - **Synchronized State** - Changes in either view reflect in the other

### **Math Module**
A comprehensive mathematics suite powered by a high-performance Rust backend for accurate, fast calculations.

- **General Calculator**
  - Scientific calculator with full expression evaluation
  - Trigonometric, logarithmic, and exponential functions
  - Constants (π, e, φ) and memory functions
  - Unit conversions (length, mass, temperature, time)

- **Algebra Tools**
  - Polynomial operations (add, subtract, multiply, divide)
  - Equation solving (linear, quadratic, cubic, polynomial)
  - Factorization and simplification
  - Systems of linear equations

- **Calculus**
  - Numerical differentiation (first, second, nth derivatives)
  - **Partial derivatives** (∂f/∂x, ∂f/∂y for multivariable functions)
  - Definite and indefinite integrals
  - **Multiple integrals** (double and triple integrals over rectangular regions)
  - Limits with left/right-sided approach options
  - Taylor series expansion
  - Ordinary differential equation solvers

- **Statistics & Probability**
  - Descriptive statistics (mean, median, mode, std deviation, variance)
  - Probability distributions (normal, exponential, binomial, Poisson)
  - Hypothesis testing:
    - One-sample and two-sample **t-tests**
    - One-sample and two-sample **z-tests** (known population σ)
    - **Chi-squared test** for categorical data
    - **ANOVA** (Analysis of Variance) for comparing multiple groups
  - Confidence intervals (mean, proportion, variance)
  - Linear and polynomial regression with R² analysis

- **Discrete Mathematics**
  - Combinatorics (permutations, combinations, factorials)
  - Number theory (GCD, LCM, prime factorization, modular arithmetic)
  - Set operations (union, intersection, difference)
  - Graph theory basics

- **Graphing (Beta)**
  - 2D function plotting
  - Parametric curve visualization
  - Polar coordinate graphs
  - Interactive zoom and pan

- **Tools & References**
  - Number system converter (binary, octal, decimal, hexadecimal)
  - Mathematical constants reference
  - Formula library with common equations

### **Quick Notes**
Ephemeral note-taking for those quick thoughts that don't need permanent storage.

- **Instant Access**
  - **Floating Hub Integration** - One-tap access from the floating menu
  - **Browse Page Widget** - Collapsible card above your files
  - **Real-Time Sync** - Changes reflect immediately across all views

- **Auto-Expiration**
  - **Configurable Retention** - Notes auto-delete after a set time
  - **Preset Durations** - 15min, 30min, 1hr, 4hr, 12hr, 24hr, 3 days, 1 week
  - **Expiry Countdown** - Visual indicator showing time remaining
  - **Manual Override** - Disable auto-delete if needed

- **Input Modes**
  - **Text Mode** - Quick text entry with instant save
  - **Handwriting Mode** - Sketch quick diagrams or handwritten notes
  - **Mode Toggle** - Easy switch between input types

- **Management**
  - **Clear All** - Quickly remove all quick notes
  - **Delete Individual** - Remove specific notes
  - **Note Count Badge** - See how many quick notes you have
  - **Settings Integration** - Configure retention from Settings page

### **Customization**
- **Dynamic Theming** - Material You dynamic color support
- **Dark & Light Modes** - Easy on the eyes, any time of day
- **Custom Fonts** - Choose from Google Fonts library
- **Flexible UI** - Customize toolbars and layouts

### **Privacy & Security**
- **Local-First** - Your data stays on your device
- **Secure Storage** - Encrypted sensitive data with `flutter_secure_storage`
- **No Cloud Dependencies** - Works completely offline
- **Export Control** - You own your data, export anytime

### **In-App Browser**
A fully-featured web browser built into Kivixa for seamless research and reference.

- **Core Browser Features**
  - **WebView2 Engine** (Windows) / Native WebView (Android) via flutter_inappwebview
  - Full navigation controls (back, forward, reload, home)
  - URL bar with security indicators (🔒 for HTTPS)
  - Loading progress indicator
  - Page title display

- **Find in Page**
  - Search text within web pages
  - Match count display with navigation (previous/next)
  - Keyboard shortcut support (Ctrl+F)

- **Developer Console**
  - JavaScript console log viewer
  - Color-coded log levels (Error, Warning, Debug, Log, Tip)
  - Timestamps for each log entry
  - Clear console functionality
  - Toggle with Ctrl+Shift+J

- **Smart Features**
  - **Dark Mode Injection** - Force dark mode on any website via CSS
  - **Permission Handling** - Camera, microphone, and location permission dialogs
  - **Download Support** - External browser handoff for downloads
  - **JavaScript Dialogs** - Alert, confirm, and prompt support

- **Keyboard Shortcuts**
  - `Ctrl+L` - Focus URL bar
  - `Ctrl+F` - Toggle find-in-page
  - `Ctrl+R` or `F5` - Reload page
  - `Ctrl+Shift+J` - Toggle console
  - `Escape` - Close panels

- **Quick Links**
  - Google, GitHub, Stack Overflow, Wikipedia, YouTube, Reddit
  - Shown on new tab/home page

- **Android Integration**
  - Back button navigation (go back in history first)
  - Gesture handling

- **Floating Browser Window**
  - Quick access browser overlay
  - Resizable and moveable
  - Separate browsing session

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.38.6 or higher
- [Dart](https://dart.dev/get-dart) 3.10.7 or higher
- [Rust](https://rustup.rs/) (for building native code)
- Platform-specific requirements:
  - **Windows**: Visual Studio 2026 with C++ desktop development, Vulkan SDK
  - **macOS**: Xcode 15+, Rust with aarch64-apple-darwin target
  - **Linux**: Standard build tools (`clang`, `cmake`, `ninja-build`), Vulkan SDK
  - **Android**: Android Studio / Android SDK, NDK for Rust cross-compilation
  - **iOS**: Xcode 15+ and CocoaPods

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/990aa/kivixa.git
   cd kivixa
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For desktop (Windows/macOS/Linux)
   flutter run -d windows  # or macos, linux
   
   # For mobile (Android/iOS)
   flutter run -d android  # or ios
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# iOS
flutter build ios --release
```

### Windows Installer (Inno Setup)

For Windows distribution, we use [Inno Setup](https://jrsoftware.org/isinfo.php) to create a professional installer.

*   **Script:** `windows/installer/kivixa-installer.iss`
*   **Output:** `build/windows/installer/`
*   **Versioning:** Automatically synced with the `VERSION` file.

To build the installer run `iscc windows/installer/kivixa-installer.iss` (requires Inno Setup)

The installer includes a custom uninstaller that allows users to optionally wipe their data (`Documents\Kivixa`) upon removal.

---

## Built With

### Core Technologies
- **[Flutter](https://flutter.dev)** - Cross-platform UI framework
- **[Dart](https://dart.dev)** - Programming language
- **[Rust](https://www.rust-lang.org)** - Native AI engine and math module via flutter_rust_bridge
- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** - Efficient SLM/LLM inference

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
|  **Windows** | Stable | Fully tested and optimized |
|  **macOS** | - | Requires macOS |
|  **Linux** | - | Requires Linux |
|  **Android** | Stable | Android 7.0 (API 24)+ |
|  **iOS** | - | Requires iOS |
|  **Web** | Experimental | Limited features |

---

## Documentations

- **[Changelog](CHANGELOG.md)** - Version history and release notes
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute to the project
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community standards and expectations
- **[License](LICENSE.md)** - Legal information and usage rights

### Issue Tracking
- **[Bug Report](.github/ISSUE_TEMPLATE/bug_report.md)** - Report bugs and issues
- **[Feature Request](.github/ISSUE_TEMPLATE/feature_request.md)** - Suggest new features

---

## Contributing

Open to contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/new-feature
   ```
3. **Make your changes** and commit
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Development Guidelines

- Follow the existing code style and conventions
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Test on multiple platforms when possible

For detailed guidelines, see [CONTRIBUTING](CONTRIBUTING.md).

To report a new issue, use [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).

---

## Contact & Support

- **Issues**: [GitHub Issues](https://github.com/990aa/kivixa/issues)
- **Discussions**: [GitHub Discussions](https://github.com/990aa/kivixa/discussions)

---

<div align="center">

⭐ Star this repository if you find it helpful!

</div>
