import 'dart:async';
import 'dart:io';

import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/services/plugins/models/plugin.dart';
import 'package:kivixa/services/plugins/plugin_api.dart';
import 'package:logging/logging.dart';
import 'package:lua_dardo/lua.dart';
import 'package:path/path.dart' as p;

/// Plugin system service for running Lua scripts
class PluginService {
  static final _log = Logger('PluginService');
  static PluginService? _instance;

  static PluginService get instance {
    _instance ??= PluginService._();
    return _instance!;
  }

  PluginService._();

  /// Directory where plugins are stored
  late String _pluginsDir;

  /// List of loaded plugins
  final List<Plugin> _plugins = [];
  List<Plugin> get plugins => List.unmodifiable(_plugins);

  /// Plugin execution results stream
  final _resultsController = StreamController<PluginResult>.broadcast();
  Stream<PluginResult> get results => _resultsController.stream;

  /// Initialize the plugin system
  Future<void> initialize() async {
    _pluginsDir = p.join(FileManager.documentsDirectory, 'plugins');
    await Directory(_pluginsDir).create(recursive: true);

    // Create example plugins directory
    await _createExamplePlugins();

    // Load all plugins
    await refreshPlugins();

    _log.info('Plugin system initialized at $_pluginsDir');
  }

  /// Create example plugins for new users
  Future<void> _createExamplePlugins() async {
    final examplesDir = p.join(_pluginsDir, 'examples');
    await Directory(examplesDir).create(recursive: true);

    // Archive completed tasks plugin
    final archivePlugin = File(p.join(examplesDir, 'archive_tasks.lua'));
    if (!await archivePlugin.exists()) {
      await archivePlugin.writeAsString('''
-- Archive Completed Tasks
-- This script moves completed tasks from your todo list to an archive

-- Plugin metadata
_PLUGIN = {
    name = "Archive Completed Tasks",
    description = "Moves completed tasks to an archive note",
    version = "1.0",
    author = "Kivixa"
}

function run()
    -- Get all notes with "Todo" or "Tasks" in their name
    local todoNotes = App:findNotes("Todo")
    local tasksNotes = App:findNotes("Tasks")
    
    local allTodos = {}
    for _, note in ipairs(todoNotes) do
        table.insert(allTodos, note)
    end
    for _, note in ipairs(tasksNotes) do
        table.insert(allTodos, note)
    end
    
    local archivedCount = 0
    
    for _, notePath in ipairs(allTodos) do
        local content = App:readNote(notePath)
        if content then
            local lines = {}
            local completedTasks = {}
            
            for line in content:gmatch("[^\\n]+") do
                -- Check if line is a completed task (starts with [x] or [X])
                if line:match("^%s*%[%s*[xX]%s*%]") then
                    table.insert(completedTasks, line)
                    archivedCount = archivedCount + 1
                else
                    table.insert(lines, line)
                end
            end
            
            -- If we found completed tasks, update the note
            if #completedTasks > 0 then
                -- Write back the note without completed tasks
                App:writeNote(notePath, table.concat(lines, "\\n"))
                
                -- Append to archive
                local archivePath = "/Archive/Completed Tasks"
                local archiveContent = App:readNote(archivePath) or ""
                local today = os.date("%Y-%m-%d")
                local newArchive = archiveContent .. "\\n\\n## " .. today .. "\\n" .. table.concat(completedTasks, "\\n")
                App:writeNote(archivePath, newArchive)
            end
        end
    end
    
    return "Archived " .. archivedCount .. " completed tasks"
end
''');
    }

    // Daily summary plugin
    final summaryPlugin = File(p.join(examplesDir, 'daily_summary.lua'));
    if (!await summaryPlugin.exists()) {
      await summaryPlugin.writeAsString('''
-- Daily Summary Generator
-- Creates a daily summary of your notes activity

_PLUGIN = {
    name = "Daily Summary",
    description = "Generates a summary of today's note activity",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local today = os.date("%Y-%m-%d")
    local notes = App:getRecentNotes(10)
    
    local summary = "# Daily Summary - " .. today .. "\\n\\n"
    summary = summary .. "## Recent Notes\\n\\n"
    
    for i, note in ipairs(notes) do
        summary = summary .. i .. ". " .. note .. "\\n"
    end
    
    -- Get statistics
    local stats = App:getStats()
    summary = summary .. "\\n## Statistics\\n\\n"
    summary = summary .. "- Total notes: " .. (stats.totalNotes or 0) .. "\\n"
    summary = summary .. "- Folders: " .. (stats.totalFolders or 0) .. "\\n"
    
    -- Write the summary
    local summaryPath = "/Summaries/" .. today
    App:writeNote(summaryPath, summary)
    
    return "Daily summary created at " .. summaryPath
end
''');
    }

    // Move overdue tasks plugin
    final overduePlugin = File(p.join(examplesDir, 'move_overdue.lua'));
    if (!await overduePlugin.exists()) {
      await overduePlugin.writeAsString('''
-- Move Overdue Tasks to Backlog
-- Scans todo lists and moves unfinished tasks to backlog

_PLUGIN = {
    name = "Move Overdue to Backlog",
    description = "Moves unfinished tasks older than a week to backlog",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local backlogPath = "/Backlog"
    local movedCount = 0
    
    -- Get notes modified more than 7 days ago
    local oldNotes = App:getNotesOlderThan(7)
    
    for _, notePath in ipairs(oldNotes) do
        if notePath:match("[Tt]odo") or notePath:match("[Tt]ask") then
            local content = App:readNote(notePath)
            if content then
                local pendingTasks = {}
                local otherLines = {}
                
                for line in content:gmatch("[^\\n]+") do
                    -- Check for uncompleted tasks ([ ] or - [ ])
                    if line:match("^%s*[%-*]?%s*%[%s*%]") then
                        table.insert(pendingTasks, line)
                        movedCount = movedCount + 1
                    else
                        table.insert(otherLines, line)
                    end
                end
                
                if #pendingTasks > 0 then
                    -- Update original note
                    App:writeNote(notePath, table.concat(otherLines, "\\n"))
                    
                    -- Add to backlog
                    local backlog = App:readNote(backlogPath) or "# Backlog\\n"
                    local today = os.date("%Y-%m-%d")
                    backlog = backlog .. "\\n\\n## From " .. notePath .. " (" .. today .. ")\\n"
                    backlog = backlog .. table.concat(pendingTasks, "\\n")
                    App:writeNote(backlogPath, backlog)
                end
            end
        end
    end
    
    return "Moved " .. movedCount .. " overdue tasks to backlog"
end
''');
    }
  }

  /// Refresh the list of available plugins
  Future<void> refreshPlugins() async {
    _plugins.clear();

    final dir = Directory(_pluginsDir);
    if (!await dir.exists()) return;

    await _scanDirectory(dir);

    _log.info('Found ${_plugins.length} plugins');
  }

  Future<void> _scanDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.lua')) {
        try {
          final plugin = await _loadPlugin(entity);
          if (plugin != null) {
            _plugins.add(plugin);
          }
        } catch (e) {
          _log.warning('Failed to load plugin ${entity.path}: $e');
        }
      }
    }
  }

  Future<Plugin?> _loadPlugin(File file) async {
    final content = await file.readAsString();
    final relativePath = p.relative(file.path, from: _pluginsDir);

    // Try to extract metadata from the plugin
    String name = p.basenameWithoutExtension(file.path);
    String description = '';
    String version = '1.0';
    String author = 'Unknown';

    // Parse _PLUGIN table for metadata
    final metadataMatch = RegExp(
      r'_PLUGIN\s*=\s*\{([^}]+)\}',
      multiLine: true,
    ).firstMatch(content);

    if (metadataMatch != null) {
      final metadata = metadataMatch.group(1)!;

      final nameMatch = RegExp(r'name\s*=\s*"([^"]+)"').firstMatch(metadata);
      if (nameMatch != null) name = nameMatch.group(1)!;

      final descMatch = RegExp(
        r'description\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      if (descMatch != null) description = descMatch.group(1)!;

      final versionMatch = RegExp(
        r'version\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      if (versionMatch != null) version = versionMatch.group(1)!;

      final authorMatch = RegExp(
        r'author\s*=\s*"([^"]+)"',
      ).firstMatch(metadata);
      if (authorMatch != null) author = authorMatch.group(1)!;
    }

    return Plugin(
      name: name,
      description: description,
      version: version,
      author: author,
      path: relativePath,
      fullPath: file.path,
      isEnabled: true,
    );
  }

  /// Run a plugin by path
  Future<PluginResult> runPlugin(Plugin plugin) async {
    _log.info('Running plugin: ${plugin.name}');

    try {
      final file = File(plugin.fullPath);
      if (!await file.exists()) {
        return PluginResult(
          plugin: plugin,
          success: false,
          message: 'Plugin file not found',
          timestamp: DateTime.now(),
        );
      }

      final content = await file.readAsString();
      final result = await _executeScript(content, plugin);

      _resultsController.add(result);
      return result;
    } catch (e) {
      final result = PluginResult(
        plugin: plugin,
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now(),
      );
      _resultsController.add(result);
      return result;
    }
  }

  /// Execute a Lua script
  Future<PluginResult> _executeScript(String script, Plugin plugin) async {
    final state = LuaState.newState();

    try {
      // Open standard libraries
      state.openLibs();

      // Register the App API
      PluginApi.register(state);

      // Load and run the script
      state.loadString(script);
      state.call(0, 0);

      // Call the run() function if it exists
      state.getGlobal('run');
      if (state.isFunction(-1)) {
        state.pCall(0, 1, 0);

        // Get the result
        String resultMessage = 'Plugin executed successfully';
        if (state.isString(-1)) {
          resultMessage = state.toStr(-1) ?? resultMessage;
        }
        state.pop(1);

        return PluginResult(
          plugin: plugin,
          success: true,
          message: resultMessage,
          timestamp: DateTime.now(),
        );
      } else {
        state.pop(1);
        return PluginResult(
          plugin: plugin,
          success: true,
          message: 'Plugin loaded (no run function)',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return PluginResult(
        plugin: plugin,
        success: false,
        message: 'Lua error: $e',
        timestamp: DateTime.now(),
      );
    } finally {
      // LuaDardo is a pure Dart implementation - no explicit cleanup needed
      // LuaState will be garbage collected when no longer referenced
    }
  }

  /// Run a script string directly
  Future<PluginResult> runScript(
    String script, {
    String name = 'Script',
  }) async {
    final plugin = Plugin(
      name: name,
      description: 'Inline script',
      version: '1.0',
      author: 'User',
      path: '',
      fullPath: '',
      isEnabled: true,
    );

    try {
      final result = await _executeScript(script, plugin);
      _resultsController.add(result);
      return result;
    } catch (e) {
      final result = PluginResult(
        plugin: plugin,
        success: false,
        message: 'Error: $e',
        timestamp: DateTime.now(),
      );
      _resultsController.add(result);
      return result;
    }
  }

  /// Create a new plugin file
  Future<Plugin?> createPlugin({
    required String name,
    required String description,
    String? content,
  }) async {
    final filename = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
    final file = File(p.join(_pluginsDir, '$filename.lua'));

    final script =
        content ??
        '''
-- $name
-- $description

_PLUGIN = {
    name = "$name",
    description = "$description",
    version = "1.0",
    author = "User"
}

function run()
    -- Your code here
    return "Hello from $name!"
end
''';

    await file.writeAsString(script);
    await refreshPlugins();

    return _plugins.where((p) => p.fullPath == file.path).firstOrNull;
  }

  /// Delete a plugin
  Future<bool> deletePlugin(Plugin plugin) async {
    try {
      final file = File(plugin.fullPath);
      if (await file.exists()) {
        await file.delete();
        await refreshPlugins();
        return true;
      }
      return false;
    } catch (e) {
      _log.warning('Failed to delete plugin: $e');
      return false;
    }
  }

  /// Get the plugins directory path
  String get pluginsDirectory => _pluginsDir;

  void dispose() {
    _resultsController.close();
  }
}

/// Result of running a plugin
class PluginResult {
  final Plugin plugin;
  final bool success;
  final String message;
  final DateTime timestamp;
  final dynamic data;

  const PluginResult({
    required this.plugin,
    required this.success,
    required this.message,
    required this.timestamp,
    this.data,
  });
}
