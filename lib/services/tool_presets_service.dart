// ToolPresetsService: Manages tool presets and toolbox layouts, supports bulk import/export.
import 'dart:convert';

class ToolPreset {
  final String toolId;
  final Map<String, dynamic> params;

  ToolPreset({required this.toolId, required this.params});

  Map<String, dynamic> toJson() => {'toolId': toolId, 'params': params};
  static ToolPreset fromJson(Map<String, dynamic> json) => ToolPreset(
    toolId: json['toolId'],
    params: Map<String, dynamic>.from(json['params']),
  );
}

class ToolPresetsService {
  final Map<String, ToolPreset> _presets = {};
  List<String> _toolboxLayout = [];

  // Persist a preset
  void savePreset(ToolPreset preset) {
    _presets[preset.toolId] = preset;
  }

  // Get a preset
  ToolPreset? getPreset(String toolId) => _presets[toolId];

  // Set toolbox layout
  void setToolboxLayout(List<String> layout) {
    _toolboxLayout = layout;
  }

  // Get toolbox layout
  List<String> getToolboxLayout() => List.unmodifiable(_toolboxLayout);

  // Fetch all presets and layout (simulate joined query)
  Map<String, dynamic> fetchAll() => {
    'presets': _presets.values.map((p) => p.toJson()).toList(),
    'layout': _toolboxLayout,
  };

  // Bulk import presets from JSON
  void importFromJson(String jsonStr) {
    final data = json.decode(jsonStr);
    if (data is Map && data['presets'] is List) {
      for (var p in data['presets']) {
        final preset = ToolPreset.fromJson(Map<String, dynamic>.from(p));
        _presets[preset.toolId] = preset;
      }
    }
    if (data['layout'] is List) {
      _toolboxLayout = List<String>.from(data['layout']);
    }
  }

  // Export all presets and layout to JSON
  String exportToJson() {
    final data = fetchAll();
    return json.encode(data);
  }
}
