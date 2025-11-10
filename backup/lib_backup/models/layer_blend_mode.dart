import 'package:flutter/material.dart';

/// Enum for layer blending modes with Flutter BlendMode mapping
enum LayerBlendMode {
  // Basic blend modes
  normal(BlendMode.srcOver, 'Normal'),
  multiply(BlendMode.multiply, 'Multiply'),
  screen(BlendMode.screen, 'Screen'),
  overlay(BlendMode.overlay, 'Overlay'),

  // Darken modes
  darken(BlendMode.darken, 'Darken'),
  colorBurn(BlendMode.colorBurn, 'Color Burn'),

  // Lighten modes
  lighten(BlendMode.lighten, 'Lighten'),
  colorDodge(BlendMode.colorDodge, 'Color Dodge'),

  // Light modes
  hardLight(BlendMode.hardLight, 'Hard Light'),
  softLight(BlendMode.softLight, 'Soft Light'),

  // Difference modes
  difference(BlendMode.difference, 'Difference'),
  exclusion(BlendMode.exclusion, 'Exclusion'),

  // Color modes
  hue(BlendMode.hue, 'Hue'),
  saturation(BlendMode.saturation, 'Saturation'),
  color(BlendMode.color, 'Color'),
  luminosity(BlendMode.luminosity, 'Luminosity'),

  // Math modes
  plus(BlendMode.plus, 'Add'),
  modulate(BlendMode.modulate, 'Modulate'),

  // Alpha modes
  src(BlendMode.src, 'Source'),
  dst(BlendMode.dst, 'Destination'),
  srcOver(BlendMode.srcOver, 'Source Over'),
  dstOver(BlendMode.dstOver, 'Destination Over'),
  srcIn(BlendMode.srcIn, 'Source In'),
  dstIn(BlendMode.dstIn, 'Destination In'),
  srcOut(BlendMode.srcOut, 'Source Out'),
  dstOut(BlendMode.dstOut, 'Destination Out'),
  srcATop(BlendMode.srcATop, 'Source Atop'),
  dstATop(BlendMode.dstATop, 'Destination Atop'),
  xor(BlendMode.xor, 'XOR'),
  clear(BlendMode.clear, 'Clear');

  const LayerBlendMode(this.blendMode, this.displayName);

  /// The Flutter BlendMode value
  final BlendMode blendMode;

  /// Human-readable name for UI display
  final String displayName;

  /// Get LayerBlendMode from BlendMode
  static LayerBlendMode fromBlendMode(BlendMode mode) {
    return LayerBlendMode.values.firstWhere(
      (e) => e.blendMode == mode,
      orElse: () => LayerBlendMode.normal,
    );
  }

  /// Get LayerBlendMode from string name
  static LayerBlendMode fromString(String name) {
    try {
      return LayerBlendMode.values.firstWhere(
        (e) => e.name == name,
        orElse: () => LayerBlendMode.normal,
      );
    } catch (e) {
      return LayerBlendMode.normal;
    }
  }

  /// Get all creative/artistic blend modes (most commonly used)
  static List<LayerBlendMode> getCreativeModes() {
    return [
      normal,
      multiply,
      screen,
      overlay,
      darken,
      lighten,
      colorDodge,
      colorBurn,
      hardLight,
      softLight,
      difference,
      exclusion,
      hue,
      saturation,
      color,
      luminosity,
    ];
  }

  /// Get all technical/alpha blend modes
  static List<LayerBlendMode> getTechnicalModes() {
    return [
      src,
      dst,
      srcOver,
      dstOver,
      srcIn,
      dstIn,
      srcOut,
      dstOut,
      srcATop,
      dstATop,
      xor,
      clear,
    ];
  }

  /// Get blend mode description for tooltips
  String getDescription() {
    switch (this) {
      case normal:
        return 'Default blending mode';
      case multiply:
        return 'Darkens by multiplying color values';
      case screen:
        return 'Lightens by inverting, multiplying, and inverting';
      case overlay:
        return 'Combines multiply and screen based on base color';
      case darken:
        return 'Selects darker of the two colors';
      case lighten:
        return 'Selects lighter of the two colors';
      case colorDodge:
        return 'Brightens base color to reflect blend color';
      case colorBurn:
        return 'Darkens base color to reflect blend color';
      case hardLight:
        return 'Strong contrast, like harsh spotlight';
      case softLight:
        return 'Subtle contrast, like diffused spotlight';
      case difference:
        return 'Subtracts darker from lighter color';
      case exclusion:
        return 'Similar to difference but lower contrast';
      case hue:
        return 'Uses hue of blend color with base saturation and luminosity';
      case saturation:
        return 'Uses saturation of blend color with base hue and luminosity';
      case color:
        return 'Uses hue and saturation of blend color with base luminosity';
      case luminosity:
        return 'Uses luminosity of blend color with base hue and saturation';
      case plus:
        return 'Adds color values (lighter result)';
      case modulate:
        return 'Multiplies alpha and color channels';
      default:
        return 'Advanced alpha compositing mode';
    }
  }
}
