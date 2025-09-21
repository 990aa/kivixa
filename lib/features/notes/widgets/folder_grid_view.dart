import 'package:flutter/material.dart';

class FolderGridView extends StatelessWidget {
  const FolderGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 10, // Example count
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPressStart: (details) {
            showContextMenu(context, details.globalPosition);
          },
          child: Card(
            color: Colors.grey[900],
            child: Center(
              child: Text(
                'Folder ${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
