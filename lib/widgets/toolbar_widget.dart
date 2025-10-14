import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/drawing_tool.dart';

/// Floating toolbar widget for annotation controls
///
/// Features:
/// - Tool selection (pen, highlighter, eraser)
/// - Independent color pickers for pen and highlighter
/// - Stroke width slider
/// - Action buttons (undo, redo, clear, save, insert image)
/// - Material Design 3 styling
/// - Tablet-optimized button sizes
class ToolbarWidget extends StatefulWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final Function(DrawingTool) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onInsertImage;
  final Color penColor;
  final Color highlighterColor;

  const ToolbarWidget({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onSave,
    required this.onInsertImage,
    required this.penColor,
    required this.highlighterColor,
  });

  @override
  State<ToolbarWidget> createState() => _ToolbarWidgetState();
}

class _ToolbarWidgetState extends State<ToolbarWidget> {
  bool _showPenSettings = false;
  bool _showHighlighterSettings = false;

  /// Show color picker dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: widget.currentColor,
            onColorChanged: widget.onColorChanged,
            pickerAreaHeightPercent: 0.8,
            displayThumbColor: true,
            enableAlpha: false,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Get stroke width range based on tool
  double _getMinStrokeWidth() {
    return widget.currentTool == DrawingTool.highlighter ? 8.0 : 1.0;
  }

  double _getMaxStrokeWidth() {
    return widget.currentTool == DrawingTool.highlighter ? 20.0 : 10.0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main toolbar row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool buttons
                _buildCompactToolButton(
                  DrawingTool.pen,
                  Icons.edit,
                  'Pen',
                  onExpand: widget.currentTool == DrawingTool.pen
                      ? () {
                          setState(() {
                            _showPenSettings = !_showPenSettings;
                            _showHighlighterSettings = false;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 4),
                _buildCompactToolButton(
                  DrawingTool.highlighter,
                  Icons.highlight,
                  'Highlight',
                  onExpand: widget.currentTool == DrawingTool.highlighter
                      ? () {
                          setState(() {
                            _showHighlighterSettings =
                                !_showHighlighterSettings;
                            _showPenSettings = false;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 4),
                _buildCompactToolButton(
                  DrawingTool.eraser,
                  Icons.auto_fix_high,
                  'Eraser',
                ),
                const VerticalDivider(width: 16, thickness: 1),
                // Action buttons
                _buildCompactActionButton(Icons.undo, 'Undo', widget.onUndo),
                const SizedBox(width: 4),
                _buildCompactActionButton(Icons.redo, 'Redo', widget.onRedo),
                const SizedBox(width: 4),
                _buildCompactActionButton(
                  Icons.image,
                  'Insert Image',
                  widget.onInsertImage,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                _buildCompactActionButton(
                  Icons.delete_sweep,
                  'Clear',
                  widget.onClear,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                _buildCompactActionButton(
                  Icons.save,
                  'Save',
                  widget.onSave,
                  color: Colors.green,
                ),
              ],
            ),

            // Expandable pen settings
            if (_showPenSettings && widget.currentTool == DrawingTool.pen) ...[
              const Divider(height: 8),
              _buildToolSettings(),
            ],

            // Expandable highlighter settings
            if (_showHighlighterSettings &&
                widget.currentTool == DrawingTool.highlighter) ...[
              const Divider(height: 8),
              _buildToolSettings(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build compact tool button with optional expand arrow
  Widget _buildCompactToolButton(
    DrawingTool tool,
    IconData icon,
    String tooltip, {
    VoidCallback? onExpand,
  }) {
    final isSelected = widget.currentTool == tool;
    final hasSettings = tool != DrawingTool.eraser;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => widget.onToolChanged(tool),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.grey.shade700,
                ),
                if (hasSettings && isSelected) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onExpand,
                    child: Icon(
                      _showPenSettings || _showHighlighterSettings
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact action button
  Widget _buildCompactActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Build tool settings (color and stroke width)
  Widget _buildToolSettings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color preview and picker
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Stroke width slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Width: ${widget.currentStrokeWidth.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    // Visual preview
                    Container(
                      width: 40,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomPaint(
                        painter: _StrokePreviewPainter(
                          color: widget.currentColor,
                          strokeWidth: widget.currentStrokeWidth,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                  child: Slider(
                    value: widget.currentStrokeWidth,
                    min: _getMinStrokeWidth(),
                    max: _getMaxStrokeWidth(),
                    divisions: 19,
                    onChanged: widget.onStrokeWidthChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for stroke width preview
class _StrokePreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _StrokePreviewPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(10, size.height / 2);
    path.lineTo(size.width - 10, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePreviewPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
