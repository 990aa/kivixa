samples, guidance on mobile development, and a full API reference.

# kivixa

**Backend-first, performance-oriented Flutter app for Android and Windows.**

## Project Structure

```
lib/
	core/         # Domain models, business logic, service interfaces, repositories
		domain/     # Pure domain entities and value objects
		services/   # Abstract service interfaces
		repos/      # Repository interfaces
	data/         # Data access, schema, migrations, DAOs
		schema/     # Database schema definitions
		migrations/ # Migration scripts and helpers
		daos/       # Data Access Objects (typed or raw)
	features/     # App features (modular, scalable)
		library/    # Library management UI/logic
		editor/     # Editor UI/logic
		pdf/        # PDF handling, rendering, OCR
		ai/         # AI/ML features (OCR, NLP, etc.)
		export/     # Export, share, backup
	platform/     # Platform-specific code
		os_paths/   # OS path helpers
		storage/    # Storage abstraction
		secure/     # Secure storage, crypto
	tools/        # Developer tools, scripts, benchmarks
		bench/      # Performance benchmarks
		scripts/    # Utility scripts
```

## Backend-First Plan

1. **Typed Database Layer**: Use Drift (with NativeDatabase/FFI) or raw DAOs over sqlite3 for maximum control and performance. Schema and migrations are managed in `lib/data/schema` and `lib/data/migrations`.
2. **Performance**: All dependencies are chosen for speed, native support, and FFI where possible. No build-time hooks, symlinks, or Git hooks are used.
3. **Platform Support**: Android (using sqflite, google_mlkit_text_recognition, etc.) and Windows (using sqlite3, sqlite3_flutter_libs, sqflite_common_ffi, flutter_secure_storage_windows, etc.).
4. **Security**: Use `crypto` and `flutter_secure_storage` for secure data handling.
5. **Features**: Modular features in `lib/features/` for library, editor, PDF, AI, export, etc.
6. **State Management**: Riverpod or Bloc (choose later, both are included for flexibility).
7. **No Build-Time Hooks**: No code generation, build_runner, or pre-commit hooks. All packages are free and open source.

## Key Dependencies

- **Database**: sqflite (Android), sqlite3 + sqlite3_flutter_libs or sqflite_common_ffi (Windows), drift
- **Storage**: path_provider, archive
- **Security**: crypto, flutter_secure_storage (+ windows variant)
- **PDF**: pdf_render, pdfx
- **OCR**: google_mlkit_text_recognition (Android)
- **Audio**: record, flutter_sound
- **State**: riverpod, bloc

---

**This project is designed for maximum control, performance, and maintainability.**
