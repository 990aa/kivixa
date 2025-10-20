import 'package:flutter/material.dart';

/// Professional drawing workspace with fixed UI and transformable canvas
/// Only the canvas moves during pan/zoom, UI elements remain fixed
class DrawingWorkspaceLayout extends StatelessWidget {
  /// Transformation controller for canvas
  final TransformationController transformController;

  /// Canvas widget (will be transformed)
  final Widget canvas;

  /// Optional toolbar widgets
  final Widget? topToolbar;
  final Widget? bottomToolbar;
  final Widget? leftPanel;
  final Widget? rightPanel;

  /// Background color
  final Color backgroundColor;

  /// Enable/disable specific UI elements
  final bool showTopToolbar;
  final bool showBottomToolbar;
  final bool showLeftPanel;
  final bool showRightPanel;

  const DrawingWorkspaceLayout({
    super.key,
    required this.transformController,
    required this.canvas,
    this.topToolbar,
    this.bottomToolbar,
    this.leftPanel,
    this.rightPanel,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.showTopToolbar = true,
    this.showBottomToolbar = true,
    this.showLeftPanel = false,
    this.showRightPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Workspace background (fixed, doesn't move)
        Positioned.fill(
          child: Container(
            color: backgroundColor,
          ),
        ),

        // Layer 2: Transformable canvas (moves with gestures)
        Positioned.fill(
          child: ClipRect(
            child: Transform(
              transform: transformController.value,
              alignment: Alignment.center,
              child: canvas,
            ),
          ),
        ),

        // Layer 3: Fixed UI overlays (top toolbar)
        if (showTopToolbar && topToolbar != null)
          Positioned(
            top: 0,
            left: showLeftPanel && leftPanel != null ? 250 : 0,
            right: showRightPanel && rightPanel != null ? 250 : 0,
            child: topToolbar!,
          ),

        // Layer 4: Fixed UI overlays (left panel)
        if (showLeftPanel && leftPanel != null)
          Positioned(
            left: 0,
            top: showTopToolbar && topToolbar != null ? 60 : 0,
            bottom: showBottomToolbar && bottomToolbar != null ? 50 : 0,
            child: leftPanel!,
          ),

        // Layer 5: Fixed UI overlays (right panel)
        if (showRightPanel && rightPanel != null)
          Positioned(
            right: 0,
            top: showTopToolbar && topToolbar != null ? 60 : 0,
            bottom: showBottomToolbar && bottomToolbar != null ? 50 : 0,
            child: rightPanel!,
          ),

        // Layer 6: Fixed UI overlays (bottom toolbar)
        if (showBottomToolbar && bottomToolbar != null)
          Positioned(
            bottom: 0,
            left: showLeftPanel && leftPanel != null ? 250 : 0,
            right: showRightPanel && rightPanel != null ? 250 : 0,
            child: bottomToolbar!,
          ),
      ],
    );
  }
}

/// Default top toolbar implementation
class DefaultTopToolbar extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onExport;

  const DefaultTopToolbar({
    super.key,
    this.onUndo,
    this.onRedo,
    this.onNew,
    this.onOpen,
    this.onSave,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // File operations
          _buildIconButton(Icons.note_add, 'New', onNew),
          _buildIconButton(Icons.folder_open, 'Open', onOpen),
          _buildIconButton(Icons.save, 'Save', onSave),
          const VerticalDivider(color: Colors.white24),
          // Edit operations
          _buildIconButton(Icons.undo, 'Undo', onUndo),
          _buildIconButton(Icons.redo, 'Redo', onRedo),
          const VerticalDivider(color: Colors.white24),
          // Export
          _buildIconButton(Icons.ios_share, 'Export', onExport),
          const Spacer(),
          // App title
          Text(
            'Kivixa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

/// Default bottom toolbar implementation
class DefaultBottomToolbar extends StatelessWidget {
  final double? zoomLevel;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomReset;
  final String? statusText;

  const DefaultBottomToolbar({
    super.key,
    this.zoomLevel,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Status text
          if (statusText != null)
            Text(
              statusText!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          const Spacer(),
          // Zoom controls
          IconButton(
            icon: Icon(Icons.remove, color: Colors.white.withValues(alpha: 0.9)),
            tooltip: 'Zoom Out',
            onPressed: onZoomOut,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              zoomLevel != null ? '${(zoomLevel! * 100).toInt()}%' : '100%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white.withValues(alpha: 0.9)),
            tooltip: 'Zoom In',
            onPressed: onZoomIn,
          ),
          IconButton(
            icon: Icon(Icons.zoom_out_map, color: Colors.white.withValues(alpha: 0.9)),
            tooltip: 'Reset Zoom',
            onPressed: onZoomReset,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

/// Default right panel implementation
class DefaultRightPanel extends StatelessWidget {
  final List<Widget>? children;
  final String? title;

  const DefaultRightPanel({
    super.key,
    this.children,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200]?.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: children ?? [],
            ),
          ),
        ],
      ),
    );
  }
}

/// Default left panel implementation
class DefaultLeftPanel extends StatelessWidget {
  final List<Widget>? children;
  final String? title;

  const DefaultLeftPanel({
    super.key,
    this.children,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200]?.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: children ?? [],
            ),
          ),
        ],
      ),
    );
  }
}
