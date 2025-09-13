import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/editor/glassmorphism_toolbar.dart';
import 'package:kivixa/features/editor/split_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.templateName,
    required this.templateColor,
  });

  final String templateName;
  final Color templateColor;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _isImmersiveMode = false;

  void _toggleImmersiveMode() {
    setState(() {
      _isImmersiveMode = !_isImmersiveMode;
    });
    if (_isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isImmersiveMode
          ? null
          : AppBar(
              title: Text('Editing ${widget.templateName}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleImmersiveMode,
                ),
              ],
            ),
      body: const Stack(
        children: [
          SplitScreen(),
          GlassmorphismToolbar(),
        ],
      ),
    );
  }
}