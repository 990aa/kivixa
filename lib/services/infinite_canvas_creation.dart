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
  final DocumentRepository _repo; // Changed from Repository

  InfiniteCanvasCreation(this._repo);

  Future<CanvasInitializationResult> create(String name, {int? templateId}) async {
    // 1. Create the document
    // Adjusted to call createDocument with the name. 
    // Handling of 'is_infinite' might need to be done in a subsequent update call
    // or by modifying DocumentRepository.createDocument if schema supports it directly.
    final documentData = await _repo.createDocument(name);
    final documentId = documentData.id; // Assuming DocumentData has an id field

    // TODO: If 'is_infinite' needs to be set, you might need an update method:
    // await _repo.updateDocument(documentData.copyWith(isInfinite: true)); 

    // 2. Apply template if provided
    if (templateId != null) {
      // This method will need to be added to DocumentRepository
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
        // This method will need to be added to DocumentRepository
        await _repo.createMinimapTile(tile);
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
