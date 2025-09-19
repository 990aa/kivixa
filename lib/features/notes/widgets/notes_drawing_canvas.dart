
import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

class NotesDrawingCanvas extends StatefulWidget {
  const NotesDrawingCanvas({super.key});

  @override
  State<NotesDrawingCanvas> createState() => _NotesDrawingCanvasState();
}

class _NotesDrawingCanvasState extends State<NotesDrawingCanvas> {
  late ScribbleNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ScribbleNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return Scribble(
      notifier: notifier,
      drawPen: true,
    );
  }
}
