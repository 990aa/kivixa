import 'package:flutter/material.dart';
import 'package:kivixa/services/app_data_clear_service.dart';

/// Widget for clearing app data in settings
class ClearAppDataWidget extends StatefulWidget {
  const ClearAppDataWidget({super.key});

  @override
  State<ClearAppDataWidget> createState() => _ClearAppDataWidgetState();
}

class _ClearAppDataWidgetState extends State<ClearAppDataWidget> {
  final _selectedTypes = <AppDataType>{};
  var _isClearing = false;
  Map<AppDataType, int>? _dataSizes;

  @override
  void initState() {
    super.initState();
    _loadDataSizes();
  }

  Future<void> _loadDataSizes() async {
    final sizes = await AppDataClearService.getDataSizes();
    if (mounted) {
      setState(() => _dataSizes = sizes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_sweep, color: Colors.red),
      title: const Text('Clear App Data'),
      subtitle: const Text('Remove notes, projects, or other data'),
      onTap: () => _showClearDataDialog(context),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Clear App Data'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select the data you want to delete. This action cannot be undone.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ...AppDataType.values
                    .where((t) => t != AppDataType.all)
                    .map((type) => _buildDataTypeOption(type, setState)),
                const Divider(),
                _buildDataTypeOption(AppDataType.all, setState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _selectedTypes.isEmpty || _isClearing
                  ? null
                  : () => _showConfirmationDialog(context),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: _isClearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Clear Selected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeOption(AppDataType type, StateSetter setState) {
    final size = _dataSizes?[type];
    final sizeText = size != null
        ? ' (${AppDataClearService.formatBytes(size)})'
        : '';

    return CheckboxListTile(
      value:
          _selectedTypes.contains(type) ||
          (type != AppDataType.all && _selectedTypes.contains(AppDataType.all)),
      onChanged: (value) {
        setState(() {
          if (type == AppDataType.all) {
            if (value == true) {
              _selectedTypes.clear();
              _selectedTypes.add(AppDataType.all);
            } else {
              _selectedTypes.remove(AppDataType.all);
            }
          } else {
            if (value == true) {
              _selectedTypes.add(type);
              _selectedTypes.remove(AppDataType.all);
            } else {
              _selectedTypes.remove(type);
            }
          }
        });
      },
      title: Text(type.displayName + sizeText),
      subtitle: Text(type.description, style: const TextStyle(fontSize: 12)),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final typesToClear = _selectedTypes.contains(AppDataType.all)
        ? {AppDataType.all}
        : _selectedTypes;

    final itemsList = typesToClear.map((t) => '• ${t.displayName}').join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ WARNING: This action is IRREVERSIBLE!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('You are about to permanently delete:'),
            const SizedBox(height: 8),
            Text(itemsList),
            const SizedBox(height: 16),
            const Text(
              'You will NOT be able to recover this data.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Are you absolutely sure you want to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation
              await _clearData(typesToClear);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData(Set<AppDataType> types) async {
    setState(() => _isClearing = true);

    try {
      final results = await AppDataClearService.clearData(types);

      if (!mounted) return;

      Navigator.pop(context); // Close the main dialog

      final successCount = results.values.where((v) => v).length;
      final failCount = results.values.where((v) => !v).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? 'Successfully cleared $successCount data type(s)'
                : 'Cleared $successCount, failed $failCount',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );

      // Reload data sizes
      await _loadDataSizes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}
