import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:scribble/scribble.dart';

class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final drawingBloc = BlocProvider.of<DrawingBloc>(context);

    return BlocBuilder<DrawingBloc, DrawingState>(
      builder: (context, state) {
        if (state is DrawingLoadSuccess) {
          final notifier = state.notifier;
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
                  onPressed: () => notifier.undo(),
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: () => notifier.redo(),
                ),
                if (notifier.value is Drawing)
                  IconButton(
                    icon: const Icon(Icons.color_lens),
                    onPressed: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Color'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor:
                                  Color((notifier.value as Drawing).selectedColor),
                              onColorChanged: (color) {
                                Navigator.of(context).pop(color);
                              },
                            ),
                          ),
                        ),
                      );
                      if (color != null) {
                        drawingBloc.add(ColorChanged(color));
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
                          value: notifier.value.selectedWidth,
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
                      drawingBloc.add(StrokeWidthChanged(strokeWidth));
                    }
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}