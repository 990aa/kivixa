import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/main.dart';
import 'package:kivixa/pages/home/home.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:window_manager/window_manager.dart';

/// A custom title bar that matches the app's theme.
/// Includes window controls, theme toggle, and settings quick access.
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key, required this.child});

  final Widget child;

  /// Height of the title bar (matches Windows default)
  static const height = 32.0;

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  var _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  void _toggleTheme() {
    // Toggle only between light and dark (no system/auto)
    final currentMode = stows.appTheme.value;
    final newMode = (currentMode == ThemeMode.dark)
        ? ThemeMode.light
        : ThemeMode.dark;
    stows.appTheme.value = newMode;
  }

  void _goToSettings() {
    final settingsPath = pathToFunction(RoutePaths.home)({
      'subpage': HomePage.settingsSubpage,
    });
    // Use rootNavigatorKey context to access GoRouter
    final navigatorContext = App.rootNavigatorKey.currentContext;
    if (navigatorContext != null) {
      GoRouter.of(navigatorContext).go(settingsPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show custom title bar on desktop platforms
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          onDoubleTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          child: Container(
            height: CustomTitleBar.height,
            color: colorScheme.surface,
            child: Row(
              children: [
                const SizedBox(width: 8),
                // App icon
                Image.asset('assets/icon/icon.png', width: 18, height: 18),
                const SizedBox(width: 8),
                // App name (capitalized)
                Text(
                  'Kivixa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
                const SizedBox(width: 16),
                // Theme toggle button
                _TitleBarButton(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  tooltip: 'Toggle theme',
                  onPressed: _toggleTheme,
                  colorScheme: colorScheme,
                ),
                // Settings button
                _TitleBarButton(
                  icon: Icons.settings,
                  tooltip: 'Settings',
                  onPressed: _goToSettings,
                  colorScheme: colorScheme,
                ),
                // Draggable spacer
                const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
                // Window controls
                _WindowControls(
                  isMaximized: _isMaximized,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// A button for the title bar with hover effects.
class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colorScheme,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          hoverColor: widget.colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: widget.colorScheme.onSurface.withValues(alpha: 0.12),
          child: Container(
            width: 32,
            height: CustomTitleBar.height,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.colorScheme.onSurface.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Window control buttons (minimize, maximize/restore, close).
class _WindowControls extends StatelessWidget {
  const _WindowControls({required this.isMaximized, required this.colorScheme});

  final bool isMaximized;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          tooltip: 'Minimize',
          onPressed: () => windowManager.minimize(),
          colorScheme: colorScheme,
        ),
        _WindowButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onPressed: () async {
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          colorScheme: colorScheme,
        ),
        _WindowButton(
          icon: Icons.close,
          tooltip: 'Close',
          onPressed: () => windowManager.close(),
          colorScheme: colorScheme,
          isClose: true,
        ),
      ],
    );
  }
}

/// A window control button with hover effects.
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colorScheme,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? Colors.red
        : widget.colorScheme.onSurface.withValues(alpha: 0.08);
    final iconColor = widget.isClose && _isHovered
        ? Colors.white
        : widget.colorScheme.onSurface.withValues(alpha: 0.8);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          hoverColor: hoverColor,
          splashColor: hoverColor.withValues(alpha: 0.3),
          child: Container(
            width: 46,
            height: CustomTitleBar.height,
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : Colors.transparent,
            ),
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
