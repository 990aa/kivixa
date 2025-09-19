import 'package:flutter/material.dart';

class NotesHomeScreen extends StatelessWidget {
  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: ListView.builder(
        itemCount: 10, // Placeholder for document list
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Note ${index + 1}'),
            onTap: () {
              Navigator.pushNamed(context, '/notes/editor', arguments: 'doc-id-${index + 1}');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/notes/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
