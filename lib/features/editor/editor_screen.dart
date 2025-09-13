import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/features/editor/floating_toolbar.dart';

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
      SystemChrome.setEnabledSystemU-I-Mode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemU-I-Mode(SystemUiMode.edgeToEdge);
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
      body: Stack(
        children: [
          GestureDetector(
            onTap: _isImmersiveMode ? _toggleImmersiveMode : null,
            child: Hero(
              tag: 'template_card_${widget.templateName}',
              child: Container(
                color: widget.templateColor,
                child: Center(
                  child: Text(
                    'This is the ${widget.templateName} template.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
          ),
          const FloatingToolbar(),
        ],
      ),
    );
  }
}
