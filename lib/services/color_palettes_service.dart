// ColorPalettesService: Manages global and per-tool palettes, starred sets, custom entries, and safe cascades.
class ColorPalette {
  final String id;
  final List<String> colors; // Hex strings
  final bool isStarred;
  final bool isCustom;

  ColorPalette({
    required this.id,
    required this.colors,
    this.isStarred = false,
    this.isCustom = false,
  });

  ColorPalette copyWith({
    List<String>? colors,
    bool? isStarred,
    bool? isCustom,
  }) => ColorPalette(
    id: id,
    colors: colors ?? this.colors,
    isStarred: isStarred ?? this.isStarred,
    isCustom: isCustom ?? this.isCustom,
  );
}

class ColorPalettesService {
  final Map<String, ColorPalette> _globalPalettes = {};
  final Map<String, Map<String, ColorPalette>> _toolPalettes = {};
  final Set<String> _starredPaletteIds = {};
  final List<String> _favorites = [];

  // Add or update a palette (global or per-tool)
  void upsertPalette(ColorPalette palette, {String? toolId}) {
    if (toolId == null) {
      _globalPalettes[palette.id] = palette;
    } else {
      _toolPalettes.putIfAbsent(toolId, () => {})[palette.id] = palette;
    }
    if (palette.isStarred) _starredPaletteIds.add(palette.id);
  }

  // Delete palette (long-press)
  void deletePalette(String paletteId, {String? toolId}) {
    if (toolId == null) {
      _globalPalettes.remove(paletteId);
    } else {
      _toolPalettes[toolId]?.remove(paletteId);
    }
    _starredPaletteIds.remove(paletteId);
    _favorites.removeWhere((id) => id == paletteId); // Safe cascade
  }

  // Get palettes (global or per-tool)
  List<ColorPalette> getPalettes({String? toolId}) {
    if (toolId == null) return _globalPalettes.values.toList();
    return _toolPalettes[toolId]?.values.toList() ?? [];
  }

  // Star/unstar a palette
  void setStarred(String paletteId, bool starred) {
    if (starred) {
      _starredPaletteIds.add(paletteId);
    } else {
      _starredPaletteIds.remove(paletteId);
    }
    if (_globalPalettes.containsKey(paletteId)) {
      _globalPalettes[paletteId] = _globalPalettes[paletteId]!.copyWith(
        isStarred: starred,
      );
    }
    for (var tool in _toolPalettes.keys) {
      if (_toolPalettes[tool]!.containsKey(paletteId)) {
        _toolPalettes[tool]![paletteId] = _toolPalettes[tool]![paletteId]!
            .copyWith(isStarred: starred);
      }
    }
  }

  // Add to favorites (max 10)
  void addToFavorites(String paletteId) {
    if (!_favorites.contains(paletteId) && _favorites.length < 10) {
      _favorites.add(paletteId);
    }
  }

  // Remove from favorites
  void removeFromFavorites(String paletteId) {
    _favorites.remove(paletteId);
  }

  // Get consistent state snapshot for UI
  Map<String, dynamic> getStateSnapshot() => {
    'globalPalettes': _globalPalettes.values.toList(),
    'toolPalettes': _toolPalettes,
    'starred': _starredPaletteIds.toList(),
    'favorites': _favorites,
  };
}
