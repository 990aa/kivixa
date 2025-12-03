import 'package:flutter/material.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// A floating hub icon that can be dragged around and shows a mini dock of tools.
///
/// The hub floats above all content and provides quick access to tools like AI chat,
/// browser, and other utilities. It supports drag gestures to reposition.
class FloatingHubOverlay extends StatefulWidget {
  const FloatingHubOverlay({super.key, required this.child});

  /// The main content of the app that the hub floats over.
  final Widget child;

  @override
  State<FloatingHubOverlay> createState() => _FloatingHubOverlayState();
}

class _FloatingHubOverlayState extends State<FloatingHubOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  var _isHovering = false;
  var _isDragging = false;

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
                // Expanded menu items
                if (controller.hubMenuExpanded) ...[
                  _buildMenuItem(
                    context: context,
                    icon: Icons.smart_toy_rounded,
                    label: 'AI Assistant',
                    isActive: controller.assistantOpen,
                    onTap: controller.toggleAssistant,
                    size: hubSize * 0.85,
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.language_rounded,
                    label: 'Browser',
                    isActive: controller.browserOpen,
                    onTap: controller.toggleBrowser,
                    size: hubSize * 0.85,
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.hub_rounded,
                    label: 'Knowledge Graph',
                    isActive: controller.isToolWindowOpen('knowledge_graph'),
                    onTap: () => controller.isToolWindowOpen('knowledge_graph')
                        ? controller.closeToolWindow('knowledge_graph')
                        : controller.openToolWindow('knowledge_graph'),
                    size: hubSize * 0.85,
                  ),
                  const SizedBox(height: 12),
                ],

                // Main hub button
                GestureDetector(
                  onPanStart: (_) {
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
                  onPanEnd: (_) {
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required double size,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size / 2),
        elevation: isActive ? 4 : 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: size * 0.5,
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
