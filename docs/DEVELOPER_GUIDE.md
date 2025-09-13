
# Kivixa Developer Guide (Flutter Edition)

Welcome to the Kivixa developer guide. This document provides a comprehensive overview of the architecture, backend-first philosophy, and step-by-step instructions for building, running, and contributing to the Kivixa app (now built with Flutter for Windows and Android).

---

## 1. Philosophy & Overview

Kivixa is a **backend-first, performance-oriented Flutter application** designed for both Windows and Android. The project emphasizes:

- **Backend-first architecture:** All business logic, data persistence, and core services are implemented independently of the UI, ensuring testability and maintainability.
- **Performance:** Optimized for low-end devices, with careful use of SQLite, caching, and background isolates.
- **Modularity:** Features are organized in a scalable, modular structure.
- **Provider-agnostic AI:** Flexible AI integration via adapters for OpenAI, Google, Ollama, and more.

---

## 2. Getting Started: Development Environment

### Prerequisites

- [Flutter SDK (3.9+ recommended)](https://docs.flutter.dev/get-started/install)
- [Dart SDK] (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) (for Android builds)
- [Visual Studio (with Desktop development workload)](https://docs.microsoft.com/en-us/visualstudio/install/install-visual-studio) (for Windows builds)
- Git

### Setup

1. **Clone the repository:**
     ```bash
     git clone https://github.com/990aa/kivixa.git
     cd kivixa
     ```
2. **Install dependencies:**
     ```bash
     flutter pub get
     ```
3. **(Optional) Run tests:**
     ```bash
     flutter test
     ```
4. **Open in your preferred IDE:**
     - Android Studio, VS Code, or IntelliJ IDEA

---

## 3. Project Architecture

Kivixa is organized into clear layers and feature modules. For deep dives, see:
- [Architecture Deep Dive](./architecture.md)
- [Performance Guide](./performance.md)
- [AI Setup](./ai-setup.md)

### Key Layers

- **Data Layer (`lib/data/`):**
    - SQLite database (via Drift and sqflite/sqlite3) for all persistent data.
    - Repository pattern for data access and abstraction.
    - Handles migrations, schema, and DAOs.
- **Domain Layer (`lib/domain/`):**
    - Pure Dart models and business logic (e.g., infinite canvas, render plans).
- **Services Layer (`lib/services/`):**
    - High-level business logic, orchestration, and background tasks (e.g., ExportManager, BackupManager, LibraryService, AI actions).
- **Features Layer (`lib/features/`):**
    - Modular UI and logic for each app feature (library, editor, PDF, AI, export, templates, etc.).
- **Platform Layer (`lib/platform/`):**
    - Platform-specific code (paths, secure storage, OS integration).
- **Widgets Layer (`lib/widgets/`):**
    - Reusable UI components.

### Backend-First Approach

- All core logic and data flows are implemented and tested independently of the UI.
- The UI layer consumes services and models exposed by the backend.
- This enables robust testing, easier maintenance, and future platform expansion.

---

## 4. Database & Storage

- **SQLite** is the single source of truth for all structured data.
- **Drift** is used for schema, migrations, and typed DAOs.
- **Assets** (images, PDFs, audio) are stored in the local file system, referenced by the database.
- **Performance:** WAL mode, cache tuning, and background isolates are used for optimal speed (see [Performance Guide](./performance.md)).

---

## 5. AI Integration

- **Provider-agnostic:** The AI layer uses adapters for OpenAI, Google, Ollama, and more.
- **Secure key storage:** API keys are stored using platform-native secure storage (see [AI Setup](./ai-setup.md)).
- **Local AI:** You can use local endpoints (e.g., Ollama) for privacy and cost savings.

---

## 6. Building the Application (EXE & APK)

You can build Kivixa for Windows (EXE) and Android (APK) using either the provided build script or manual Flutter commands.

### Automated Build (Recommended)

From the project root, run:

```bash
dart build.dart
```

This will build:
- **Windows EXE:** Output in `build/windows/runner/Release/`
- **Android APK:** Output in `build/app/outputs/flutter-apk/`

### Manual Build

- **Windows:**
    ```bash
    flutter build windows --release
    ```
- **Android:**
    ```bash
    flutter build apk --release
    ```

---

## 7. Contributing

- Follow the backend-first philosophy: implement business logic and data flows in the backend/services before UI.
- Add new features as modular packages in `lib/features/`.
- Use the repository and service patterns for all data access and business logic.
- Write tests for new backend logic in `test/`.
- For UI, use Riverpod for state management and keep widgets modular.

---

## 8. Code Style & Best Practices

- Follow Dart and Flutter best practices.
- Use immutable data models where possible.
- Keep business logic out of widgets.
- Use async/await and isolates for heavy tasks.
- Write clear, concise, and well-documented code.

---

## 9. Further Reading

- [Architecture Deep Dive](./architecture.md)
- [Performance Guide](./performance.md)
- [AI Setup](./ai-setup.md)
- [Feature Parity Checklists](./parity/)

---

**Kivixa is designed for maximum control, performance, and maintainability.**