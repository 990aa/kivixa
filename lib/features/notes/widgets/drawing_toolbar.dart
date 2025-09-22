import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';

class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final drawingBloc = BlocProvider.of<DrawingBloc>(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => drawingBloc.add(Undo()),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => drawingBloc.add(Redo()),
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Color'),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: drawingBloc.state.color,
                      onColorChanged: (color) {
                        Navigator.of(context).pop(color);
                      },
                    ),
                  ),
                ),
              );
              if (color != null) {
                drawingBloc.add(ChangeColor(color));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.line_weight),
            onPressed: () async {
              final strokeWidth = await showDialog<double>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Stroke Width'),
                  content: Slider(
                    value: drawingBloc.state.strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    onChanged: (value) {
                      // No need to call setState, just for live preview
                    },
                    onChangeEnd: (value) {
                      Navigator.of(context).pop(value);
                    },
                  ),
                ),
              );
              if (strokeWidth != null) {
                drawingBloc.add(ChangeStrokeWidth(strokeWidth));
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: drawingBloc.state.isErasing ? Colors.blue : Colors.black,
            ),
            onPressed: () => drawingBloc.add(ToggleEraser()),
          ),
        ],
      ),
    );
  }
}

// A simple block-based color picker.
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
        Colors.brown,
        Colors.grey,
        Colors.blueGrey,
        Colors.black,
        Colors.white,
      ]
          .map((color) => GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color:
                          pickerColor == color ? Colors.blue : Colors.transparent,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
