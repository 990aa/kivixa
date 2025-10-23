import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/compression_service.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  late CompressionService compressionService;
  late Directory testDir;

  setUp(() async {
    compressionService = CompressionService();
    testDir = await Directory.systemTemp.createTemp('compression_test_');
  });

  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('GZIP Compression', () {
    test('should compress data with GZIP', () async {
      final originalData = 'This is test data for compression. ' * 100;
      final bytes = utf8.encode(originalData);

      final compressed = await compressionService.compressGzip(bytes);

      expect(compressed.length, lessThan(bytes.length));
      expect(compressed, isNotEmpty);
    });

    test('should decompress GZIP data', () async {
      final originalData = 'This is test data for compression.';
      final bytes = utf8.encode(originalData);

      final compressed = await compressionService.compressGzip(bytes);
      final decompressed = await compressionService.decompressGzip(compressed);

      expect(utf8.decode(decompressed), originalData);
    });

    test('should compress with different compression levels', () async {
      final data = 'Test data ' * 1000;
      final bytes = utf8.encode(data);

      final compressed1 = await compressionService.compressGzip(
        bytes,
        level: 1,
      );
      final compressed9 = await compressionService.compressGzip(
        bytes,
        level: 9,
      );

      // Higher compression level should result in smaller size
      expect(compressed9.length, lessThanOrEqualTo(compressed1.length));
    });

    test('should handle empty data', () async {
      final bytes = <int>[];

      final compressed = await compressionService.compressGzip(bytes);
      final decompressed = await compressionService.decompressGzip(compressed);

      expect(decompressed, isEmpty);
    });

    test('should handle large data', () async {
      // Create 10MB of test data
      final largeData = 'X' * (10 * 1024 * 1024);
      final bytes = utf8.encode(largeData);

      final compressed = await compressionService.compressGzip(bytes);
      final decompressed = await compressionService.decompressGzip(compressed);

      expect(decompressed.length, bytes.length);
      expect(compressed.length, lessThan(bytes.length));
    });
  });

  group('File Compression', () {
    test('should compress file', () async {
      // Create test file
      final testFile = File('${testDir.path}/test.txt');
      await testFile.writeAsString('Test content ' * 100);

      final compressedFile = await compressionService.compressFile(
        testFile.path,
      );

      expect(await compressedFile.exists(), true);
      expect(await compressedFile.length(), lessThan(await testFile.length()));
    });

    test('should decompress file', () async {
      final originalContent = 'Test content for file compression';
      final testFile = File('${testDir.path}/original.txt');
      await testFile.writeAsString(originalContent);

      // Compress
      final compressedFile = await compressionService.compressFile(
        testFile.path,
      );

      // Decompress
      final decompressedFile = await compressionService.decompressFile(
        compressedFile.path,
      );

      final decompressedContent = await decompressedFile.readAsString();
      expect(decompressedContent, originalContent);
    });

    test('should compress to custom output path', () async {
      final testFile = File('${testDir.path}/test.txt');
      await testFile.writeAsString('Test');

      final outputPath = '${testDir.path}/custom_output.gz';
      final compressedFile = await compressionService.compressFile(
        testFile.path,
        outputPath: outputPath,
      );

      expect(compressedFile.path, outputPath);
      expect(await compressedFile.exists(), true);
    });
  });

  group('Compression Ratios', () {
    test('should calculate compression ratio', () {
      final originalSize = 1000;
      final compressedSize = 300;

      final ratio = compressionService.getCompressionRatio(
        originalSize,
        compressedSize,
      );

      expect(ratio, closeTo(3.33, 0.01));
    });

    test('should calculate compression percentage', () {
      final originalSize = 1000;
      final compressedSize = 250;

      final percentage = compressionService.getCompressionPercentage(
        originalSize,
        compressedSize,
      );

      expect(percentage, 75.0);
    });

    test('should handle no compression', () {
      final size = 100;

      final ratio = compressionService.getCompressionRatio(size, size);
      final percentage = compressionService.getCompressionPercentage(
        size,
        size,
      );

      expect(ratio, 1.0);
      expect(percentage, 0.0);
    });
  });

  group('JSON Compression', () {
    test('should compress JSON data', () async {
      final jsonData = {
        'strokes': List.generate(
          100,
          (i) => {
            'points': List.generate(50, (j) => {'x': j * 10.0, 'y': j * 20.0}),
            'color': '#000000',
            'width': 2.0,
          },
        ),
      };

      final jsonString = jsonEncode(jsonData);
      final originalBytes = utf8.encode(jsonString);

      final compressed = await compressionService.compressJson(jsonData);

      expect(compressed.length, lessThan(originalBytes.length));
    });

    test('should decompress JSON data', () async {
      final originalData = {
        'name': 'Test Document',
        'type': 'canvas',
        'data': List.generate(100, (i) => 'item_$i'),
      };

      final compressed = await compressionService.compressJson(originalData);
      final decompressed = await compressionService.decompressJson(compressed);

      expect(decompressed['name'], originalData['name']);
      expect(decompressed['type'], originalData['type']);
      expect(decompressed['data'].length, originalData['data']!.length);
    });
  });

  group('Batch Compression', () {
    test('should compress multiple files', () async {
      // Create test files
      final files = <File>[];
      for (int i = 0; i < 5; i++) {
        final file = File('${testDir.path}/test_$i.txt');
        await file.writeAsString('Content $i ' * 100);
        files.add(file);
      }

      final compressedFiles = await compressionService.compressMultipleFiles(
        files.map((f) => f.path).toList(),
      );

      expect(compressedFiles.length, files.length);
      for (final compressed in compressedFiles) {
        expect(await compressed.exists(), true);
        expect(compressed.path.endsWith('.gz'), true);
      }
    });

    test('should report compression statistics', () async {
      final testFile = File('${testDir.path}/test.txt');
      final testContent = 'Test data ' * 1000;
      await testFile.writeAsString(testContent);

      final originalSize = await testFile.length();
      final compressedFile = await compressionService.compressFile(
        testFile.path,
      );
      final compressedSize = await compressedFile.length();

      final stats = compressionService.getCompressionStats(
        originalSize,
        compressedSize,
      );

      expect(stats['originalSize'], originalSize);
      expect(stats['compressedSize'], compressedSize);
      expect(stats['ratio'], greaterThan(1.0));
      expect(stats['percentage'], greaterThan(0.0));
      expect(stats['savedBytes'], originalSize - compressedSize);
    });
  });

  group('Error Handling', () {
    test('should handle invalid GZIP data', () async {
      final invalidData = [1, 2, 3, 4, 5];

      expect(
        () => compressionService.decompressGzip(invalidData),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle non-existent file', () async {
      expect(
        () => compressionService.compressFile('/non/existent/file.txt'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle corrupt compressed file', () async {
      final corruptFile = File('${testDir.path}/corrupt.gz');
      await corruptFile.writeAsBytes([1, 2, 3, 4, 5]);

      expect(
        () => compressionService.decompressFile(corruptFile.path),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Performance', () {
    test('should compress large canvas data efficiently', () async {
      // Simulate large canvas with many strokes
      final largeCanvas = {
        'strokes': List.generate(
          1000,
          (i) => {
            'points': List.generate(
              100,
              (j) => {'x': (i * j).toDouble(), 'y': (i + j).toDouble()},
            ),
            'color': '#${i.toRadixString(16).padLeft(6, '0')}',
            'width': (i % 10) + 1.0,
          },
        ),
      };

      final stopwatch = Stopwatch()..start();
      final compressed = await compressionService.compressJson(largeCanvas);
      stopwatch.stop();

      // Should complete in reasonable time (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Should achieve good compression ratio
      final originalSize = utf8.encode(jsonEncode(largeCanvas)).length;
      final ratio = compressionService.getCompressionRatio(
        originalSize,
        compressed.length,
      );
      expect(ratio, greaterThan(2.0)); // At least 50% compression
    });
  });
}
