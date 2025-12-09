<div align="center">

<img src="assets/icon/icon.png" alt="Kivixa Logo" width="200" height="200">

# Kivixa

*Pronounced: kee-VEE-ha (/kiˈviːhɑː/)*

### A Modern Cross-Platform Notes & Productivity Application

*Seamlessly blend notes, sketches, and creativity across all your devices*

[![Flutter](https://img.shields.io/badge/Flutter-3.35.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-View%20License-blue)](LICENSE.md)
[![Version](https://img.shields.io/badge/Version-0.0.1-green)](CHANGELOG.md)

</div>

---

## Features

### **On-Device AI (NEW)**
Kivixa features a powerful on-device AI engine powered by Microsoft's Phi-4 model, providing intelligent features without requiring an internet connection.

- **Smart Model Manager**
  - Automatic download with resume support for the 2.4GB AI model
  - Background downloading - continues even when app is minimized
  - Progress tracking with speed and ETA display
  - GPU acceleration via Vulkan (Android/Windows/Linux) and Metal (macOS)

- **AI-Powered Features**
  - **Semantic Search** - Find notes by meaning, not just keywords
  - **Auto-Categorization** - Automatic topic extraction for organization
  - **Smart Summaries** - Generate concise summaries of long notes
  - **Question Answering** - Ask questions about your note content
  - **Title Suggestions** - AI-generated title recommendations

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

### **In-App Browser (NEW)**
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

- [Flutter](https://flutter.dev/docs/get-started/install) 3.35.0 or higher
- [Dart](https://dart.dev/get-dart) 3.9.0 or higher
- [Rust](https://rustup.rs/) (for building native AI engine)
- Platform-specific requirements:
  - **Windows**: Visual Studio 2022 with C++ desktop development, Vulkan SDK
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

3. **Build native Rust library** (required for AI features)
   ```bash
   cd native
   cargo build --release
   cd ..
   
   # Generate Dart bindings
   flutter_rust_bridge_codegen generate
   ```

4. **Run the app**
   ```bash
   # For desktop (Windows/macOS/Linux)
   flutter run -d windows  # or macos, linux
   
   # For mobile (Android/iOS)
   flutter run -d android  # or ios
   
   # Let Flutter choose the best available device
   flutter run
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

---

## Built With

### Core Technologies
- **[Flutter](https://flutter.dev)** - Cross-platform UI framework
- **[Dart](https://dart.dev)** - Programming language
- **[Rust](https://www.rust-lang.org)** - Native AI engine via flutter_rust_bridge
- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** - Efficient LLM inference
- **[Phi-4 Mini](https://huggingface.co/microsoft/phi-4)** - Microsoft's efficient on-device AI model
- **[AppFlowy Editor](https://appflowy.io)** - Rich text editing
- **[Perfect Freehand](https://github.com/steveruizok/perfect-freehand)** - Smooth drawing strokes
- **[Lua Dardo](https://pub.dev/packages/lua_dardo)** - Pure Dart Lua 5.3 VM for plugin scripting

### Key Dependencies
- **AI/ML**: `flutter_rust_bridge`, `llama-cpp-2` (Rust), `fdg-sim` (graph physics)
- **UI/UX**: `material_symbols_icons`, `dynamic_color`, `animations`
- **Drawing**: `perfect_freehand`, `vector_math`, `flutter_quill`
- **File Management**: `path_provider`, `file_picker`, `share_plus`
- **PDF**: `pdf`, `pdfrx`, `printing`
- **Storage**: `shared_preferences`, `flutter_secure_storage`
- **Version Control**: `crypto` (SHA-256 for content-addressable storage)
- **Scripting**: `lua_dardo` (Lua 5.3 interpreter)
- **Browser**: `flutter_inappwebview` (WebView2/WebView integration)
- **Utilities**: `go_router`, `url_launcher`, `screenshot`

*Full dependency list available in [pubspec](pubspec.yaml)*

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
- **Repository**: [kivixa](https://github.com/990aa/kivixa)

---

<div align="center">

⭐ Star this repository if you find it helpful!

</div>
