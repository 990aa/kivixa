import 'package:flutter/material.dart';
import '../models/layer_blend_mode.dart';

/// Widget for selecting layer blend modes
class BlendModeSelector extends StatelessWidget {
  final LayerBlendMode selectedMode;
  final ValueChanged<LayerBlendMode> onModeChanged;
  final bool showTechnicalModes;

  const BlendModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.showTechnicalModes = false,
  });

  @override
  Widget build(BuildContext context) {
    final creativeModes = LayerBlendMode.getCreativeModes();
    final technicalModes = LayerBlendMode.getTechnicalModes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creative modes section
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Creative Modes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...creativeModes.map((mode) => _buildModeItem(context, mode)),

        // Technical modes section (optional)
        if (showTechnicalModes) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Technical Modes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...technicalModes.map((mode) => _buildModeItem(context, mode)),
        ],
      ],
    );
  }

  Widget _buildModeItem(BuildContext context, LayerBlendMode mode) {
    final isSelected = mode == selectedMode;

    return ListTile(
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      title: Text(mode.displayName),
      subtitle: Text(
        mode.getDescription(),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () => onModeChanged(mode),
    );
  }
}

/// Compact blend mode selector (dropdown style)
class CompactBlendModeSelector extends StatelessWidget {
  final LayerBlendMode selectedMode;
  final ValueChanged<LayerBlendMode> onModeChanged;

  const CompactBlendModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final creativeModes = LayerBlendMode.getCreativeModes();

    return DropdownButton<LayerBlendMode>(
      value: selectedMode,
      isExpanded: true,
      items: creativeModes.map((mode) {
        return DropdownMenuItem<LayerBlendMode>(
          value: mode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mode.displayName),
              Text(
                mode.getDescription(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (mode) {
        if (mode != null) {
          onModeChanged(mode);
        }
      },
    );
  }
}

/// Bottom sheet for blend mode selection
class BlendModeBottomSheet extends StatelessWidget {
  final LayerBlendMode selectedMode;
  final ValueChanged<LayerBlendMode> onModeChanged;

  const BlendModeBottomSheet({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  static Future<LayerBlendMode?> show({
    required BuildContext context,
    required LayerBlendMode currentMode,
  }) {
    return showModalBottomSheet<LayerBlendMode>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return BlendModeBottomSheet(
            selectedMode: currentMode,
            onModeChanged: (mode) {
              Navigator.pop(context, mode);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Blend Mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Blend mode list
          Expanded(
            child: SingleChildScrollView(
              child: BlendModeSelector(
                selectedMode: selectedMode,
                onModeChanged: onModeChanged,
                showTechnicalModes: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blend mode preview widget (shows effect on sample colors)
class BlendModePreview extends StatelessWidget {
  final LayerBlendMode blendMode;
  final Size size;

  const BlendModePreview({
    super.key,
    required this.blendMode,
    this.size = const Size(100, 100),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _BlendModePreviewPainter(blendMode: blendMode.blendMode),
    );
  }
}

class _BlendModePreviewPainter extends CustomPainter {
  final BlendMode blendMode;

  _BlendModePreviewPainter({required this.blendMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base layer (gradient)
    final baseRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red, Colors.blue],
      ).createShader(baseRect);
    canvas.drawRect(baseRect, basePaint);

    // Draw blend layer with blend mode
    final blendPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.7)
      ..blendMode = blendMode;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.4,
      blendPaint,
    );
  }

  @override
  bool shouldRepaint(_BlendModePreviewPainter oldDelegate) {
    return oldDelegate.blendMode != blendMode;
  }
}
