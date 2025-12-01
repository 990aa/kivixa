// ignore_for_file: avoid_slow_async_io, use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kivixa/services/plugins/plugins.dart';

/// Page for managing Lua plugins
class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  var _plugins = <Plugin>[];
  var _isLoading = true;
  final _recentResults = <PluginResult>[];
  StreamSubscription? _resultsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    _resultsSubscription = PluginService.instance.results.listen((result) {
      setState(() {
        _recentResults.insert(0, result);
        if (_recentResults.length > 10) {
          _recentResults.removeLast();
        }
      });
    });
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPlugins() async {
    setState(() => _isLoading = true);
    await PluginService.instance.refreshPlugins();
    setState(() {
      _plugins = PluginService.instance.plugins;
      _isLoading = false;
    });
  }

  Future<void> _runPlugin(Plugin plugin) async {
    final result = await PluginService.instance.runPlugin(plugin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showResultDetails(BuildContext context, PluginResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.plugin.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Executed at ${_formatTimestamp(result.timestamp)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Result:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    result.message,
                    style: TextStyle(
                      fontFamily: 'FiraMono',
                      fontSize: 13,
                      color: result.success
                          ? colorScheme.onSurface
                          : colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _runPlugin(result.plugin);
            },
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Run Again'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlugins,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePluginDialog(context),
            tooltip: 'Create Plugin',
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => _showScriptRunnerDialog(context),
            tooltip: 'Run Script',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plugins.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildPluginList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No plugins found',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new plugin or add .lua files to the plugins folder',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreatePluginDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Plugin'),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginList(ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        // Recent results section
        if (_recentResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Recent Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recentResults.length,
                itemBuilder: (context, index) {
                  final result = _recentResults[index];
                  return GestureDetector(
                    onTap: () => _showResultDetails(context, result),
                    child: Card(
                      margin: const EdgeInsets.only(right: 8),
                      color: result.success
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                result.plugin.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: result.success
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onErrorContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  result.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: result.success
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onErrorContainer,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
        ],

        // Plugins section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Installed Plugins',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final plugin = _plugins[index];
            return _buildPluginTile(plugin, colorScheme);
          }, childCount: _plugins.length),
        ),
      ],
    );
  }

  Widget _buildPluginTile(Plugin plugin, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.extension, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(plugin.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          plugin.description.isNotEmpty
              ? '${plugin.description}\nv${plugin.version} by ${plugin.author}'
              : 'v${plugin.version} by ${plugin.author}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _runPlugin(plugin),
              tooltip: 'Run',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditPluginDialog(context, plugin);
                  case 'delete':
                    _showDeletePluginDialog(context, plugin);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePluginDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final scriptController = TextEditingController(
      text:
          '-- My Plugin\n'
          '-- Enter your Lua script here\n\n'
          '_PLUGIN = {\n'
          '    name = "My Plugin",\n'
          '    description = "A custom plugin",\n'
          '    version = "1.0",\n'
          '    author = "You"\n'
          '}\n\n'
          'function run()\n'
          '    -- Your code here\n'
          '    local notes = App:getRecentNotes(5)\n'
          '    App:log("Found " .. #notes .. " recent notes")\n'
          '    return "Plugin completed!"\n'
          'end\n',
    );
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Create Plugin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plugin Name',
                        hintText: 'My Plugin',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What does this plugin do?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Lua Script:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: scriptController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'FiraMono',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use App:readNote, App:writeNote, App:findNotes, App:log, etc.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (scriptController.text.isNotEmpty) {
                        final result = await PluginService.instance.runScript(
                          scriptController.text,
                          name: nameController.text.isNotEmpty
                              ? nameController.text
                              : 'Test Script',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Test'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if ((result ?? false) && nameController.text.isNotEmpty) {
      await PluginService.instance.createPlugin(
        name: nameController.text,
        description: descController.text,
        content: scriptController.text,
      );
      await _loadPlugins();
    }

    nameController.dispose();
    descController.dispose();
    scriptController.dispose();
  }

  Future<void> _showEditPluginDialog(
    BuildContext context,
    Plugin plugin,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final scriptController = TextEditingController();

    // Load the current script content
    try {
      final file = File(plugin.fullPath);
      if (await file.exists()) {
        scriptController.text = await file.readAsString();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading plugin: $e')));
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          height: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit: ${plugin.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plugin.fullPath,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: scriptController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'FiraMono',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use App:readNote, App:writeNote, App:findNotes, App:log, etc.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (scriptController.text.isNotEmpty) {
                        final result = await PluginService.instance.runScript(
                          scriptController.text,
                          name: plugin.name,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Run'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final file = File(plugin.fullPath);
                        await file.writeAsString(scriptController.text);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plugin saved'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    scriptController.dispose();
    await _loadPlugins();
  }

  Future<void> _showDeletePluginDialog(
    BuildContext context,
    Plugin plugin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plugin'),
        content: Text('Are you sure you want to delete "${plugin.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await PluginService.instance.deletePlugin(plugin);
      await _loadPlugins();
    }
  }

  Future<void> _showScriptRunnerDialog(BuildContext context) async {
    final scriptController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Lua Script'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scriptController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Lua Script',
                  hintText: '''
-- Enter your Lua code here
local notes = App:getRecentNotes(5)
for i, note in ipairs(notes) do
    print(note)
end
return "Done!"''',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'FiraMono', fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Use App:readNote, App:writeNote, App:findNotes, etc.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (scriptController.text.isNotEmpty) {
                final result = await PluginService.instance.runScript(
                  scriptController.text,
                  name: 'Console Script',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run'),
          ),
        ],
      ),
    );

    scriptController.dispose();
  }
}
