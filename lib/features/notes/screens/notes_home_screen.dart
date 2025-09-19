import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_event.dart';
import 'package:kivixa/features/notes/blocs/notes_state.dart';

import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(NotesLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotesLoadSuccess) {
            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return ListTile(
                  title: Text(note.title),
                  onTap: () {
                    Navigator.pushNamed(context, '/notes/editor', arguments: note.id);
                  },
                );
              },
            );
          } else if (state is NotesLoadFailure) {
            return Center(child: Text(state.error));
          } else {
            return const Center(child: Text('No notes found.'));
          }
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
