import 'package:kivixa/services/export_manager.dart';
import 'package:kivixa/services/offline_queue.dart';
import 'package:kivixa/data/database.dart';

enum ExportFormat {
  nativeZip,
  flatPdf,
  images,
}

class ExportOptions {
  final ExportFormat format;
  final String documentId;
  final String destination;

  ExportOptions({
    required this.format,
    required this.documentId,
    required this.destination,
  });
}

class ImageExportOptions extends ExportOptions {
  final int dpi;
  final int quality;

  ImageExportOptions({
    required String documentId,
    required String destination,
    this.dpi = 300,
    this.quality = 90,
  }) : super(
          format: ExportFormat.images,
          documentId: documentId,
          destination: destination,
        );
}

class ExportService {
  final ExportManager _exportManager;
  final OfflineQueue _offlineQueue;

  ExportService(this._exportManager, this._offlineQueue);

  Future<int> export(ExportOptions options) async {
    final payload = {
      'documentId': options.documentId,
      'destination': options.destination,
    };

    if (options is ImageExportOptions) {
      payload['dpi'] = options.dpi;
      payload['quality'] = options.quality;
    }

    final jobId = await _offlineQueue.enqueue(options.format.toString(), payload);
    return jobId;
  }
}
