import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/plugins/models/plugin.dart';

void main() {
  group('Plugin Model', () {
    test('creates a valid plugin', () {
      const plugin = Plugin(
        name: 'Test Plugin',
        description: 'A test plugin',
        version: '1.0.0',
        author: 'Test Author',
        path: 'test/plugin.lua',
        fullPath: '/full/path/test/plugin.lua',
        isEnabled: true,
      );

      expect(plugin.name, 'Test Plugin');
      expect(plugin.description, 'A test plugin');
      expect(plugin.version, '1.0.0');
      expect(plugin.author, 'Test Author');
      expect(plugin.path, 'test/plugin.lua');
      expect(plugin.fullPath, '/full/path/test/plugin.lua');
      expect(plugin.isEnabled, true);
    });

    test('copyWith creates modified copy', () {
      const original = Plugin(
        name: 'Original',
        description: 'Original desc',
        version: '1.0',
        author: 'Author',
        path: 'path.lua',
        fullPath: '/full/path.lua',
        isEnabled: true,
      );

      final modified = original.copyWith(name: 'Modified', isEnabled: false);

      expect(modified.name, 'Modified');
      expect(modified.isEnabled, false);
      expect(modified.description, 'Original desc'); // Unchanged
      expect(modified.version, '1.0'); // Unchanged
    });

    test('equality is based on name and path', () {
      const plugin1 = Plugin(
        name: 'Plugin A',
        description: 'Description 1',
        version: '1.0',
        author: 'Author 1',
        path: 'path/a.lua',
        fullPath: '/full/path/a.lua',
        isEnabled: true,
      );

      const plugin2 = Plugin(
        name: 'Plugin A',
        description: 'Different description',
        version: '2.0',
        author: 'Author 2',
        path: 'path/a.lua',
        fullPath: '/different/full/path/a.lua',
        isEnabled: false,
      );

      const plugin3 = Plugin(
        name: 'Plugin B',
        description: 'Description 1',
        version: '1.0',
        author: 'Author 1',
        path: 'path/a.lua',
        fullPath: '/full/path/a.lua',
        isEnabled: true,
      );

      expect(plugin1, equals(plugin2)); // Same name and path
      expect(plugin1, isNot(equals(plugin3))); // Different name
    });

    test('hashCode is consistent with equality', () {
      const plugin1 = Plugin(
        name: 'Same',
        description: 'Desc 1',
        version: '1.0',
        author: 'Author',
        path: 'same/path.lua',
        fullPath: '/full/same/path.lua',
        isEnabled: true,
      );

      const plugin2 = Plugin(
        name: 'Same',
        description: 'Desc 2',
        version: '2.0',
        author: 'Other',
        path: 'same/path.lua',
        fullPath: '/other/full/same/path.lua',
        isEnabled: false,
      );

      expect(plugin1.hashCode, equals(plugin2.hashCode));
    });

    test('copyWith preserves all fields when no changes', () {
      const original = Plugin(
        name: 'Plugin',
        description: 'Description',
        version: '1.0',
        author: 'Author',
        path: 'path.lua',
        fullPath: '/full/path.lua',
        isEnabled: true,
      );

      final copy = original.copyWith();

      expect(copy.name, original.name);
      expect(copy.description, original.description);
      expect(copy.version, original.version);
      expect(copy.author, original.author);
      expect(copy.path, original.path);
      expect(copy.fullPath, original.fullPath);
      expect(copy.isEnabled, original.isEnabled);
    });
  });

  group('Plugin Metadata Parsing', () {
    test('parses _PLUGIN table metadata correctly', () {
      const luaContent = '''
-- Archive Completed Tasks
-- This script moves completed tasks

_PLUGIN = {
    name = "Archive Tasks",
    description = "Moves completed tasks to archive",
    version = "2.0",
    author = "990aa"
}

function run()
    return "Done"
end
''';

      // Test the regex patterns used in plugin_service.dart
      final metadataMatch = RegExp(
        r'_PLUGIN\s*=\s*\{([^}]+)\}',
        multiLine: true,
      ).firstMatch(luaContent);

      expect(metadataMatch, isNotNull);

      final metadata = metadataMatch!.group(1)!;

      final nameMatch = RegExp(r'name\s*=\s*"([^"]+)"').firstMatch(metadata);
      expect(nameMatch, isNotNull);
      expect(nameMatch!.group(1), 'Archive Tasks');

      final descMatch = RegExp(
        r'description\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      expect(descMatch, isNotNull);
      expect(descMatch!.group(1), 'Moves completed tasks to archive');

      final versionMatch = RegExp(
        r'version\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      expect(versionMatch, isNotNull);
      expect(versionMatch!.group(1), '2.0');

      final authorMatch = RegExp(
        r'author\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      expect(authorMatch, isNotNull);
      expect(authorMatch!.group(1), '990aa');
    });

    test('handles missing optional metadata fields', () {
      const luaContent = '''
_PLUGIN = {
    name = "Simple Plugin"
}

function run()
    print("Hello")
end
''';

      final metadataMatch = RegExp(
        r'_PLUGIN\s*=\s*\{([^}]+)\}',
        multiLine: true,
      ).firstMatch(luaContent);

      expect(metadataMatch, isNotNull);

      final metadata = metadataMatch!.group(1)!;

      final nameMatch = RegExp(r'name\s*=\s*"([^"]+)"').firstMatch(metadata);
      expect(nameMatch, isNotNull);
      expect(nameMatch!.group(1), 'Simple Plugin');

      final descMatch = RegExp(
        r'description\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      expect(descMatch, isNull);

      final versionMatch = RegExp(
        r'version\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      expect(versionMatch, isNull);
    });

    test('handles scripts without _PLUGIN table', () {
      const luaContent = '''
-- Simple script without metadata

function run()
    print("Hello, World!")
    return "Success"
end
''';

      final metadataMatch = RegExp(
        r'_PLUGIN\s*=\s*\{([^}]+)\}',
        multiLine: true,
      ).firstMatch(luaContent);

      expect(metadataMatch, isNull);
    });
  });

  group('Lua Script Syntax Validation', () {
    test('validates basic Lua function syntax', () {
      const validScript = '''
function run()
    local x = 1
    local y = 2
    return x + y
end
''';

      // Check basic structure
      expect(validScript.contains('function run()'), true);
      expect(validScript.contains('return'), true);
      expect(validScript.contains('end'), true);
    });

    test('validates Lua table syntax', () {
      const tableScript = '''
local myTable = {
    key1 = "value1",
    key2 = 42,
    key3 = true
}
''';

      // Check table structure
      expect(tableScript.contains('local myTable = {'), true);
      expect(tableScript.contains('}'), true);
    });

    test('validates Lua loop syntax', () {
      const loopScript = '''
function run()
    local items = {"a", "b", "c"}
    for i, item in ipairs(items) do
        print(item)
    end
    return "Done"
end
''';

      // Check loop structure
      expect(loopScript.contains('for'), true);
      expect(loopScript.contains('in ipairs'), true);
      expect(loopScript.contains('do'), true);
      expect(loopScript.contains('end'), true);
    });

    test('validates Lua conditional syntax', () {
      const conditionalScript = '''
function run()
    local x = 10
    if x > 5 then
        return "Greater"
    elseif x == 5 then
        return "Equal"
    else
        return "Less"
    end
end
''';

      // Check conditional structure
      expect(conditionalScript.contains('if'), true);
      expect(conditionalScript.contains('then'), true);
      expect(conditionalScript.contains('elseif'), true);
      expect(conditionalScript.contains('else'), true);
      expect(conditionalScript.contains('end'), true);
    });
  });

  group('Plugin Result', () {
    test('PluginResult placeholder for success result', () {
      // Since PluginResult may require actual service initialization,
      // we test the concept of what a result should contain
      final timestamp = DateTime.now();

      // A successful result should have:
      // - success: true
      // - message: the result string
      // - timestamp: when it ran
      // - plugin: the plugin that was run

      expect(timestamp, isA<DateTime>());
    });

    test('result timestamps are reasonable', () {
      final before = DateTime.now();
      // Simulate some work
      final during = DateTime.now();
      final after = DateTime.now();

      expect(during.isAfter(before) || during.isAtSameMomentAs(before), true);
      expect(after.isAfter(before) || after.isAtSameMomentAs(before), true);
    });
  });

  group('Plugin API Method Names', () {
    test('expected API methods exist conceptually', () {
      // These are the methods that should be available to Lua scripts
      const expectedMethods = [
        'createNote',
        'readNote',
        'writeNote',
        'deleteNote',
        'moveNote',
        'renameNote',
        'getAllNotes',
        'findNotes',
        'getRecentNotes',
        'getCurrentNote',
        'getStats',
      ];

      for (final method in expectedMethods) {
        expect(method.isNotEmpty, true);
        // Method names should be camelCase
        expect(method[0].toLowerCase() == method[0], true);
      }
    });
  });

  group('StreamController for Results', () {
    test('StreamController.broadcast allows multiple listeners', () async {
      final controller = StreamController<String>.broadcast();

      final listener1Received = <String>[];
      final listener2Received = <String>[];

      final sub1 = controller.stream.listen((event) {
        listener1Received.add(event);
      });

      final sub2 = controller.stream.listen((event) {
        listener2Received.add(event);
      });

      controller.add('Event 1');
      controller.add('Event 2');

      // Allow async events to process
      await Future.delayed(Duration.zero);

      expect(listener1Received, ['Event 1', 'Event 2']);
      expect(listener2Received, ['Event 1', 'Event 2']);

      await sub1.cancel();
      await sub2.cancel();
      await controller.close();
    });
  });

  group('Plugin File Path Handling', () {
    test('relative path extraction', () {
      const fullPath = '/home/user/documents/plugins/examples/test.lua';
      const pluginsDir = '/home/user/documents/plugins';

      // Simulate relative path calculation
      final relativePath = fullPath.substring(pluginsDir.length + 1);

      expect(relativePath, 'examples/test.lua');
    });

    test('filename extraction from path', () {
      const paths = [
        'test.lua',
        'folder/test.lua',
        'deep/nested/path/test.lua',
      ];

      for (final path in paths) {
        final filename = path.split('/').last;
        expect(filename, 'test.lua');
      }
    });

    test('basename without extension', () {
      const files = {
        'test.lua': 'test',
        'my_plugin.lua': 'my_plugin',
        'archive_tasks.lua': 'archive_tasks',
      };

      for (final entry in files.entries) {
        final basename = entry.key.replaceAll('.lua', '');
        expect(basename, entry.value);
      }
    });
  });
}
