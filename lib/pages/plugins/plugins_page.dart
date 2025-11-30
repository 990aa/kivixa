import 'dart:async';

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
                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    color: result.success
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 150,
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
        title: Text(plugin.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plugin.description.isNotEmpty)
              Text(
                plugin.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'v${plugin.version} by ${plugin.author}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Plugin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Plugin Name',
                hintText: 'My Plugin',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What does this plugin do?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if ((result ?? false) && nameController.text.isNotEmpty) {
      await PluginService.instance.createPlugin(
        name: nameController.text,
        description: descController.text,
      );
      await _loadPlugins();
    }

    nameController.dispose();
    descController.dispose();
  }

  Future<void> _showEditPluginDialog(
    BuildContext context,
    Plugin plugin,
  ) async {
    // In a real implementation, this would open a code editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit plugin at: ${plugin.fullPath}')),
    );
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
