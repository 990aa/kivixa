// BrushParamsStore: Persists brush params per tool with migration-friendly mapping.
class BrushParams {
  double pressureSensitivity; // 0–2.0 (0–200%)
  double inkFlow; // 0–1.0 (0–100%)
  double opacity; // 0–1.0
  List<double> widthPresets; // e.g., [0.2, 1.0, 3.0] mm

  BrushParams({
    required this.pressureSensitivity,
    required this.inkFlow,
    required this.opacity,
    required this.widthPresets,
  });

  Map<String, dynamic> toMap() => {
    'pressureSensitivity': pressureSensitivity,
    'inkFlow': inkFlow,
    'opacity': opacity,
    'widthPresets': widthPresets,
  };

  static BrushParams fromMap(Map<String, dynamic> map) => BrushParams(
    pressureSensitivity: (map['pressureSensitivity'] ?? 1.0).toDouble(),
    inkFlow: (map['inkFlow'] ?? 1.0).toDouble(),
    opacity: (map['opacity'] ?? 1.0).toDouble(),
    widthPresets:
        (map['widthPresets'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [0.2, 1.0, 3.0],
  );
}

class BrushParamsStore {
  // toolId -> params (migration-friendly)
  final Map<String, Map<String, dynamic>> _store = {};

  void saveParams(String toolId, BrushParams params) {
    _store[toolId] = params.toMap();
  }

  BrushParams getParams(String toolId) {
    final map = _store[toolId] ?? {};
    return BrushParams.fromMap(map);
  }

  // For migration: update schema or map keys as needed in future
  void migrateParams(
    String toolId,
    Map<String, dynamic> Function(Map<String, dynamic>) migrator,
  ) {
    final old = _store[toolId] ?? {};
    _store[toolId] = migrator(old);
  }
}
