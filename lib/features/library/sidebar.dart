import 'package:flutter/material.dart';
import 'package:kivixa/services/export_manager.dart';
import 'package:kivixa/services/import_manager.dart';
import 'package:kivixa/widgets/file_transfer_view.dart';
import 'package:shimmer/shimmer.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _isLoading ? _buildSkeletonLoader() : _buildContent(),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: List.generate(10, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 24.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.import_export),
          title: const Text('Import/Export'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FileTransferView(
                  importManager: ImportManager(),
                  exportManager: ExportManager(),
                ),
              ),
            );
          },
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: 20, // Dummy data
            itemBuilder: (context, index) {
              return GridTile(
                child: Container(
                  color: Colors.blue.shade100,
                  child: Center(
                    child: Text('Item $index'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
