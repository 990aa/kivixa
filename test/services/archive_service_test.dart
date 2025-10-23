import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kivixa/services/archive_service.dart';
import 'package:kivixa/database/database_helper.dart';
import 'package:kivixa/database/folder_repository.dart';
import 'package:kivixa/database/document_repository.dart';
import 'package:kivixa/models/folder.dart';
import 'package:kivixa/models/drawing_document.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ArchiveService archiveService;
  late FolderRepository folderRepo;
  late DocumentRepository docRepo;
  late Directory testDir;

  setUp(() async {
    // Create test directory
    testDir = await Directory.systemTemp.createTemp('kivixa_test_');
    
    // Initialize database and services
    await DatabaseHelper.initialize(testDir.path);
    folderRepo = FolderRepository();
    docRepo = DocumentRepository();
    archiveService = ArchiveService();
  });

  tearDown(() async {
    // Clean up test directory
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await DatabaseHelper.close();
  });

  group('Archive Creation', () {
    test('should create archive from folder', () async {
      // Create test folder
      final folder = Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final folderId = await folderRepo.create(folder);

      // Create test documents
      final doc1 = DrawingDocument(
        name: 'Test Doc 1',
        type: DocumentType.canvas,
        folderId: folderId,
        filePath: path.join(testDir.path, 'doc1.json'),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await docRepo.create(doc1);

      // Create archive
      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folderId,
      );

      expect(archive, isNotNull);
      expect(archive.name, 'Test Archive');
      expect(archive.folderId, folderId);
      expect(await File(archive.archivePath).exists(), true);
    });

    test('should create archive with custom compression level', () async {
      final folder = Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final folderId = await folderRepo.create(folder);

      final archive = await archiveService.createArchive(
        name: 'Compressed Archive',
        folderId: folderId,
        compressionLevel: 9, // Maximum compression
      );

      expect(archive, isNotNull);
      expect(archive.compressionLevel, 9);
    });

    test('should fail to create archive from non-existent folder', () async {
      expect(
        () => archiveService.createArchive(
          name: 'Bad Archive',
          folderId: 99999, // Non-existent folder
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Archive Restoration', () {
    test('should restore archive to folder', () async {
      // Create and archive a folder
      final folder = Folder(
        name: 'Original Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final folderId = await folderRepo.create(folder);

      final doc = DrawingDocument(
        name: 'Original Doc',
        type: DocumentType.canvas,
        folderId: folderId,
        filePath: path.join(testDir.path, 'original.json'),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await docRepo.create(doc);

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folderId,
      );

      // Delete original folder
      await folderRepo.delete(folderId);

      // Restore archive
      final restoredFolderId = await archiveService.restoreArchive(
        archiveId: archive.id!,
      );

      expect(restoredFolderId, isNotNull);
      final restoredFolder = await folderRepo.findById(restoredFolderId);
      expect(restoredFolder, isNotNull);
      expect(restoredFolder!.name, 'Original Folder');

      // Check documents were restored
      final restoredDocs = await docRepo.getByFolder(restoredFolderId);
      expect(restoredDocs.length, 1);
      expect(restoredDocs[0].name, 'Original Doc');
    });

    test('should restore archive to custom location', () async {
      final folder = Folder(
        name: 'Source Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final folderId = await folderRepo.create(folder);

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folderId,
      );

      // Create target folder
      final targetFolder = Folder(
        name: 'Target Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final targetId = await folderRepo.create(targetFolder);

      // Restore to target
      final restoredFolderId = await archiveService.restoreArchive(
        archiveId: archive.id!,
        targetFolderId: targetId,
      );

      final restoredFolder = await folderRepo.findById(restoredFolderId);
      expect(restoredFolder!.parentId, targetId);
    });
  });

  group('Archive Management', () {
    test('should list all archives', () async {
      // Create multiple archives
      final folder1 = await folderRepo.create(Folder(
        name: 'Folder 1',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      final folder2 = await folderRepo.create(Folder(
        name: 'Folder 2',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      await archiveService.createArchive(name: 'Archive 1', folderId: folder1);
      await archiveService.createArchive(name: 'Archive 2', folderId: folder2);

      final archives = await archiveService.getAllArchives();
      expect(archives.length, greaterThanOrEqualTo(2));
    });

    test('should delete archive', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folder,
      );

      // Delete archive
      await archiveService.deleteArchive(archive.id!);

      // Verify archive file is deleted
      expect(await File(archive.archivePath).exists(), false);

      // Verify archive is removed from database
      final archives = await archiveService.getAllArchives();
      expect(
        archives.where((a) => a.id == archive.id).isEmpty,
        true,
      );
    });

    test('should get archive size', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folder,
      );

      final size = await archiveService.getArchiveSize(archive.id!);
      expect(size, greaterThan(0));
    });
  });

  group('Auto-Archiving', () {
    test('should enable auto-archiving for folder', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Auto Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      await archiveService.enableAutoArchiving(
        folderId: folder,
        maxAge: const Duration(days: 30),
      );

      final settings = await archiveService.getAutoArchivingSettings(folder);
      expect(settings, isNotNull);
      expect(settings!['enabled'], true);
      expect(settings['maxAge'], const Duration(days: 30).inMilliseconds);
    });

    test('should disable auto-archiving for folder', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Auto Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      await archiveService.enableAutoArchiving(
        folderId: folder,
        maxAge: const Duration(days: 30),
      );
      await archiveService.disableAutoArchiving(folder);

      final settings = await archiveService.getAutoArchivingSettings(folder);
      expect(settings?['enabled'] ?? false, false);
    });

    test('should archive old documents automatically', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Auto Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      // Create old document
      final oldDoc = DrawingDocument(
        name: 'Old Doc',
        type: DocumentType.canvas,
        folderId: folder,
        filePath: path.join(testDir.path, 'old.json'),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        modifiedAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      await docRepo.create(oldDoc);

      // Enable auto-archiving with 30-day threshold
      await archiveService.enableAutoArchiving(
        folderId: folder,
        maxAge: const Duration(days: 30),
      );

      // Run auto-archiving
      final archivedCount = await archiveService.runAutoArchiving();
      expect(archivedCount, greaterThan(0));

      // Verify archive was created
      final archives = await archiveService.getArchivesByFolder(folder);
      expect(archives.length, greaterThan(0));
    });
  });

  group('Archive Integrity', () {
    test('should verify archive integrity', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folder,
      );

      final isValid = await archiveService.verifyArchiveIntegrity(archive.id!);
      expect(isValid, true);
    });

    test('should detect corrupted archive', () async {
      final folder = await folderRepo.create(Folder(
        name: 'Test Folder',
        parentId: null,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      final archive = await archiveService.createArchive(
        name: 'Test Archive',
        folderId: folder,
      );

      // Corrupt the archive file
      final archiveFile = File(archive.archivePath);
      await archiveFile.writeAsBytes([0, 0, 0, 0]);

      final isValid = await archiveService.verifyArchiveIntegrity(archive.id!);
      expect(isValid, false);
    });
  });
}
