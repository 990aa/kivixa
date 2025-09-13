import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/features/library/documents_notifier.dart';
import 'package:kivixa/features/library/sidebar.dart';
import 'package:kivixa/widgets/components/kivixa_button.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final documents = ref.watch(documentsNotifierProvider);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Library'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const Sidebar(),
      body: documents.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('Your documents will appear here.'),
            );
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final document = data[index];
              return ListTile(
                import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivixa/core/providers.dart';
import 'package:kivixa/features/library/documents_notifier.dart';
import 'package:kivixa/features/library/sidebar.dart';
import 'package:kivixa/widgets/components/kivixa_button.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final documents = ref.watch(documentsNotifierProvider);
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Library'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const Sidebar(),
      body: Column(
        children: [
          Expanded(
            child: documents.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Your documents will appear here.'),
                  );
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final document = data[index];
                    return ListTile(
                      title: Text(document.title),
                      onTap: () {
                        // TODO: Navigate to document editor
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(documentsNotifierProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          connectivity.when(
            data: (result) {
              final isOffline = result == ConnectivityResult.none;
              return Container(
                color: isOffline ? Colors.red : Colors.green,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOffline ? Icons.signal_wifi_off : Icons.signal_wifi_4_bar,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOffline ? 'Offline' : 'Online',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Hero(
        tag: 'create_document_fab',
        child: KivixaButton(
          buttonType: KivixaButtonType.floating,
          onPressed: () {
            _showCreateDocumentDialog(context, ref);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateDocumentDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Document'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Document Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text;
                if (title.isNotEmpty) {
                  ref.read(documentsNotifierProvider.notifier).createDocument(title);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
                onTap: () {
                  // TODO: Navigate to document editor
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(documentsNotifierProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Hero(
        tag: 'create_document_fab',
        child: KivixaButton(
          buttonType: KivixaButtonType.floating,
          onPressed: () {
            _showCreateDocumentDialog(context, ref);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateDocumentDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Document'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Document Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text;
                if (title.isNotEmpty) {
                  ref.read(documentsNotifierProvider.notifier).createDocument(title);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
