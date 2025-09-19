import 'package:flutter/material.dart';

class NoteEditorScreen extends StatelessWidget {
  final String? documentId;

  const NoteEditorScreen({super.key, this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
      ),
      body: Container(), // TODO: implement note editor
    );
  }
}
