import 'dart:convert';

import 'package:kivixa/data/file_manager/file_manager.dart';

abstract class ChatContextGateway {
  Future<String> buildContextSnapshot();
}

class NotesActivityContextGateway implements ChatContextGateway {
  const NotesActivityContextGateway({
    this.maxNotes = 12,
    this.maxCharsPerNote = 1400,
    this.maxTotalChars = 12000,
    this.maxFolders = 40,
    this.maxRecentEntries = 10,
  });

  final int maxNotes;
  final int maxCharsPerNote;
  final int maxTotalChars;
  final int maxFolders;
  final int maxRecentEntries;

  @override
  Future<String> buildContextSnapshot() async {
    try {
      final allFiles = await FileManager.getAllFiles(
        includeExtensions: true,
        includeAssets: false,
      );

      final noteFiles = allFiles
          .where((path) => path.endsWith('.md') || path.endsWith('.kvtx'))
          .toList(growable: false);

      if (noteFiles.isEmpty) {
        return '';
      }

      final sortedNotes = List<String>.from(noteFiles)
        ..sort((a, b) => FileManager.lastModified(b).compareTo(FileManager.lastModified(a)));

      final selectedNotes = sortedNotes.take(maxNotes).toList(growable: false);
      final folders = _collectFolders(noteFiles).take(maxFolders).toList(growable: false);
      final recent = await FileManager.getRecentlyAccessed();

      final buffer = StringBuffer();
      buffer.writeln('## User Workspace Context');
      buffer.writeln('Use this context to answer note and activity questions directly.');
      buffer.writeln('Skip handwritten note assumptions unless explicitly provided.');

      if (folders.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('### Folder Structure');
        for (final folder in folders) {
          buffer.writeln('- $folder');
        }
      }

      if (recent.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('### Recent User Activity');
        for (final path in recent.take(maxRecentEntries)) {
          buffer.writeln('- Opened: $path');
        }
      }

      var remainingChars = maxTotalChars;
      buffer.writeln();
      buffer.writeln('### Recent Markdown and Text Notes');

      for (final notePath in selectedNotes) {
        if (remainingChars <= 0) {
          break;
        }

        final content = await _readNoteContent(notePath);
        if (content.isEmpty) {
          continue;
        }

        final truncated = _truncate(content, maxCharsPerNote);
        if (truncated.isEmpty) {
          continue;
        }

        final block = StringBuffer()
          ..writeln('#### $notePath')
          ..writeln(truncated.trim())
          ..writeln();

        final blockText = block.toString();
        if (blockText.length > remainingChars) {
          final shortened = _truncate(blockText, remainingChars);
          if (shortened.trim().isNotEmpty) {
            buffer.writeln(shortened.trimRight());
          }
          remainingChars = 0;
          break;
        }

        buffer.write(blockText);
        remainingChars -= blockText.length;
      }

      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _readNoteContent(String notePath) async {
    final bytes = await FileManager.readFile(notePath);
    if (bytes == null || bytes.isEmpty) {
      return '';
    }

    final raw = utf8.decode(bytes, allowMalformed: true).replaceAll('\r\n', '\n').trim();
    if (raw.isEmpty) {
      return '';
    }

    if (notePath.endsWith('.kvtx')) {
      return _extractKvtxText(raw);
    }

    return raw;
  }

  String _extractKvtxText(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);

      if (decoded is Map<String, dynamic>) {
        final plainText = decoded['plainText'];
        if (plainText is String && plainText.trim().isNotEmpty) {
          return plainText;
        }

        final fromDocument = _extractTextFromDelta(decoded['document']);
        if (fromDocument.isNotEmpty) {
          return fromDocument;
        }
      }

      if (decoded is List<dynamic>) {
        final fromList = _extractTextFromDelta(decoded);
        if (fromList.isNotEmpty) {
          return fromList;
        }
      }
    } catch (_) {
      return rawJson;
    }

    return rawJson;
  }

  String _extractTextFromDelta(dynamic deltaCandidate) {
    if (deltaCandidate is! List<dynamic>) {
      return '';
    }

    final buffer = StringBuffer();
    for (final op in deltaCandidate) {
      if (op is Map<String, dynamic>) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert);
        }
      }
    }

    return buffer.toString().trim();
  }

  Iterable<String> _collectFolders(List<String> notePaths) sync* {
    final folders = <String>{'/' };

    for (final notePath in notePaths) {
      final parts = notePath.split('/').where((part) => part.isNotEmpty).toList();
      if (parts.length <= 1) {
        continue;
      }

      var current = '';
      for (var i = 0; i < parts.length - 1; i++) {
        current += '/${parts[i]}';
        folders.add('$current/');
      }
    }

    final ordered = folders.toList()..sort();
    for (final folder in ordered) {
      yield folder;
    }
  }

  String _truncate(String text, int maxLength) {
    if (maxLength <= 0) {
      return '';
    }
    if (text.length <= maxLength) {
      return text;
    }
    if (maxLength <= 3) {
      return text.substring(0, maxLength);
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
}
