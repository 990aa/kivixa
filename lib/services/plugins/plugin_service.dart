// ignore_for_file: avoid_slow_async_io
// This service intentionally uses async I/O for plugin file operations

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

    // Calendar: Today's Events plugin
    final calendarTodayPlugin = File(p.join(examplesDir, 'calendar_today.lua'));
    if (!await calendarTodayPlugin.exists()) {
      await calendarTodayPlugin.writeAsString('''
-- Today's Calendar Events
-- Shows all events and tasks scheduled for today

_PLUGIN = {
    name = "Today's Events",
    description = "Lists all calendar events and tasks for today",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local today = os.date("*t")
    local events = App:getEventsForDate(today.year, today.month, today.day)
    
    local result = "=== Today's Calendar (" .. os.date("%Y-%m-%d") .. ") ===\\n\\n"
    
    if #events == 0 then
        result = result .. "No events scheduled for today.\\n"
    else
        local tasks = {}
        local appointments = {}
        
        for _, event in ipairs(events) do
            if event.type == "task" then
                table.insert(tasks, event)
            else
                table.insert(appointments, event)
            end
        end
        
        if #appointments > 0 then
            result = result .. "📅 Events:\\n"
            for _, event in ipairs(appointments) do
                local timeStr = ""
                if event.startHour then
                    timeStr = string.format("%02d:%02d", event.startHour, event.startMinute or 0)
                    if event.endHour then
                        timeStr = timeStr .. " - " .. string.format("%02d:%02d", event.endHour, event.endMinute or 0)
                    end
                elseif event.isAllDay then
                    timeStr = "All day"
                end
                result = result .. "  • " .. event.title
                if timeStr ~= "" then
                    result = result .. " (" .. timeStr .. ")"
                end
                result = result .. "\\n"
            end
            result = result .. "\\n"
        end
        
        if #tasks > 0 then
            result = result .. "✅ Tasks:\\n"
            for _, task in ipairs(tasks) do
                local status = task.isCompleted and "[x]" or "[ ]"
                result = result .. "  " .. status .. " " .. task.title .. "\\n"
            end
        end
    end
    
    return result
end
''');
    }

    // Calendar: Add Quick Event plugin
    final addEventPlugin = File(p.join(examplesDir, 'add_quick_event.lua'));
    if (!await addEventPlugin.exists()) {
      await addEventPlugin.writeAsString('''
-- Add Quick Event
-- Adds a simple event or task to today's calendar

_PLUGIN = {
    name = "Add Quick Event",
    description = "Quickly add an event to today's calendar",
    version = "1.0",
    author = "Kivixa"
}

-- Configuration: Change these values before running
local EVENT_TITLE = "Team Meeting"
local EVENT_DESCRIPTION = "Weekly sync"
local START_HOUR = 10
local START_MINUTE = 0
local END_HOUR = 11
local END_MINUTE = 0
local IS_TASK = false  -- Set to true for a task instead of event

function run()
    local today = os.date("*t")
    
    local eventId = App:addCalendarEvent(
        EVENT_TITLE,
        today.year,
        today.month,
        today.day,
        {
            description = EVENT_DESCRIPTION,
            startHour = START_HOUR,
            startMinute = START_MINUTE,
            endHour = END_HOUR,
            endMinute = END_MINUTE,
            type = IS_TASK and "task" or "event"
        }
    )
    
    if eventId then
        local typeStr = IS_TASK and "Task" or "Event"
        return typeStr .. " '" .. EVENT_TITLE .. "' added successfully!\\nID: " .. eventId
    else
        return "Failed to add event"
    end
end
''');
    }

    // Calendar: Week Overview plugin
    final weekOverviewPlugin = File(
      p.join(examplesDir, 'calendar_week_overview.lua'),
    );
    if (!await weekOverviewPlugin.exists()) {
      await weekOverviewPlugin.writeAsString('''
-- Weekly Calendar Overview
-- Shows events for the next 7 days

_PLUGIN = {
    name = "Week Overview",
    description = "Shows calendar events for the upcoming week",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local result = "=== Week Overview ===\\n\\n"
    local today = os.date("*t")
    
    local daysOfWeek = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    
    for i = 0, 6 do
        -- Calculate date for each day
        local dayOffset = i * 24 * 60 * 60
        local targetTime = os.time(today) + dayOffset
        local targetDate = os.date("*t", targetTime)
        
        local dayName = daysOfWeek[targetDate.wday]
        local dateStr = os.date("%Y-%m-%d", targetTime)
        
        local events = App:getEventsForDate(targetDate.year, targetDate.month, targetDate.day)
        
        if i == 0 then
            result = result .. "📌 TODAY - " .. dayName .. " (" .. dateStr .. ")\\n"
        else
            result = result .. "\\n" .. dayName .. " (" .. dateStr .. ")\\n"
        end
        
        if #events == 0 then
            result = result .. "   (no events)\\n"
        else
            for _, event in ipairs(events) do
                local prefix = event.type == "task" and "  ✅ " or "  📅 "
                result = result .. prefix .. event.title
                if event.startHour then
                    result = result .. " @ " .. string.format("%02d:%02d", event.startHour, event.startMinute or 0)
                end
                result = result .. "\\n"
            end
        end
    end
    
    return result
end
''');
    }

    // Productivity: Timer Stats plugin
    final timerStatsPlugin = File(
      p.join(examplesDir, 'productivity_stats.lua'),
    );
    if (!await timerStatsPlugin.exists()) {
      await timerStatsPlugin.writeAsString('''
-- Productivity Statistics
-- Shows your focus session statistics

_PLUGIN = {
    name = "Productivity Stats",
    description = "Displays your productivity timer statistics",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local stats = App:getTimerStats()
    local state = App:getTimerState()
    
    local result = "=== Productivity Dashboard ===\\n\\n"
    
    -- Current session status
    result = result .. "📊 Current Status\\n"
    result = result .. "   State: " .. (state.state or "idle") .. "\\n"
    if state.isRunning or state.isPaused then
        result = result .. "   Session: " .. (state.sessionType or "focus") .. "\\n"
        result = result .. "   Remaining: " .. math.floor(state.remainingMinutes or 0) .. " minutes\\n"
        result = result .. "   Cycle: " .. (state.currentCycle or 1) .. "/" .. (state.totalCycles or 1) .. "\\n"
    end
    
    result = result .. "\\n📈 Today\\n"
    result = result .. "   Focus time: " .. (stats.todayFocusMinutes or 0) .. " minutes\\n"
    result = result .. "   Sessions: " .. (stats.todaySessions or 0) .. "\\n"
    
    result = result .. "\\n🏆 All Time\\n"
    result = result .. "   Total focus: " .. math.floor((stats.totalFocusMinutes or 0) / 60) .. " hours\\n"
    result = result .. "   Total sessions: " .. (stats.totalSessions or 0) .. "\\n"
    result = result .. "   Completed: " .. (stats.completedSessions or 0) .. "\\n"
    result = result .. "   Completion rate: " .. math.floor((stats.completionRate or 0) * 100) .. "%%\\n"
    
    result = result .. "\\n🔥 Streaks\\n"
    result = result .. "   Current streak: " .. (stats.currentStreak or 0) .. " days\\n"
    result = result .. "   Longest streak: " .. (stats.longestStreak or 0) .. " days\\n"
    
    return result
end
''');
    }

    // Productivity: Quick Start Timer plugin
    final quickTimerPlugin = File(p.join(examplesDir, 'quick_start_timer.lua'));
    if (!await quickTimerPlugin.exists()) {
      await quickTimerPlugin.writeAsString('''
-- Quick Start Timer
-- Starts a focus session with configurable duration

_PLUGIN = {
    name = "Quick Start Timer",
    description = "Quickly start a focus timer session",
    version = "1.0",
    author = "Kivixa"
}

-- Configuration: Change these values before running
local DURATION_MINUTES = 25  -- Pomodoro default
local SESSION_TYPE = "focus"  -- Options: focus, deepWork, sprint, meeting, study, workout

function run()
    local state = App:getTimerState()
    
    if state.isRunning then
        return "⚠️ Timer is already running!\\n" ..
               "Session: " .. (state.sessionType or "unknown") .. "\\n" ..
               "Remaining: " .. math.floor(state.remainingMinutes or 0) .. " minutes"
    end
    
    local success = App:startTimer(DURATION_MINUTES, SESSION_TYPE)
    
    if success then
        return "✅ Started " .. DURATION_MINUTES .. " minute " .. SESSION_TYPE .. " session!\\n\\n" ..
               "Good luck with your focused work!"
    else
        return "❌ Failed to start timer"
    end
end
''');
    }

    // Productivity: Daily Report plugin
    final dailyReportPlugin = File(
      p.join(examplesDir, 'productivity_daily_report.lua'),
    );
    if (!await dailyReportPlugin.exists()) {
      await dailyReportPlugin.writeAsString('''
-- Daily Productivity Report
-- Creates a productivity report note for today

_PLUGIN = {
    name = "Daily Productivity Report",
    description = "Generates a productivity report and saves it as a note",
    version = "1.0",
    author = "Kivixa"
}

function run()
    local today = os.date("%Y-%m-%d")
    local stats = App:getTimerStats()
    local history = App:getSessionHistory(7)
    
    -- Build report content
    local report = "# Productivity Report - " .. today .. "\\n\\n"
    
    -- Today's summary
    report = report .. "## Today's Progress\\n\\n"
    report = report .. "- **Focus time:** " .. (stats.todayFocusMinutes or 0) .. " minutes\\n"
    report = report .. "- **Sessions completed:** " .. (stats.todaySessions or 0) .. "\\n"
    report = report .. "- **Current streak:** " .. (stats.currentStreak or 0) .. " days\\n"
    
    -- Weekly trend
    report = report .. "\\n## Last 7 Days\\n\\n"
    report = report .. "| Date | Minutes |\\n"
    report = report .. "|------|---------|\\n"
    
    local totalWeek = 0
    for date, minutes in pairs(history) do
        report = report .. "| " .. date .. " | " .. minutes .. " |\\n"
        totalWeek = totalWeek + minutes
    end
    
    report = report .. "\\n**Weekly total:** " .. totalWeek .. " minutes (" .. math.floor(totalWeek / 60) .. " hours)\\n"
    
    -- Statistics
    report = report .. "\\n## All-Time Statistics\\n\\n"
    report = report .. "- Total focus time: " .. math.floor((stats.totalFocusMinutes or 0) / 60) .. " hours\\n"
    report = report .. "- Total sessions: " .. (stats.totalSessions or 0) .. "\\n"
    report = report .. "- Completion rate: " .. math.floor((stats.completionRate or 0) * 100) .. "%%\\n"
    report = report .. "- Longest streak: " .. (stats.longestStreak or 0) .. " days\\n"
    
    -- Save the report
    local reportPath = "/Productivity Reports/" .. today
    App:writeNote(reportPath, report)
    
    return "📊 Productivity report saved to:\\n" .. reportPath
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
    final logs = <String>[];

    try {
      // Open standard libraries
      state.openLibs();

      // Register the App API
      PluginApi.register(state);

      // Override print to capture output
      state.register('print', (LuaState ls) {
        final nArgs = ls.getTop();
        final parts = <String>[];
        for (var i = 1; i <= nArgs; i++) {
          parts.add(ls.toStr(i) ?? 'nil');
        }
        logs.add(parts.join('\t'));
        return 0;
      });

      // Load the script
      state.loadString(script);

      // Run the script, expecting 1 return value
      state.pCall(0, 1, 0);

      // Check if the script returned a value directly
      String resultMessage = '';
      if (!state.isNil(-1)) {
        resultMessage = state.toStr(-1) ?? '';
        state.pop(1);
      }

      // If no direct return, try calling run() function
      if (resultMessage.isEmpty) {
        state.getGlobal('run');
        if (state.isFunction(-1)) {
          state.pCall(0, 1, 0);

          // Get the result from run()
          if (state.isString(-1)) {
            resultMessage = state.toStr(-1) ?? 'Plugin executed successfully';
          } else {
            resultMessage = 'Plugin executed successfully';
          }
          state.pop(1);
        } else {
          state.pop(1);
          // No run function and no direct return
          if (logs.isNotEmpty) {
            resultMessage = logs.join('\n');
          } else {
            resultMessage = 'Plugin loaded (no run function or return value)';
          }
        }
      }

      // Append logs if there are any and not already included
      if (logs.isNotEmpty && !resultMessage.contains(logs.first)) {
        resultMessage = '${logs.join('\n')}\n\n$resultMessage';
      }

      return PluginResult(
        plugin: plugin,
        success: true,
        message: resultMessage,
        timestamp: DateTime.now(),
      );
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
