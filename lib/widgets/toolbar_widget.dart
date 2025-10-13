import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/drawing_tool.dart';

/// Floating toolbar widget for annotation controls
///
/// Features:
/// - Tool selection (pen, highlighter, eraser)
/// - Color picker
/// - Stroke width slider
/// - Action buttons (undo, redo, clear, save)
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with collapse button
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.edit, size: 20),
                  ),
                  const Text(
                    'Annotation Tools',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.expand_less),
                    ),
                    onPressed: _toggleExpand,
                    iconSize: 20,
                  ),
                ],
              ),

              // Expandable content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),

                    // Tool selector buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildToolButton(DrawingTool.pen, Icons.edit, 'Pen'),
                          _buildToolButton(
                            DrawingTool.highlighter,
                            Icons.highlight,
                            'Highlighter',
                          ),
                          _buildToolButton(
                            DrawingTool.eraser,
                            Icons.auto_fix_high,
                            'Eraser',
                          ),
                        ],
                      ),
                    ),

                    // Color picker and stroke width (hidden for eraser)
                    if (widget.currentTool != DrawingTool.eraser) ...[
                      const Divider(),

                      // Color picker button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Color:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showColorPicker,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: widget.currentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showColorPicker,
                                icon: const Icon(Icons.palette, size: 18),
                                label: const Text('Pick Color'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),

                      // Stroke width slider
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Width:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.currentStrokeWidth.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                // Visual preview
                                Container(
                                  width: 60,
                                  height: 24,
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
                            Slider(
                              value: widget.currentStrokeWidth,
                              min: _getMinStrokeWidth(),
                              max: _getMaxStrokeWidth(),
                              divisions: 19,
                              onChanged: widget.onStrokeWidthChanged,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Divider(),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildActionButton(Icons.undo, 'Undo', widget.onUndo),
                          _buildActionButton(Icons.redo, 'Redo', widget.onRedo),
                          _buildActionButton(
                            Icons.delete_sweep,
                            'Clear',
                            widget.onClear,
                            color: Colors.red,
                          ),
                          _buildActionButton(
                            Icons.save,
                            'Save',
                            widget.onSave,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build tool selection button
  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = widget.currentTool == tool;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => widget.onToolChanged(tool),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Build action button
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: color?.withValues(alpha: 0.1),
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
        minimumSize: const Size(80, 36),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
