// EraserModesService: Persists eraser mode and pressure sensitivity in user settings/favorites.
enum EraserMode { pixel, stroke }

class EraserModesService {
  // Simulated user settings/favorites storage
  final Map<String, dynamic> _userSettings = {};

  void setEraserMode(EraserMode mode) {
    _userSettings['eraserMode'] = mode.name;
  }

  EraserMode getEraserMode() {
    final mode = _userSettings['eraserMode'];
    if (mode == 'stroke') return EraserMode.stroke;
    return EraserMode.pixel;
  }

  void setPressureSensitivity(double value) {
    _userSettings['eraserPressure'] = value;
  }

  double getPressureSensitivity() {
    return (_userSettings['eraserPressure'] as double?) ?? 1.0;
  }

  // Stroke erase: operate by stroke IDs for deterministic undo
  void eraseStrokesById(List<String> strokeIds) {
    // ... logic to erase strokes by ID ...
  }

  // Pixel erase: reserved for bitmap layers (future)
  void erasePixels(/* params for bitmap layer */) {
    // ... logic for pixel erase (future) ...
  }
}
