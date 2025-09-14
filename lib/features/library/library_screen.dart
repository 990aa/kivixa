import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kivixa/features/library/sidebar.dart';
import 'package:kivixa/providers.dart'; // Changed this import
import 'package:kivixa/widgets/empty_state_animated.dart';
import 'package:kivixa/widgets/contextual_help_overlay.dart';
import 'package:kivixa/widgets/premium_error_dialog.dart';

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
                  return Stack(
                    children: [
                      const EmptyStateAnimated(
                        message: 'Your documents will appear here.',
                        icon: Icons.description_outlined,
                      ),
                      Positioned(
                        bottom: 32,
                        right: 32,
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => const ContextualHelpOverlay(
                                message:
                                    'Tap the + button to create your first document!',
                              ),
                            );
                          },
                          label: const Text('Help'),
                          icon: const Icon(Icons.help_outline),
                        ),
                      ),
                    ],
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    // Preload next items if near end
                    if (scroll.metrics.pixels >
                        scroll.metrics.maxScrollExtent - 200) {
                      // TODO: Preload more documents if paginated
                    }
                    return false;
                  },
                  child: ListView.builder(
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
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => PremiumErrorDialog(
                error: error.toString(),
                onRetry: () => ref.invalidate(documentsNotifierProvider),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: connectivity.when(
              data: (status) {
                if (status == ConnectivityResult.none) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Offline mode', style: TextStyle(color: Colors.red)),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
