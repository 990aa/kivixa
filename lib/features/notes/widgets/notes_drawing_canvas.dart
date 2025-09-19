
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/notes/widgets/paper_background.dart';
import 'package:scribble/scribble.dart';

class NotesDrawingCanvas extends StatefulWidget {
  final ScribbleNotifier notifier;

  const NotesDrawingCanvas({super.key, required this.notifier});

  @override
  State<NotesDrawingCanvas> createState() => _NotesDrawingCanvasState();
}

class _NotesDrawingCanvasState extends State<NotesDrawingCanvas> {
  PaperType _paperType = PaperType.blank;
  final TransformationController _transformationController = TransformationController();

  void _showContextMenu(BuildContext context, Offset offset) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        const PopupMenuItem(value: 'cut', child: Text('Cut')),
        const PopupMenuItem(value: 'paste', child: Text('Paste')),
        const PopupMenuItem(value: 'paper', child: Text('Change Paper Type')),
      ],
    );

    switch (result) {
      case 'copy':
      // TODO: Implement copy
        break;
      case 'cut':
      // TODO: Implement cut
        break;
      case 'paste':
      // TODO: Implement paste
        break;
      case 'paper':
        setState(() {
          _paperType =
              PaperType.values[(_paperType.index + 1) % PaperType.values.length];
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
        UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
        RedoIntent(),
      },
      actions: {
        UndoIntent: CallbackAction(onInvoke: (e) => widget.notifier.undo()),
        RedoIntent: CallbackAction(onInvoke: (e) => widget.notifier.redo()),
      },
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final scrolled = pointerSignal.scrollDelta.dy;
                  final currentScale = _transformationController.value.getMaxScaleOnAxis();
                  final newScale = (currentScale - scrolled / 1000).clamp(0.5, 4.0);
                  _transformationController.value = Matrix4.identity()..scale(newScale);
                }
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: GestureDetector(
                  onSecondaryTapUp: (details) =>
                      _showContextMenu(context, details.globalPosition),
                  child: Stack(
                    children: [
                      PaperBackground(paperType: _paperType),
                      Listener(
                        onPointerDown: (details) {
                          switch (details.kind) {
                            case PointerDeviceKind.stylus:
                            case PointerDeviceKind.invertedStylus:
                              widget.notifier.setAllowedPointers(1);
                              break;
                            case PointerDeviceKind.touch:
                              widget.notifier.setAllowedPointers(2);
                              break;
                            case PointerDeviceKind.mouse:
                              widget.notifier.setAllowedPointers(1);
                              break;
                            default:
                          }
                        },
                        child: Scribble(
                          notifier: widget.notifier,
                          drawPen: true,
                          pressureCurve: Curves.easeInOut,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => widget.notifier.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => widget.notifier.redo(),
          ),
          _buildToolButton(ScribbleTool.pen),
          _buildToolButton(ScribbleTool.eraser),
          _buildToolButton(ScribbleTool.highlighter),
          _buildColorPalette(),
          _buildStrokeWidthSlider(),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              setState(() {
                _paperType = PaperType.values[
                (_paperType.index + 1) % PaperType.values.length];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(ScribbleTool tool) {
    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, value, child) {
        final isSelected = value.activeTool == tool;
        return IconButton(
          icon: Icon(
            _getIconForTool(tool),
            color: isSelected ? Theme.of(context).colorScheme.secondary : null,
          ),
          onPressed: () => widget.notifier.setTool(tool),
        );
      },
    );
  }

  IconData _getIconForTool(ScribbleTool tool) {
    switch (tool) {
      case ScribbleTool.pen:
        return Icons.edit;
      case ScribbleTool.eraser:
        return Icons.cleaning_services;
      case ScribbleTool.highlighter:
        return Icons.highlight;
      default:
        return Icons.edit;
    }
  }

  Widget _buildColorPalette() {
    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, value, child) {
        return Row(
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => widget.notifier.setColor(color),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 12,
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, value, child) {
        return Slider(
          value: value.strokeWidth,
          min: 1,
          max: 10,
          onChanged: (val) => widget.notifier.setStrokeWidth(val),
        );
      },
    );
  }
}

class UndoIntent extends Intent {}

class RedoIntent extends Intent {}
