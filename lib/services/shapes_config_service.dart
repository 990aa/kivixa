// ShapesConfigService: Defines parameters and CRUD for shape presets.
class ShapeConfig {
  final String id;
  final String
  type; // line, arrow, dashed, wave, axis, cube, cone, cylinder, sphere
  final Map<String, dynamic> params;

  ShapeConfig({required this.id, required this.type, required this.params});

  ShapeConfig copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? params,
  }) => ShapeConfig(
    id: id ?? this.id,
    type: type ?? this.type,
    params: params ?? this.params,
  );
}

class ShapesConfigService {
  final Map<String, ShapeConfig> _presets = {};

  // Create or update a shape preset
  void upsertPreset(ShapeConfig config) {
    _presets[config.id] = config;
  }

  // Read a shape preset
  ShapeConfig? getPreset(String id) => _presets[id];

  // Delete a shape preset
  void deletePreset(String id) {
    _presets.remove(id);
  }

  // List all presets
  List<ShapeConfig> getAllPresets() => _presets.values.toList();
}
