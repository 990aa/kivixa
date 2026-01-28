import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

class FileManager {
  FileManager._();

  static final log = Logger('FileManager');

  static const appRootDirectoryPrefix = 'kivixa';

  static late String documentsDirectory;

  static final fileWriteStream = StreamController<FileOperation>.broadcast();

  static String _sanitisePath(String path) =>
      File(path).path.replaceAll('\\', '/');

  static final assetFileRegex = RegExp(r'\.kvx?\.[\dp]+$');

  static Future<void> init({
    String? documentsDirectory,
    bool shouldWatchRootDirectory = true,
  }) async {
    FileManager.documentsDirectory =
        documentsDirectory ?? await getDocumentsDirectory();

    if (shouldWatchRootDirectory) unawaited(watchRootDirectory());
  }

  static Future<String> getDocumentsDirectory() async =>
      stows.customDataDir.value ?? await getDefaultDocumentsDirectory();

  static Future<String> getDefaultDocumentsDirectory() async =>
      '${(await getApplicationDocumentsDirectory()).path}/$appRootDirectoryPrefix';

  static Future<void> migrateDataDir() async {
    final oldDir = Directory(documentsDirectory);
    final newDir = Directory(await getDocumentsDirectory());
    if (oldDir.path == newDir.path) return;
    log.info('Migrating data directory from $oldDir to $newDir');

    late final oldDirEmpty = oldDir.existsSync()
        ? oldDir.listSync().isEmpty
        : true;
    late final newDirEmpty = newDir.existsSync()
        ? newDir.listSync().isEmpty
        : true;

    if (!oldDirEmpty && !newDirEmpty) {
      log.severe('New and old data directory aren\'t empty, can\'t migrate');
      return;
    }

    documentsDirectory = newDir.path;
    if (oldDirEmpty) {
      log.fine('Old data directory is empty or missing, nothing to migrate');
    } else {
      await moveDirContents(oldDir: oldDir, newDir: newDir);
      await oldDir.delete(recursive: true);
    }
  }

  static Future<void> moveDirContents({
    required Directory oldDir,
    required Directory newDir,
  }) async {
    await newDir.create(recursive: true);

    await for (final entity in oldDir.list(recursive: true)) {
      final relative = p.relative(entity.path, from: oldDir.path);
      final targetPath = p.join(newDir.path, relative);

      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
        continue;
      }

      if (entity is File) {
        await entity.parent.create(recursive: true);

        try {
          await entity.rename(targetPath);
        } on FileSystemException catch (e) {
          const exdev = 18;
          if (e.osError?.errorCode == exdev) {
            await entity.copy(targetPath);
            await entity.delete();
          } else {
            rethrow;
          }
        }
      }
    }
  }

  @visibleForTesting
  static Future<void> watchRootDirectory() async {
    final rootDir = Directory(documentsDirectory);
    await rootDir.create(recursive: true);
    rootDir.watch(recursive: true).listen((FileSystemEvent event) {
      final type =
          event.type == FileSystemEvent.create ||
              event.type == FileSystemEvent.modify ||
              event.type == FileSystemEvent.move
          ? FileOperationType.write
          : FileOperationType.delete;
      final String path = event.path
          .replaceAll('\\', '/')
          .replaceFirst(documentsDirectory, '');
      broadcastFileWrite(type, path);
    });
  }

  @visibleForTesting
  static void broadcastFileWrite(FileOperationType type, String path) async {
    if (!fileWriteStream.hasListener) return;

    if (path.endsWith(Editor.extension)) {
      path = path.substring(0, path.length - Editor.extension.length);
    } else if (path.endsWith(Editor.extensionOldJson)) {
      path = path.substring(0, path.length - Editor.extensionOldJson.length);
    }

    fileWriteStream.add(FileOperation(type, path));
  }

  static Future<Uint8List?> readFile(String filePath, {int retries = 3}) async {
    log.fine(
      'FileManager.readFile input: $filePath, docDir: $documentsDirectory',
    );
    filePath = _sanitisePath(filePath);
    log.fine('FileManager.readFile sanitised: $filePath');

    Uint8List? result;
    final file = getFile(filePath);
    log.fine(
      'FileManager.readFile checking: ${file.path}, exists: ${file.existsSync()}',
    );
    if (file.existsSync()) {
      result = await file.readAsBytes();
      if (result.isEmpty) result = null;
    } else {
      retries = 0;
    }

    if (result == null && retries > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
      return readFile(filePath, retries: retries - 1);
    }
    return result;
  }

  @visibleForTesting
  static var shouldUseRawFilePath = false;

  static File getFile(String filePath) {
    if (shouldUseRawFilePath) {
      return File(filePath);
    } else {
      assert(
        filePath.startsWith('/'),
        'Expected filePath to start with a slash, got $filePath',
      );
      return File(documentsDirectory + filePath);
    }
  }

  static Directory getRootDirectory() => Directory(documentsDirectory);

  static Future<void> writeFile(
    String filePath,
    List<int> toWrite, {
    bool awaitWrite = false,
    DateTime? lastModified,
  }) async {
    filePath = _sanitisePath(filePath);
    log.fine('Writing to $filePath');

    await _saveFileAsRecentlyAccessed(filePath);

    final file = getFile(filePath);
    await _createFileDirectory(filePath);
    Future writeFuture = Future.wait([
      file.writeAsBytes(toWrite).then((file) async {
        if (lastModified != null) await file.setLastModified(lastModified);
      }),
      if (filePath.endsWith(Editor.extension))
        getFile(
          '${filePath.substring(0, filePath.length - Editor.extension.length)}'
          '${Editor.extensionOldJson}',
        ).delete().catchError(
          (_) => File(''),
          test: (e) => e is PathNotFoundException || e is PathAccessException,
        ),
    ]);

    void afterWrite() {
      broadcastFileWrite(FileOperationType.write, filePath);
      if (filePath.endsWith(Editor.extension)) {
        _removeReferences(
          '${filePath.substring(0, filePath.length - Editor.extension.length)}'
          '${Editor.extensionOldJson}',
        );
      }
    }

    writeFuture = writeFuture.then((_) => afterWrite());
    if (awaitWrite) await writeFuture;
  }

  static Future<void> createFolder(String folderPath) async {
    folderPath = _sanitisePath(folderPath);

    final dir = Directory(documentsDirectory + folderPath);
    await dir.create(recursive: true);
  }

  static Future exportFile(
    String fileName,
    List<int> bytes, {
    bool isImage = false,
    required BuildContext context,
  }) async {
    File? tempFile;
    Future<File> getTempFile() async {
      final tempFolder = (await getTemporaryDirectory()).path;
      final file = File('$tempFolder/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    }

    if (Platform.isAndroid) {
      if (isImage) {
        final permissionGranted = await _requestPhotosPermission();
        if (permissionGranted) {
          await SaverGallery.saveImage(
            Uint8List.fromList(bytes),
            fileName: fileName,
            androidRelativePath: 'Pictures/kivixa',
            skipIfExists: true,
          );
        }
      } else {
        tempFile = await getTempFile();
        await SharePlus.instance.share(
          ShareParams(files: [XFile(tempFile.path)]),
        );
      }
    } else {
      final outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
        initialDirectory: (await getDownloadsDirectory())?.path,
        type: FileType.custom,
        allowedExtensions: [fileName.split('.').last],
      );
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    }

    await tempFile?.delete();
  }

  static Future<bool> _requestPhotosPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final sdkInt = await DeviceInfoPlugin().androidInfo.then(
      (info) => info.version.sdkInt,
    );
    if (sdkInt > 33) {
      return await Permission.photos.request().isGranted;
    } else {
      return await Permission.storage.request().isGranted;
    }
  }

  static Future<String> moveFile(
    String fromPath,
    String toPath, {
    bool replaceExistingFile = false,
    bool alsoMoveAssets = true,
  }) async {
    fromPath = _sanitisePath(fromPath);
    toPath = _sanitisePath(toPath);

    if (!toPath.contains('/')) {
      toPath = fromPath.substring(0, fromPath.lastIndexOf('/') + 1) + toPath;
    }

    if (!replaceExistingFile || Editor.isReservedPath(toPath)) {
      toPath = await suffixFilePathToMakeItUnique(
        toPath,
        currentPath: fromPath,
      );
    }

    if (fromPath == toPath) return toPath;

    final fromFile = getFile(fromPath);
    final toFile = getFile(toPath);
    await _createFileDirectory(toPath);
    if (fromFile.existsSync()) {
      await fromFile.rename(toFile.path);
    } else {
      log.warning('Tried to move non-existent file from $fromPath to $toPath');
    }

    _renameReferences(fromPath, toPath);
    broadcastFileWrite(FileOperationType.delete, fromPath);
    broadcastFileWrite(FileOperationType.write, toPath);

    if (alsoMoveAssets && !assetFileRegex.hasMatch(fromPath)) {
      final assets = <String>[];
      for (int assetNumber = 0; true; assetNumber++) {
        final assetFile = getFile('$fromPath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add('$assetNumber');
        } else {
          break;
        }
      }
      {
        const assetNumber = 'p';
        final assetFile = getFile('$fromPath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add(assetNumber);
        }
      }

      await Future.wait([
        for (final assetNumber in assets)
          moveFile(
            '$fromPath.$assetNumber',
            '$toPath.$assetNumber',
            replaceExistingFile: replaceExistingFile,
          ),
      ]);
    }

    return toPath;
  }

  static Future deleteFile(
    String filePath, {
    bool alsoDeleteAssets = true,
  }) async {
    filePath = _sanitisePath(filePath);

    final file = getFile(filePath);
    if (!file.existsSync()) return;
    await file.delete();

    _removeReferences(filePath);
    broadcastFileWrite(FileOperationType.delete, filePath);

    if (alsoDeleteAssets && !assetFileRegex.hasMatch(filePath)) {
      final assets = <int>[];
      for (int assetNumber = 0; true; assetNumber++) {
        final assetFile = getFile('$filePath.$assetNumber');
        if (assetFile.existsSync()) {
          assets.add(assetNumber);
        } else {
          break;
        }
      }

      final previewFile = getFile('$filePath.p');
      await Future.wait([
        for (final assetNumber in assets)
          deleteFile('$filePath.$assetNumber', alsoDeleteAssets: false),
        if (previewFile.existsSync())
          deleteFile('$filePath.p', alsoDeleteAssets: false),
      ]);
    }
  }

  static Future removeUnusedAssets(
    String filePath, {
    required int numAssets,
  }) async {
    final futures = <Future>[];

    for (int assetNumber = numAssets; true; assetNumber++) {
      final assetPath = '$filePath.$assetNumber';
      if (getFile(assetPath).existsSync()) {
        futures.add(deleteFile(assetPath));
      } else {
        break;
      }
    }

    await Future.wait(futures);
  }

  static Future renameDirectory(String directoryPath, String newName) async {
    directoryPath = _sanitisePath(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    final List<String> children = [];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        children.add(entity.path.substring(directory.path.length));
      }
    }

    final String newPath =
        directoryPath.substring(0, directoryPath.lastIndexOf('/') + 1) +
        newName;
    await directory.rename(documentsDirectory + newPath);

    for (final child in children) {
      _renameReferences(directoryPath + child, newPath + child);
      broadcastFileWrite(FileOperationType.delete, directoryPath + child);
      broadcastFileWrite(FileOperationType.write, newPath + child);
    }
  }

  static Future deleteDirectory(
    String directoryPath, [
    bool recursive = true,
  ]) async {
    directoryPath = _sanitisePath(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          await deleteFile(entity.path.substring(documentsDirectory.length));
        }
      }
    }

    await directory.delete(recursive: recursive);
  }

  /// Moves a directory to a new location.
  /// [fromPath] is the current full path of the directory.
  /// [toPath] is the destination full path where the directory should be moved.
  static Future<void> moveDirectory(String fromPath, String toPath) async {
    fromPath = _sanitisePath(fromPath);
    toPath = _sanitisePath(toPath);

    if (fromPath == toPath) return;

    final fromDirectory = Directory(documentsDirectory + fromPath);
    if (!fromDirectory.existsSync()) {
      log.warning('Tried to move non-existent directory from $fromPath');
      return;
    }

    // Collect all files in the source directory for reference updates
    final List<String> children = [];
    await for (final entity in fromDirectory.list(recursive: true)) {
      if (entity is File) {
        children.add(entity.path.substring(documentsDirectory.length));
      }
    }

    // Ensure the parent directory of the destination exists
    final toParent = Directory(
      documentsDirectory + toPath.substring(0, toPath.lastIndexOf('/')),
    );
    if (!toParent.existsSync()) {
      await toParent.create(recursive: true);
    }

    // Move the directory
    await fromDirectory.rename(documentsDirectory + toPath);

    // Update references for all files
    for (final childPath in children) {
      final relativePath = childPath.substring(fromPath.length);
      final newChildPath = toPath + relativePath;
      _renameReferences(childPath, newChildPath);
      broadcastFileWrite(FileOperationType.delete, childPath);
      broadcastFileWrite(FileOperationType.write, newChildPath);
    }
  }

  static Future<DirectoryChildren?> getChildrenOfDirectory(
    String directory, {
    bool includeExtensions = false,
    bool includeAssets = false,
  }) async {
    assert(
      !includeAssets || includeExtensions,
      'includeAssets can\'t be true without includeExtensions',
    );

    directory = _sanitisePath(directory);
    if (!directory.endsWith('/')) directory += '/';

    final List<String> directories = [], files = [];
    final Map<String, KivixaFileType> fileTypes = {};

    final dir = Directory(documentsDirectory + directory);
    if (!dir.existsSync()) return null;

    final int directoryPrefixLength = directory.endsWith('/')
        ? directory.length
        : directory.length + 1;

    // Process directory listing and track file types
    final entities = await dir.list().toList();
    for (final entity in entities) {
      final filePath = entity.path.substring(documentsDirectory.length);

      if (entity is Directory) {
        final childName = filePath.substring(directoryPrefixLength);
        // Hidden directories that should not appear in the browse view
        const hiddenDirectories = {'plugins', '.lifegit', 'models'};
        if (!hiddenDirectories.contains(childName) &&
            !directories.contains(childName)) {
          directories.add(childName);
        }
        continue;
      }

      if (Editor.isReservedPath(filePath)) continue;

      final iskvx = filePath.endsWith(Editor.extension);
      final iskvx1 = filePath.endsWith(Editor.extensionOldJson);
      final ismd = filePath.endsWith('.md');
      final iskvtx = filePath.endsWith(TextFileEditor.internalExtension);

      String? childName;
      KivixaFileType? fileType;

      if (!includeExtensions) {
        if (iskvx) {
          childName = filePath.substring(
            directoryPrefixLength,
            filePath.length - Editor.extension.length,
          );
          fileType = KivixaFileType.handwritten;
        } else if (iskvx1) {
          childName = filePath.substring(
            directoryPrefixLength,
            filePath.length - Editor.extensionOldJson.length,
          );
          fileType = KivixaFileType.handwritten;
        } else if (ismd) {
          childName = filePath.substring(
            directoryPrefixLength,
            filePath.length - '.md'.length,
          );
          fileType = KivixaFileType.markdown;
        } else if (iskvtx) {
          childName = filePath.substring(
            directoryPrefixLength,
            filePath.length - TextFileEditor.internalExtension.length,
          );
          fileType = KivixaFileType.text;
        }
      } else {
        if (!includeAssets) {
          final isAsset = !iskvx && !iskvx1 && !ismd && !iskvtx;
          if (isAsset) continue;
        }
        childName = filePath.substring(directoryPrefixLength);
        if (iskvx || iskvx1) {
          fileType = KivixaFileType.handwritten;
        } else if (ismd) {
          fileType = KivixaFileType.markdown;
        } else if (iskvtx) {
          fileType = KivixaFileType.text;
        }
      }

      if (childName != null) {
        // Skip asset files
        if (!includeAssets && assetFileRegex.hasMatch(childName)) continue;

        if (!files.contains(childName)) {
          files.add(childName);
          if (fileType != null) {
            fileTypes[childName] = fileType;
          }
        }
      }
    }

    return DirectoryChildren(directories, files, fileTypes);
  }

  static Future<List<String>> getAllFiles({
    bool includeExtensions = false,
    bool includeAssets = false,
  }) async {
    final allFiles = <String>[];
    final directories = <String>['/'];

    while (directories.isNotEmpty) {
      final directory = directories.removeLast();
      final children = await getChildrenOfDirectory(
        directory,
        includeExtensions: includeExtensions,
        includeAssets: includeAssets,
      );
      if (children == null) continue;

      for (final file in children.files) {
        allFiles.add('$directory$file');
      }
      for (final childDirectory in children.directories) {
        directories.add('$directory$childDirectory/');
      }
    }

    return allFiles;
  }

  static Future<List<String>> getRecentlyAccessed() async {
    if (!stows.recentFiles.loaded) await stows.recentFiles.waitUntilRead();

    final recentFiles = <String>[];
    final filesToRemove = <String>[];

    for (final filePath in stows.recentFiles.value) {
      String normalizedPath;
      if (filePath.endsWith(Editor.extension)) {
        normalizedPath = filePath.substring(
          0,
          filePath.length - Editor.extension.length,
        );
      } else if (filePath.endsWith(Editor.extensionOldJson)) {
        normalizedPath = filePath.substring(
          0,
          filePath.length - Editor.extensionOldJson.length,
        );
      } else if (filePath.endsWith('.md')) {
        normalizedPath = filePath.substring(0, filePath.length - '.md'.length);
      } else if (filePath.endsWith(TextFileEditor.internalExtension)) {
        normalizedPath = filePath.substring(
          0,
          filePath.length - TextFileEditor.internalExtension.length,
        );
      } else {
        normalizedPath = filePath;
      }

      if (Editor.isReservedPath(normalizedPath)) continue;

      // Check if the file actually exists
      final fileExists =
          doesFileExist('$normalizedPath${Editor.extension}') ||
          doesFileExist('$normalizedPath.md') ||
          doesFileExist('$normalizedPath${TextFileEditor.internalExtension}');

      if (fileExists && !recentFiles.contains(normalizedPath)) {
        // Only add if not already in the list (handles same base name with different extensions)
        recentFiles.add(normalizedPath);
      } else if (!fileExists) {
        // Mark for removal from recent files list
        filesToRemove.add(filePath);
      }
    }

    // Remove deleted files from the recent files list
    if (filesToRemove.isNotEmpty) {
      final updatedRecentFiles = List<String>.from(stows.recentFiles.value);
      updatedRecentFiles.removeWhere((file) => filesToRemove.contains(file));
      stows.recentFiles.value = updatedRecentFiles;
    }

    return recentFiles;
  }

  static bool isDirectory(String filePath) {
    filePath = _sanitisePath(filePath);
    final directory = Directory(documentsDirectory + filePath);
    return directory.existsSync();
  }

  static bool doesFileExist(String filePath) {
    filePath = _sanitisePath(filePath);
    final file = getFile(filePath);
    return file.existsSync();
  }

  static DateTime lastModified(String filePath) {
    filePath = _sanitisePath(filePath);
    final file = getFile(filePath);
    return file.lastModifiedSync();
  }

  static Future<String> newFilePath([String parentPath = '/']) async {
    assert(parentPath.endsWith('/'));

    final DateTime now = DateTime.now();
    final String filePath =
        '$parentPath${DateFormat("yy-MM-dd").format(now)} '
        '${t.editor.untitled}';

    return await suffixFilePathToMakeItUnique(filePath);
  }

  static Future<String> suffixFilePathToMakeItUnique(
    String filePath, {
    String? intendedExtension,
    String? currentPath,
  }) async {
    String newFilePath = filePath;
    bool hasExtension = false;

    if (filePath.endsWith(Editor.extension)) {
      filePath = filePath.substring(
        0,
        filePath.length - Editor.extension.length,
      );
      newFilePath = filePath;
      hasExtension = true;
      intendedExtension ??= Editor.extension;
    } else if (filePath.endsWith(Editor.extensionOldJson)) {
      filePath = filePath.substring(
        0,
        filePath.length - Editor.extensionOldJson.length,
      );
      newFilePath = filePath;
      hasExtension = true;
      intendedExtension ??= Editor.extensionOldJson;
    } else {
      intendedExtension ??= Editor.extension;
    }

    int i = 1;
    while (true) {
      if (!doesFileExist(newFilePath + Editor.extension) &&
          !doesFileExist(newFilePath + Editor.extensionOldJson))
        break;
      if (newFilePath + Editor.extension == currentPath) break;
      if (newFilePath + Editor.extensionOldJson == currentPath) break;
      i++;
      newFilePath = '$filePath ($i)';
    }

    return newFilePath + (hasExtension ? intendedExtension : '');
  }

  static Future<String?> importFile(
    String path,
    String? parentDir, {
    String? extension,
    bool awaitWrite = true,
  }) async {
    assert(
      parentDir == null || parentDir.startsWith('/') && parentDir.endsWith('/'),
    );

    if (extension == null) {
      extension = '.${path.split('.').last}';
      assert(extension.length > 1);
    } else {
      assert(extension.startsWith('.'));
    }

    String fileName = path.split(RegExp(r'[\\/]')).last;
    fileName = fileName.substring(0, fileName.lastIndexOf('.'));
    final String importedPath;

    final writeFutures = <Future>[];

    if (extension.toLowerCase() == '.kvx ') {
      final inputStream = InputFileStream(path);
      final archive = ZipDecoder().decodeStream(inputStream);

      final mainFile = archive.files.cast<ArchiveFile?>().firstWhere(
        (file) =>
            file!.name.toLowerCase().endsWith('kvx') ||
            file.name.toLowerCase().endsWith('kvx'),
        orElse: () => null,
      );
      if (mainFile == null) {
        log.severe('Failed to find main note in kvx : $path');
        return null;
      }
      final mainFileExtension = '.${mainFile.name.split('.').last}'
          .toLowerCase();
      importedPath = await suffixFilePathToMakeItUnique(
        '${parentDir ?? '/'}$fileName',
        intendedExtension: mainFileExtension,
      );
      final mainFileContents = () {
        final output = OutputMemoryStream();
        mainFile.writeContent(output);
        return output.getBytes();
      }();
      writeFutures.add(
        writeFile(
          importedPath + mainFileExtension,
          mainFileContents,
          awaitWrite: awaitWrite,
        ),
      );

      for (final file in archive.files) {
        if (!file.isFile) continue;
        if (file == mainFile) continue;

        final extension = file.name.split('.').last;
        final assetNumber = int.tryParse(extension);
        if (assetNumber == null) continue;
        if (assetNumber < 0) continue;

        final assetBytes = () {
          final output = OutputMemoryStream();
          file.writeContent(output);
          return output.getBytes();
        }();
        writeFutures.add(
          writeFile(
            '$importedPath$mainFileExtension.$assetNumber',
            assetBytes,
            awaitWrite: awaitWrite,
          ),
        );
      }
    } else {
      final file = File(path);
      final fileContents = await file.readAsBytes();
      importedPath = await suffixFilePathToMakeItUnique(
        '${parentDir ?? '/'}$fileName',
        intendedExtension: extension.toLowerCase(),
      );
      writeFutures.add(
        writeFile(
          importedPath + extension.toLowerCase(),
          fileContents,
          awaitWrite: awaitWrite,
        ),
      );
    }

    await Future.wait(writeFutures);

    return importedPath;
  }

  static Future _createFileDirectory(String filePath) async {
    assert(filePath.contains('/'), 'filePath must be a path, not a file name');
    final parentDirectory = filePath.substring(0, filePath.lastIndexOf('/'));
    await Directory(
      documentsDirectory + parentDirectory,
    ).create(recursive: true);
  }

  static Future _renameReferences(String fromPath, String toPath) async {
    bool replaced = false;
    for (int i = 0; i < stows.recentFiles.value.length; i++) {
      if (stows.recentFiles.value[i] != fromPath) continue;
      if (!replaced) {
        stows.recentFiles.value[i] = toPath;
        replaced = true;
      } else {
        stows.recentFiles.value.removeAt(i);
      }
    }
    stows.recentFiles.notifyListeners();
  }

  static Future _removeReferences(String filePath) async {
    for (int i = 0; i < stows.recentFiles.value.length; i++) {
      if (stows.recentFiles.value[i] != filePath) continue;
      stows.recentFiles.value.removeAt(i);
    }
    stows.recentFiles.notifyListeners();
  }

  static Future _saveFileAsRecentlyAccessed(String filePath) async {
    if (assetFileRegex.hasMatch(filePath)) return;

    stows.recentFiles.value.remove(filePath);
    stows.recentFiles.value.insert(0, filePath);
    if (stows.recentFiles.value.length > maxRecentlyAccessedFiles)
      stows.recentFiles.value.removeLast();

    stows.recentFiles.notifyListeners();
  }

  static const maxRecentlyAccessedFiles = 30;
}

/// Note file type enumeration for browse filtering
/// Named KivixaFileType to avoid conflict with file_picker's FileType
enum KivixaFileType {
  handwritten, // .kvx files
  markdown, // .md files
  text, // .kvtx files
}

class DirectoryChildren {
  final List<String> directories;
  final List<String> files;

  /// Maps file name (without extension) to its file type
  /// This is populated during directory listing for efficient filtering
  final Map<String, KivixaFileType> fileTypes;

  DirectoryChildren(
    this.directories,
    this.files, [
    Map<String, KivixaFileType>? fileTypes,
  ]) : fileTypes = fileTypes ?? {};

  bool onlyOneChild() => directories.length + files.length <= 1;

  bool get isEmpty => directories.isEmpty && files.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Get the file type for a given file name
  /// Returns null if the file type is unknown
  KivixaFileType? getFileType(String fileName) => fileTypes[fileName];

  /// Check if a file is of a specific type
  bool isFileType(String fileName, KivixaFileType type) =>
      fileTypes[fileName] == type;
}

enum FileOperationType { write, delete }

class FileOperation {
  final FileOperationType type;
  final String filePath;

  const FileOperation(this.type, this.filePath);
}
