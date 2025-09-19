import 'package:flutter/material.dart';

class NotesHomeScreen extends StatelessWidget {
  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Container(), // TODO: implement document list
      floatingActionButton: FloatingActionButton(
        onPressed: () { // TODO: implement create new document
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
