import 'package:flutter/material.dart';

class RoughNotepadPopup extends StatefulWidget {
  final VoidCallback? onClose;
  const RoughNotepadPopup({super.key, this.onClose});

  @override
  State<RoughNotepadPopup> createState() => _RoughNotepadPopupState();
}

class _RoughNotepadPopupState extends State<RoughNotepadPopup> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rough Notepad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      widget.onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Jot down anything... (not saved)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
