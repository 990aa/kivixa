import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/split_screen/split_screen.dart';
import 'package:kivixa/data/routes.dart';

/// A full-screen split view page for working with two files simultaneously
class SplitScreenPage extends StatefulWidget {
  const SplitScreenPage({super.key, this.leftFilePath, this.rightFilePath});

  final String? leftFilePath;
  final String? rightFilePath;

  @override
  State<SplitScreenPage> createState() => _SplitScreenPageState();
}

class _SplitScreenPageState extends State<SplitScreenPage> {
  late final SplitScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplitScreenController();

    // Initialize with provided file paths
    if (widget.leftFilePath != null) {
      _controller.openFile(widget.leftFilePath!, inRightPane: false);
    }
    if (widget.rightFilePath != null) {
      _controller.enableSplit();
      _controller.openFile(widget.rightFilePath!, inRightPane: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(HomeRoutes.browseFilePath('/'));
            }
          },
        ),
        title: const Text('Split View'),
        actions: [
          SplitScreenToolbar(controller: _controller, compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SplitScreenContainer(controller: _controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilePickerForPane(context),
        tooltip: 'Open file in pane',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilePickerForPane(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Open File In',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chevron_left),
              title: Text(
                _controller.leftPane.isEmpty
                    ? 'Left Pane (empty)'
                    : 'Left Pane',
              ),
              subtitle: _controller.leftPane.filePath != null
                  ? Text(
                      _controller.leftPane.filePath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _openFileBrowser(isRightPane: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chevron_right),
              title: Text(
                _controller.rightPane.isEmpty
                    ? 'Right Pane (empty)'
                    : 'Right Pane',
              ),
              subtitle: _controller.rightPane.filePath != null
                  ? Text(
                      _controller.rightPane.filePath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _controller.enableSplit();
                _openFileBrowser(isRightPane: true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Swap Panes'),
              onTap: () {
                Navigator.pop(context);
                _controller.swapPanes();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openFileBrowser({required bool isRightPane}) {
    // Navigate to browse page with callback to open file in the specified pane
    context.push(
      '${HomeRoutes.browseFilePath('/')}${isRightPane ? '&splitPane=right' : '&splitPane=left'}',
    );
  }
}
