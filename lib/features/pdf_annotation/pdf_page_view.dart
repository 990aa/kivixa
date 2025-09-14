import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPageView extends StatefulWidget {
  final String assetPath;

  const PdfPageView({Key? key, required this.assetPath}) : super(key: key);

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  late PdfViewerController controller;

  @override
  void initState() {
    super.initState();
    controller = PdfViewerController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => controller.zoomUp(),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => controller.zoomDown(),
          ),
        ],
      ),
      body: PdfViewer.asset(
        widget.assetPath,
        controller: controller,
        params: const PdfViewerParams(
          minScale: 1.0,
          maxScale: 3.0,
          panEnabled: true,
          scaleEnabled: true,
        ),
      ),
    );
  }
}
