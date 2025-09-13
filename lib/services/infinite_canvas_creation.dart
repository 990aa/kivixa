import '../data/repository.dart';

class CanvasInitializationResult {
  final int documentId;
  final List<Map<String, dynamic>> initialTiles;
  final Map<String, dynamic> backgroundProperties;

  CanvasInitializationResult({
    required this.documentId,
    required this.initialTiles,
    required this.backgroundProperties,
  });
}

class InfiniteCanvasCreation {
  final Repository _repo;

  InfiniteCanvasCreation(this._repo);

  Future<CanvasInitializationResult> create(String name, {int? templateId}) async {
    // 1. Create the document
    final documentId = await _repo.createDocument({
      'name': name,
      'is_infinite': true, // Assuming a flag for infinite canvas
    });

    // 2. Apply template if provided
    if (templateId != null) {
      final template = await _repo.getTemplate(templateId);
      if (template != null) {
        // Apply template data to the document.
        // This is a simplified representation. A real implementation would be more complex.
        final content = template['content']; // Assuming content is stored in the template
        // Here you would parse the content and create the initial strokes, text blocks, etc.
      }
    }

    // 3. Create initial tiles
    // For a minimal grid, we can create a 3x3 grid of tiles around the origin.
    final initialTiles = <Map<String, dynamic>>[];
    for (var x = -1; x <= 1; x++) {
      for (var y = -1; y <= 1; y++) {
        final tile = {
          'document_id': documentId,
          'x': x,
          'y': y,
          'data': {}, // Empty data for now
        };
        await _repo.createMinimapTile(tile); // Assuming createMinimapTile can be used for this
        initialTiles.add(tile);
      }
    }

    // 4. Define background properties
    final backgroundProperties = {
      'color': 0xFFFFFFFF, // White background
      'grid_size': 20, // 20 pixels
    };

    return CanvasInitializationResult(
      documentId: documentId,
      initialTiles: initialTiles,
      backgroundProperties: backgroundProperties,
    );
  }
}