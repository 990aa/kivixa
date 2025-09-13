
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kivixa/data/database.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class ExportManager {
  final AppDatabase _db;

  ExportManager(this._db);

  Future<int> exportToKivixa(String documentId, List<String> assetIds) async {
    final payload = {
      'documentId': documentId,
      'assetIds': assetIds,
    };
    final job = JobQueuesCompanion.insert(
      jobType: 'export_kivixa',
      status: 'pending',
      payload: jsonEncode(payload),
    );
    final result = await _db.into(_db.jobQueues).insert(job);
    _processJobs();
    return result;
  }

  Future<int> exportToPdf(String documentId) async {
    final payload = {'documentId': documentId};
    final job = JobQueuesCompanion.insert(
      jobType: 'export_pdf',
      status: 'pending',
      payload: jsonEncode(payload),
    );
    final result = await _db.into(_db.jobQueues).insert(job);
    _processJobs();
    return result;
  }

  Future<int> exportToImages(String documentId, int startPage, int endPage) async {
    final payload = {
      'documentId': documentId,
      'startPage': startPage,
      'endPage': endPage,
    };
    final job = JobQueuesCompanion.insert(
      jobType: 'export_images',
      status: 'pending',
      payload: jsonEncode(payload),
    );
    final result = await _db.into(_db.jobQueues).insert(job);
    _processJobs();
    return result;
  }

  Future<void> _processJobs() async {
    final pendingJobs = await (_db.select(_db.jobQueues)
          ..where((tbl) => tbl.status.equals('pending')))
        .get();

    for (final job in pendingJobs) {
      await _updateJobStatus(job.id, 'in_progress');
      try {
        switch (job.jobType) {
          case 'export_kivixa':
            await _handleKivixaExport(job);
            break;
          case 'export_pdf':
            await _handlePdfExport(job);
            break;
          case 'export_images':
            await _handleImagesExport(job);
            break;
        }
        await _updateJobStatus(job.id, 'completed');
      } catch (e) {
        await _updateJobStatus(job.id, 'failed');
      }
    }
  }

  Future<void> _updateJobStatus(int jobId, String status) async {
    await (_db.update(_db.jobQueues)..where((tbl) => tbl.id.equals(jobId)))
        .write(JobQueuesCompanion(status: Value(status)));
  }

  Future<void> _handleKivixaExport(JobQueue job) async {
    final payload = jsonDecode(job.payload);
    final documentId = payload['documentId'];
    // 1. Get database snapshot
    // 2. Get selected assets
    // 3. Create a zip archive
    // 4. Save the archive to a file
    throw UnimplementedError();
  }

  Future<void> _handlePdfExport(JobQueue job) async {
    // 1. Rasterize pages
    // 2. Rasterize ink
    // 3. Create a PDF document
    // 4. Save the PDF to a file
    throw UnimplementedError();
  }

  Future<void> _handleImagesExport(JobQueue job) async {
    // 1. For each page in range
    // 2. Rasterize page
    // 3. Save as image
    throw UnimplementedError();
  }
}
