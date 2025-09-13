enum RenderLayerType {
  pdfRaster,
  ink,
  shape,
  text,
  highlight,
}

class RenderLayer {
  final RenderLayerType type;
  final int zIndex;
  final dynamic data;

  RenderLayer({required this.type, required this.zIndex, this.data});
}

class RenderPlan {
  final List<RenderLayer> layers;

  RenderPlan({required this.layers});
}

class RenderPlanBuilder {
  RenderPlan build(List<RenderLayer> layers) {
    layers.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return RenderPlan(layers: layers);
  }
}

// Placeholder data classes
class PdfRasterData {}
class InkData {}
class ShapeData {}
class TextData {}
class HighlightData {}
