import 'dart:ui';

enum BackgroundType {
  grid,
  line,
  dot,
}

class BackgroundStyle {
  final BackgroundType type;
  final Color color;
  final double spacing;

  BackgroundStyle({
    required this.type,
    required this.color,
    required this.spacing,
  });
}

class PageTemplate {
  final BackgroundStyle background;

  PageTemplate({required this.background});
}

class PageSettings {
  final PageTemplate? template;
  final BackgroundStyle? overrideBackground;

  PageSettings({this.template, this.overrideBackground});
}

class RasterizableDescriptor {
  final String cacheKey;
  final BackgroundStyle style;

  RasterizableDescriptor({required this.cacheKey, required this.style});
}

class PageTemplateResolver {
  RasterizableDescriptor resolve(PageSettings settings) {
    final style = settings.overrideBackground ?? settings.template?.background ?? _defaultBackground();

    final cacheKey = '${style.type}_${style.color.toARGB32()}_${style.spacing}'; // Changed .value to .toARGB32()

    return RasterizableDescriptor(cacheKey: cacheKey, style: style);
  }

  BackgroundStyle _defaultBackground() {
    return BackgroundStyle(
      type: BackgroundType.line,
      color: const Color(0xFFE0E0E0),
      spacing: 20.0,
    );
  }
}
