import 'package:flutter/material.dart';

class ChecklistInteractive extends StatefulWidget {
  final List<String>? initialItems;
  const ChecklistInteractive({super.key, this.initialItems});

  @override
  State<ChecklistInteractive> createState() => _ChecklistInteractiveState();
}

class _ChecklistInteractiveState extends State<ChecklistInteractive> {
  late List<_ChecklistItem> _items;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items =
        widget.initialItems?.map((e) => _ChecklistItem(e, false)).toList() ??
        [];
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _items.add(_ChecklistItem(text, false));
        _controller.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Add item...'),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Dismissible(
                key: ValueKey(item.text + index.toString()),
                onDismissed: (_) => _removeItem(index),
                background: Container(color: Colors.red),
                child: CheckboxListTile(
                  value: item.checked,
                  onChanged: (val) {
                    setState(() => item.checked = val ?? false);
                  },
                  title: Text(
                    item.text,
                    style: TextStyle(
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem {
  String text;
  bool checked;
  _ChecklistItem(this.text, this.checked);
}
