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

    // Always enable split mode when entering split screen page
    _controller.enableSplit();

    // Initialize with provided file paths
    if (widget.leftFilePath != null) {
      _controller.openFile(widget.leftFilePath!, inRightPane: false);
    }
    if (widget.rightFilePath != null) {
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
          // Simplified toolbar - only show direction toggle and swap
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final colorScheme = Theme.of(context).colorScheme;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.splitDirection == SplitDirection.horizontal
                          ? Icons.view_column
                          : Icons.view_agenda,
                      color: colorScheme.onSurface,
                    ),
                    tooltip:
                        _controller.splitDirection == SplitDirection.horizontal
                        ? 'Switch to vertical split'
                        : 'Switch to horizontal split',
                    onPressed: _controller.toggleSplitDirection,
                  ),
                  IconButton(
                    icon: Icon(Icons.swap_horiz, color: colorScheme.onSurface),
                    tooltip: 'Swap panes',
                    onPressed: _controller.swapPanes,
                  ),
                  IconButton(
                    icon: Icon(Icons.height, color: colorScheme.onSurface),
                    tooltip: 'Reset to 50/50',
                    onPressed: _controller.resetSplitRatio,
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SplitScreenContainer(
            controller: _controller,
            showFileBrowserWhenEmpty: true,
          );
        },
      ),
    );
  }
}
