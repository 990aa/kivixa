<div align="center">

<img src="assets/icon/icon.png" alt="Kivixa Logo" width="200" height="200">

# Kivixa

### A Modern Cross-Platform Notes & Productivity Application

*Seamlessly blend notes, sketches, and creativity across all your devices*

[![Flutter](https://img.shields.io/badge/Flutter-3.35.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-View%20License-blue)](LICENSE.md)
[![Version](https://img.shields.io/badge/Version-1.0.0-green)](CHANGELOG.md)

[Features](#-features) • [Getting Started](#-getting-started) • [Contributing](#-contributing) • [Documentation](#-documentation)

</div>

---

## Features

### **Notes & Documents**
- **Rich Markdown Editor** - Create beautiful formatted documents with AppFlowy Editor
  - Text formatting (bold, italic, underline, strikethrough)
  - Block formatting (lists, checkboxes, quotes, code blocks)
  - Hyperlink support
  - Real-time autosave
- **Floating Text Boxes** - Add moveable, resizable text boxes anywhere on the canvas
- **File Organization** - Intuitive folder system with move, rename, and delete operations
- **Multiple Formats** - Support for `.kvx` (native), `.md` (markdown), and PDF files

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

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.35.0 or higher
- [Dart](https://dart.dev/get-dart) 3.9.0 or higher
- Platform-specific requirements:
  - **Windows**: Visual Studio 2022 with C++ desktop development
  - **macOS**: Xcode 15+
  - **Linux**: Standard build tools (`clang`, `cmake`, `ninja-build`)
  - **Android**: Android Studio / Android SDK
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

# iOS (requires macOS)
flutter build ios --release
```

---

## Built With

### Core Technologies
- **[Flutter](https://flutter.dev)** - Cross-platform UI framework
- **[Dart](https://dart.dev)** - Programming language
- **[AppFlowy Editor](https://appflowy.io)** - Rich text editing
- **[Perfect Freehand](https://github.com/steveruizok/perfect-freehand)** - Smooth drawing strokes

### Key Dependencies
- **UI/UX**: `material_symbols_icons`, `dynamic_color`, `animations`
- **Drawing**: `perfect_freehand`, `vector_math`, `flutter_quill`
- **File Management**: `path_provider`, `file_picker`, `share_plus`
- **PDF**: `pdf`, `pdfrx`, `printing`
- **Storage**: `shared_preferences`, `flutter_secure_storage`
- **Utilities**: `go_router`, `url_launcher`, `screenshot`

*Full dependency list available in [pubspec](pubspec.yaml)*

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
|  **Windows** | Stable | Fully tested and optimized |
|  **macOS** | Stable | Requires macOS 10.15+ |
|  **Linux** | Stable | Tested on Ubuntu 20.04+ |
|  **Android** | Stable | Android 7.0 (API 24)+ |
|  **iOS** | Stable | iOS 12.0+ |
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
   git checkout -b feature/amazing-feature
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
