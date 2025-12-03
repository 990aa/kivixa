# Rust Library for Kivixa

This package wraps the native Rust library for Flutter Rust Bridge integration.

## Build

The Rust library is located in `../native/`. Build it with:

```bash
cd ../native
cargo build --release
```

## Generate Bindings

From the project root:

```bash
flutter_rust_bridge_codegen generate
```
