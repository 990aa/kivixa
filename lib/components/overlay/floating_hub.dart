import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// Layout style for the hub menu.
enum HubMenuLayout {
  /// Vertical list of icons (default).
  vertical,

  /// Circular arrangement around the hub.
  circular,
}

/// A floating hub icon that can be dragged around and shows a mini dock of tools.
///
/// The hub floats above all content and provides quick access to tools like AI chat,
/// browser, and other utilities. It supports drag gestures to reposition.
class FloatingHubOverlay extends StatefulWidget {
  const FloatingHubOverlay({
    super.key,
    required this.child,
    this.menuLayout = HubMenuLayout.vertical,
  });

  /// The main content of the app that the hub floats over.
  final Widget child;

  /// Layout style for the menu items.
  final HubMenuLayout menuLayout;

  @override
  State<FloatingHubOverlay> createState() => _FloatingHubOverlayState();
}

class _FloatingHubOverlayState extends State<FloatingHubOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  late final Animation<double> _menuAnimation;
  var _isHovering = false;
  var _isDragging = false;

  /// Whether we're on a desktop platform with mouse support.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
    _menuAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutBack,
    );
    OverlayController.instance.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    _isHovering = true;
    _hoverController.forward();
  }

  void _onHoverExit() {
    _isHovering = false;
    if (!_isDragging) {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final controller = OverlayController.instance;

        // Calculate actual hub position from normalized coordinates
        final hubSize = 56.0 * controller.hubScale;
        final hubX = controller.hubPosition.dx * (screenSize.width - hubSize);
        final hubY = controller.hubPosition.dy * (screenSize.height - hubSize);

        return Stack(
          children: [
            // Main app content
            widget.child,

            // Tap catcher when menu is expanded
            if (controller.hubMenuExpanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.collapseHubMenu,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // Floating hub
            Positioned(
              left: hubX,
              top: hubY,
              child: _buildHub(context, controller, screenSize),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHub(
    BuildContext context,
    OverlayController controller,
    Size screenSize,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hubSize = 56.0 * controller.hubScale;
    // Increase touch targets on desktop for better mouse interaction
    final touchPadding = _isDesktop ? 4.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: HoverAnimationBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          final opacity = _isDragging || _isHovering
              ? 1.0
              : controller.hubOpacity +
                    (_hoverAnimation.value * (1.0 - controller.hubOpacity));

          return Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Expanded menu items using registered tools
                if (controller.hubMenuExpanded)
                  _buildMenu(context, controller, hubSize),

                // Main hub button
                Padding(
                  padding: EdgeInsets.all(touchPadding),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      _isDragging = true;
                      _hoverController.forward();
                    },
                    onPanUpdate: (details) {
                      final newX =
                          (controller.hubPosition.dx *
                                  (screenSize.width - hubSize) +
                              details.delta.dx) /
                          (screenSize.width - hubSize);
                      final newY =
                          (controller.hubPosition.dy *
                                  (screenSize.height - hubSize) +
                              details.delta.dy) /
                          (screenSize.height - hubSize);
                      controller.updateHubPosition(Offset(newX, newY));
                    },
                    onPanEnd: (details) {
                      _isDragging = false;
                      if (!_isHovering) {
                        _hoverController.reverse();
                      }
                    },
                    onTap: controller.toggleHubMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: hubSize,
                      height: hubSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(hubSize / 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: controller.hubMenuExpanded ? 0.125 : 0,
                        child: Icon(
                          controller.hubMenuExpanded
                              ? Icons.close_rounded
                              : Icons.apps_rounded,
                          color: colorScheme.onPrimary,
                          size: hubSize * 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context,
    OverlayController controller,
    double hubSize,
  ) {
    final tools = controller.registeredTools;
    if (tools.isEmpty) return const SizedBox.shrink();

    switch (widget.menuLayout) {
      case HubMenuLayout.vertical:
        return _buildVerticalMenu(context, tools, hubSize);
      case HubMenuLayout.circular:
        return _buildCircularMenu(context, tools, hubSize);
    }
  }

  Widget _buildVerticalMenu(
    BuildContext context,
    List<OverlayTool> tools,
    double hubSize,
  ) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _menuAnimation.value,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: _menuAnimation.value.clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < tools.length; i++) ...[
                  _buildMenuItem(
                    context: context,
                    tool: tools[i],
                    size: hubSize * 0.85,
                    animationDelay: i * 0.1,
                  ),
                  if (i < tools.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularMenu(
    BuildContext context,
    List<OverlayTool> tools,
    double hubSize,
  ) {
    final itemSize = hubSize * 0.85;
    final radius = hubSize * 1.5;

    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        return SizedBox(
          width: radius * 2 + itemSize,
          height: radius + itemSize / 2,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              for (int i = 0; i < tools.length; i++)
                _buildCircularMenuItem(
                  context: context,
                  tool: tools[i],
                  index: i,
                  total: tools.length,
                  radius: radius * _menuAnimation.value,
                  size: itemSize,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularMenuItem({
    required BuildContext context,
    required OverlayTool tool,
    required int index,
    required int total,
    required double radius,
    required double size,
  }) {
    // Calculate angle for this item (spread from -90° to 90° above the hub)
    const startAngle = -math.pi;
    const endAngle = 0.0;
    final angleStep = (endAngle - startAngle) / (total + 1);
    final angle = startAngle + angleStep * (index + 1);

    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);

    return Positioned(
      left: radius + dx - size / 2 + size / 2,
      top: radius + dy,
      child: Transform.scale(
        scale: _menuAnimation.value.clamp(0.0, 1.0),
        child: Opacity(
          opacity: _menuAnimation.value.clamp(0.0, 1.0),
          child: _buildMenuItem(context: context, tool: tool, size: size),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required OverlayTool tool,
    required double size,
    double animationDelay = 0.0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = tool.active;
    // Increase touch targets on desktop
    final touchPadding = _isDesktop ? 4.0 : 0.0;

    return Tooltip(
      message: tool.label,
      child: Padding(
        padding: EdgeInsets.all(touchPadding),
        child: Material(
          color: isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size / 2),
          elevation: isActive ? 4 : 2,
          child: InkWell(
            onTap: tool.onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                tool.icon,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple animation builder wrapper for easier animation usage.
class HoverAnimationBuilder extends AnimatedWidget {
  const HoverAnimationBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
