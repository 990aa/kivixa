import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

@immutable
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.mediaType,
    this.extractedText,
    this.binaryPreviewBase64,
    this.isTruncated = false,
  });

  final String id;
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final String mediaType;
  final String? extractedText;
  final String? binaryPreviewBase64;
  final bool isTruncated;

  bool get hasExtractedText =>
      extractedText != null && extractedText!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'filePath': filePath,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'mediaType': mediaType,
    'isTruncated': isTruncated,
    if (hasExtractedText) 'contentPreview': extractedText,
    if (!hasExtractedText && binaryPreviewBase64 != null)
      'contentPreview': binaryPreviewBase64,
    'contentPreviewFormat': hasExtractedText ? 'text' : 'base64-head',
  };
}

class ChatAttachmentService {
  static const int _maxBytesToRead = 256 * 1024;
  static const int _maxTextChars = 6000;
  static const int _maxBinaryPreviewBytes = 1024;

  static const Set<String> _textExtensions = <String>{
    'txt',
    'md',
    'markdown',
    'csv',
    'json',
    'yaml',
    'yml',
    'toml',
    'xml',
    'html',
    'htm',
    'log',
    'ini',
    'conf',
    'cfg',
    'dart',
    'js',
    'ts',
    'jsx',
    'tsx',
    'py',
    'java',
    'kt',
    'kts',
    'swift',
    'c',
    'cc',
    'cpp',
    'h',
    'hpp',
    'rs',
    'go',
    'sh',
    'ps1',
    'bat',
    'sql',
    'css',
    'scss',
    'sass',
    'less',
    'rb',
    'php',
    'tex',
    'rtf',
    'kvtx',
  };

  static Future<List<ChatAttachment>> fromFilePaths(
    Iterable<String> filePaths,
  ) async {
    final attachments = <ChatAttachment>[];
    final seenPaths = <String>{};

    for (final filePath in filePaths) {
      if (filePath.trim().isEmpty) {
        continue;
      }

      final normalizedPath = path.normalize(filePath);
      if (!seenPaths.add(normalizedPath)) {
        continue;
      }

      final attachment = await fromFilePath(normalizedPath);
      if (attachment != null) {
        attachments.add(attachment);
      }
    }

    return attachments;
  }

  static Future<ChatAttachment?> fromFilePath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final fileName = path.basename(filePath);
    final sizeBytes = await file.length();
    final mediaType = _inferMediaType(fileName);
    final extension = path
        .extension(fileName)
        .toLowerCase()
        .replaceFirst('.', '');
    final likelyText =
        _textExtensions.contains(extension) || mediaType.startsWith('text/');

    final bytesToRead = math.min(sizeBytes, _maxBytesToRead);
    final headBytes = await _readFileHead(file, bytesToRead);

    var extractedText = '';
    var isTruncated = false;

    if (likelyText) {
      extractedText = _decodeAsText(headBytes);
      if (extractedText.isNotEmpty) {
        if (extractedText.length > _maxTextChars) {
          extractedText = extractedText.substring(0, _maxTextChars);
          isTruncated = true;
        }
        if (sizeBytes > bytesToRead) {
          isTruncated = true;
        }
      }
    }

    final hasText = extractedText.trim().isNotEmpty;
    final binaryPreviewBase64 = hasText
        ? null
        : base64Encode(headBytes.take(_maxBinaryPreviewBytes).toList());

    return ChatAttachment(
      id: '${DateTime.now().microsecondsSinceEpoch}-$filePath',
      filePath: filePath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      mediaType: mediaType,
      extractedText: hasText ? extractedText : null,
      binaryPreviewBase64: binaryPreviewBase64,
      isTruncated: isTruncated,
    );
  }

  static String buildPromptContext(
    List<ChatAttachment> attachments, {
    int maxTotalChars = 14000,
  }) {
    if (attachments.isEmpty) {
      return '';
    }

    final buffer = StringBuffer()
      ..writeln('[Attached files]')
      ..writeln(
        'The user sent one or more attachments. Use these details while answering.',
      );

    for (var i = 0; i < attachments.length; i++) {
      final attachment = attachments[i];
      buffer
        ..writeln()
        ..writeln('Attachment ${i + 1}: ${attachment.fileName}')
        ..writeln('- Path: ${attachment.filePath}')
        ..writeln('- Media type: ${attachment.mediaType}')
        ..writeln('- Size: ${attachment.sizeBytes} bytes');

      if (attachment.hasExtractedText) {
        buffer
          ..writeln(
            '- Extracted text${attachment.isTruncated ? ' (truncated)' : ''}:',
          )
          ..writeln('"""')
          ..writeln(attachment.extractedText)
          ..writeln('"""');
      } else if (attachment.binaryPreviewBase64 != null &&
          attachment.binaryPreviewBase64!.isNotEmpty) {
        buffer.writeln(
          '- Binary preview (base64 head): ${attachment.binaryPreviewBase64}',
        );
      } else {
        buffer.writeln('- No inline preview available.');
      }
    }

    var context = buffer.toString().trimRight();
    if (context.length > maxTotalChars) {
      context =
          '${context.substring(0, maxTotalChars)}\n\n[Attachment context truncated]';
    }

    return context;
  }

  static String formatSize(int sizeBytes) {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<List<int>> _readFileHead(File file, int length) async {
    if (length <= 0) {
      return const <int>[];
    }

    final bytesBuilder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, length)) {
      bytesBuilder.add(chunk);
    }
    return bytesBuilder.takeBytes();
  }

  static String _decodeAsText(List<int> bytes) {
    if (bytes.isEmpty) {
      return '';
    }

    String decoded;
    try {
      decoded = utf8.decode(bytes);
    } on FormatException {
      decoded = utf8.decode(bytes, allowMalformed: true);
    }

    final controlCharacters = decoded.runes.where((rune) {
      return rune < 32 && rune != 9 && rune != 10 && rune != 13;
    }).length;

    final hasTooManyControlCharacters =
        controlCharacters > decoded.length * 0.1;

    if (hasTooManyControlCharacters) {
      return '';
    }

    return decoded.replaceAll('\r\n', '\n').trimRight();
  }

  static String _inferMediaType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();

    switch (ext) {
      case '.txt':
      case '.md':
      case '.markdown':
      case '.csv':
      case '.json':
      case '.yaml':
      case '.yml':
      case '.toml':
      case '.xml':
      case '.kvtx':
        return 'text/plain';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.svg':
        return 'image/svg+xml';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.flac':
        return 'audio/flac';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }
}
