# PDFium WASM Module - Production Build Notes

## ⚠️ Debug Warning

During development and debug builds for Web, you may see this warning:

```
!DEBUG TIME WARNING: The app is bundling PDFium WASM module (about 4MB) as a part of the app.
For production use (not for Web/Debug), you'd better remove the PDFium WASM module.
```

## What Does This Mean?

The `pdfrx` package includes a PDFium WASM (WebAssembly) module that is approximately 4MB in size. This module is bundled with your app during debug builds for web development convenience. However, for production builds, this adds unnecessary size to your application.

## Production Build Configuration

### For Web Production Builds

When building for web production, you should configure the app to load PDFium from a CDN instead of bundling it:

1. **Remove the bundled WASM module** by configuring `pdfrx` to use external PDFium:

```dart
// In your PDF viewer initialization
PdfViewer.file(
  pdfPath,
  controller: _pdfController,
  params: PdfViewerParams(
    // ... other params
  ),
)
```

2. **Use CDN for PDFium WASM** by adding this to your `web/index.html`:

```html
<script>
  // Configure pdfrx to use CDN
  window.pdfrxWasmUrl = 'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js';
</script>
```

### For Mobile/Desktop Builds

The PDFium WASM module is **only relevant for Web builds**. For mobile (Android/iOS) and desktop (Windows/macOS/Linux) platforms, the native PDF rendering is used, so this warning does not apply.

## Build Commands

### Debug Build (Web)
```bash
flutter run -d chrome
```
The WASM module will be bundled (4MB overhead is acceptable for debug).

### Production Build (Web)
```bash
flutter build web --release
```
Configure to use CDN as described above to reduce bundle size.

### Production Build (Mobile/Desktop)
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# No action needed - WASM module is not included
```

## Performance Considerations

- **Debug builds**: The bundled WASM (4MB) is acceptable for development
- **Production Web**: Use CDN to reduce initial load time
- **Mobile/Desktop**: No impact - uses native PDF rendering

## Additional Resources

- [pdfrx GitHub Repository](https://github.com/espresso3389/pdfrx)
- [PDFium WASM Configuration](https://github.com/espresso3389/pdfrx/tree/master/packages/pdfrx#note-for-building-release-builds)
- [Production Build Best Practices](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx/README.md)

## Summary

✅ **Debug/Development**: Warning is expected and can be ignored  
✅ **Production Web**: Configure to use CDN for optimal performance  
✅ **Production Mobile/Desktop**: No action needed - warning does not apply
