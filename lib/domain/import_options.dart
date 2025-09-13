import 'package:kivixa/services/import_manager.dart';

enum ImportSource {
  pdf,
  image,
  office,
}

enum DedupStrategy {
  keepBoth,
  overwrite,
  skip,
}

enum ThumbnailPolicy {
  onImport,
  lazy,
}

class ImportOptions {
  final ImportSource source;
  final String path;
  final DedupStrategy dedupStrategy;
  final ThumbnailPolicy thumbnailPolicy;

  ImportOptions({
    required this.source,
    required this.path,
    this.dedupStrategy = DedupStrategy.keepBoth,
    this.thumbnailPolicy = ThumbnailPolicy.onImport,
  });
}

class ImportService {
  final ImportManager _importManager;

  ImportService(this._importManager);

  Future<String> importFile(ImportOptions options) async {
    // In a real app, you would use the options to change the import behavior.
    // For example, the dedupStrategy would be used to check for existing files.
    // The thumbnailPolicy would determine if thumbnails are generated immediately.
    return await _importManager.importFile(options.path);
  }
}
