
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/notes/widgets/paper_background.dart';
import 'package:scribble/scribble.dart';

class NotesDrawingCanvas extends StatefulWidget {
  final ScribbleNotifier notifier;
  final Uint8List? backgroundImage;

  const NotesDrawingCanvas({
    super.key,
    required this.notifier,
    this.backgroundImage,
  });

  @override
  State<NotesDrawingCanvas> createState() => _NotesDrawingCanvasState();
}

class _NotesDrawingCanvasState extends State<NotesDrawingCanvas> {
  PaperType _paperType = PaperType.blank;
  final TransformationController _transformationController =
      TransformationController();

  void _showContextMenu(BuildContext context, Offset offset) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
      ),
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
          _paperType = PaperType
              .values[(_paperType.index + 1) % PaperType.values.length];
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
                  final currentScale = _transformationController.value
                      .getMaxScaleOnAxis();
                  final newScale = (currentScale - scrolled / 1000).clamp(
                    0.5,
                    4.0,
                  );
                  _transformationController.value = Matrix4.identity()
                    ..scale(newScale);
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
                      if (widget.backgroundImage != null)
                        Image.memory(
                          widget.backgroundImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      PaperBackground(paperType: _paperType),
                      // Pointer logic and pressureCurve removed for compatibility with scribble 0.10.0+1
                      Scribble(notifier: widget.notifier, drawPen: true),
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
          // Tool buttons removed for compatibility with scribble 0.10.0+1
          _buildColorPalette(),
          _buildStrokeWidthSlider(),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              setState(() {
                _paperType = PaperType
                    .values[(_paperType.index + 1) % PaperType.values.length];
              });
            },
          ),
        ],
      ),
    );
  }

  // Tool button logic removed for compatibility with scribble 0.10.0+1

  // Tool icon logic removed for compatibility with scribble 0.10.0+1

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
      child: CircleAvatar(backgroundColor: color, radius: 12),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, value, child) {
        // strokeWidth property not available in scribble 0.10.0+1
        return Slider(
          value: 1,
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
