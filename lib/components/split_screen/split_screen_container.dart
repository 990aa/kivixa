import 'package:flutter/material.dart';
import 'package:kivixa/components/split_screen/pane_wrapper.dart';
import 'package:kivixa/components/split_screen/resizable_divider.dart';
import 'package:kivixa/components/split_screen/split_screen_state.dart';

/// The main split screen container widget
class SplitScreenContainer extends StatefulWidget {
  const SplitScreenContainer({
    super.key,
    required this.controller,
    this.minPaneWidth = 200,
    this.minPaneHeight = 150,
  });

  final SplitScreenController controller;
  final double minPaneWidth;
  final double minPaneHeight;

  @override
  State<SplitScreenContainer> createState() => _SplitScreenContainerState();
}

class _SplitScreenContainerState extends State<SplitScreenContainer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleDrag(double delta, double totalSize) {
    final controller = widget.controller;
    final currentRatio = controller.splitRatio;
    final deltaRatio = delta / totalSize;
    controller.setSplitRatio(currentRatio + deltaRatio);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controller = widget.controller;
        final isWide = constraints.maxWidth >= SplitScreenController.minSplitWidth;

        // If split is not enabled or screen is too narrow, show single pane
        if (!controller.isSplitEnabled || !isWide) {
          return PaneWrapper(
            paneState: controller.leftPane.isEmpty
                ? controller.rightPane
                : controller.leftPane,
            isRightPane: controller.leftPane.isEmpty,
            onClose: () {},
            onTap: () {},
            showCloseButton: false,
          );
        }

        // Build split view
        final isHorizontal = controller.splitDirection == SplitDirection.horizontal;

        if (isHorizontal) {
          return _buildHorizontalSplit(constraints);
        } else {
          return _buildVerticalSplit(constraints);
        }
      },
    );
  }

  Widget _buildHorizontalSplit(BoxConstraints constraints) {
    final controller = widget.controller;
    final totalWidth = constraints.maxWidth;
    final dividerWidth = 8.0;
    final availableWidth = totalWidth - dividerWidth;
    final leftWidth = availableWidth * controller.splitRatio;
    final rightWidth = availableWidth * (1 - controller.splitRatio);

    return Row(
      children: [
        SizedBox(
          width: leftWidth.clamp(widget.minPaneWidth, availableWidth - widget.minPaneWidth),
          child: PaneWrapper(
            paneState: controller.leftPane,
            isRightPane: false,
            onClose: () => controller.closePane(isRightPane: false),
            onTap: () => controller.setActivePane(isRightPane: false),
          ),
        ),
        ResizableDivider(
          direction: SplitDirection.horizontal,
          onDrag: (delta) => _handleDrag(delta, totalWidth),
        ),
        Expanded(
          child: PaneWrapper(
            paneState: controller.rightPane,
            isRightPane: true,
            onClose: () => controller.closePane(isRightPane: true),
            onTap: () => controller.setActivePane(isRightPane: true),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalSplit(BoxConstraints constraints) {
    final controller = widget.controller;
    final totalHeight = constraints.maxHeight;
    final dividerHeight = 8.0;
    final availableHeight = totalHeight - dividerHeight;
    final topHeight = availableHeight * controller.splitRatio;

    return Column(
      children: [
        SizedBox(
          height: topHeight.clamp(widget.minPaneHeight, availableHeight - widget.minPaneHeight),
          child: PaneWrapper(
            paneState: controller.leftPane,
            isRightPane: false,
            onClose: () => controller.closePane(isRightPane: false),
            onTap: () => controller.setActivePane(isRightPane: false),
          ),
        ),
        ResizableDivider(
          direction: SplitDirection.vertical,
          onDrag: (delta) => _handleDrag(delta, totalHeight),
        ),
        Expanded(
          child: PaneWrapper(
            paneState: controller.rightPane,
            isRightPane: true,
            onClose: () => controller.closePane(isRightPane: true),
            onTap: () => controller.setActivePane(isRightPane: true),
          ),
        ),
      ],
    );
  }
}

/// A toolbar for controlling the split screen
class SplitScreenToolbar extends StatelessWidget {
  const SplitScreenToolbar({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final SplitScreenController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (compact) {
          return _buildCompactToolbar(context, colorScheme);
        }
        return _buildFullToolbar(context, colorScheme);
      },
    );
  }

  Widget _buildCompactToolbar(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            controller.isSplitEnabled
                ? Icons.view_sidebar
                : Icons.vertical_split,
            color: controller.isSplitEnabled
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
          tooltip: controller.isSplitEnabled
              ? 'Disable split view'
              : 'Enable split view',
          onPressed: controller.toggleSplit,
        ),
        if (controller.isSplitEnabled) ...[
          IconButton(
            icon: Icon(
              controller.splitDirection == SplitDirection.horizontal
                  ? Icons.view_column
                  : Icons.view_agenda,
              color: colorScheme.onSurface,
            ),
            tooltip: controller.splitDirection == SplitDirection.horizontal
                ? 'Switch to vertical split'
                : 'Switch to horizontal split',
            onPressed: controller.toggleSplitDirection,
          ),
          IconButton(
            icon: Icon(Icons.swap_horiz, color: colorScheme.onSurface),
            tooltip: 'Swap panes',
            onPressed: controller.swapPanes,
          ),
        ],
      ],
    );
  }

  Widget _buildFullToolbar(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Split toggle button
            _buildToolbarButton(
              icon: controller.isSplitEnabled
                  ? Icons.view_sidebar
                  : Icons.vertical_split,
              label: controller.isSplitEnabled ? 'Single' : 'Split',
              isActive: controller.isSplitEnabled,
              onPressed: controller.toggleSplit,
              colorScheme: colorScheme,
            ),
            if (controller.isSplitEnabled) ...[
              const SizedBox(width: 8),
              const VerticalDivider(width: 1),
              const SizedBox(width: 8),
              // Direction toggle
              _buildToolbarButton(
                icon: controller.splitDirection == SplitDirection.horizontal
                    ? Icons.view_column
                    : Icons.view_agenda,
                label: controller.splitDirection == SplitDirection.horizontal
                    ? 'Horizontal'
                    : 'Vertical',
                isActive: false,
                onPressed: controller.toggleSplitDirection,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              // Swap panes
              _buildToolbarButton(
                icon: Icons.swap_horiz,
                label: 'Swap',
                isActive: false,
                onPressed: controller.swapPanes,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              // Reset ratio
              _buildToolbarButton(
                icon: Icons.height,
                label: '50/50',
                isActive: false,
                onPressed: controller.resetSplitRatio,
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: isActive
            ? colorScheme.primaryContainer
            : Colors.transparent,
        foregroundColor: isActive
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
