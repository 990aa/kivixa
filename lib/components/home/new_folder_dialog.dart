import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/theming/adaptive_alert_dialog.dart';
import 'package:kivixa/components/theming/adaptive_icon.dart';
import 'package:kivixa/components/theming/adaptive_text_field.dart';
import 'package:kivixa/i18n/strings.g.dart';

class NewFolderDialog extends StatefulWidget {
  const NewFolderDialog({
    // ignore: unused_element_parameter
    super.key,
    required this.createFolder,
    required this.doesFolderExist,
    this.currentPath,
  });

  final void Function(String, {Color? color}) createFolder;
  final bool Function(String) doesFolderExist;
  final String? currentPath;

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<NewFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  Color? _selectedColor;

  String? validateFolderName(String? folderName) {
    if (folderName == null || folderName.isEmpty) {
      return t.home.newFolder.folderNameEmpty;
    }
    folderName = reformatFolderName(folderName);
    if (folderName.contains('/') || folderName.contains('\\')) {
      return t.home.newFolder.folderNameContainsSlash;
    }
    if (widget.doesFolderExist(folderName)) {
      return t.home.newFolder.folderNameExists;
    }
    return null;
  }

  String reformatFolderName(String folderName) => folderName.trim();

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => _FolderColorPickerDialog(
        initialColor: _selectedColor,
        onColorSelected: (color) {
          setState(() => _selectedColor = color);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return AdaptiveAlertDialog(
      title: Text(t.home.newFolder.newFolder),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveTextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              focusOrder: const NumericFocusOrder(1),
              placeholder: t.home.newFolder.folderName,
              prefixIcon: const AdaptiveIcon(
                icon: Icons.create_new_folder,
                cupertinoIcon: CupertinoIcons.folder_badge_plus,
              ),
              validator: validateFolderName,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Folder Color:',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showColorPicker,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor ?? Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline, width: 2),
                    ),
                    child: _selectedColor == null
                        ? const Icon(Icons.folder, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedColor != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _selectedColor = null),
                    tooltip: 'Reset to default',
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        CupertinoDialogAction(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final folderName = reformatFolderName(_controller.text);
            widget.createFolder(folderName, color: _selectedColor);
            Navigator.of(context).pop();
          },
          child: Text(t.home.newFolder.create),
        ),
      ],
    );
  }
}

/// Color picker dialog for folder colors
class _FolderColorPickerDialog extends StatefulWidget {
  const _FolderColorPickerDialog({
    this.initialColor,
    required this.onColorSelected,
  });

  final Color? initialColor;
  final void Function(Color?) onColorSelected;

  @override
  State<_FolderColorPickerDialog> createState() =>
      _FolderColorPickerDialogState();
}

class _FolderColorPickerDialogState extends State<_FolderColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    if (widget.initialColor != null) {
      final hsl = HSLColor.fromColor(widget.initialColor!);
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
    } else {
      _hue = 210; // Blue default
      _saturation = 0.7;
      _lightness = 0.5;
    }
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return AlertDialog(
      title: const Text('Choose Folder Color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 2),
              ),
              child: const Icon(Icons.folder, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),

            // Hue slider (color wheel effect)
            const Text('Hue', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: List.generate(
                    360,
                    (i) => HSLColor.fromAHSL(
                      1.0,
                      i.toDouble(),
                      0.8,
                      0.5,
                    ).toColor(),
                  ),
                ),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 30,
                  trackShape: const RoundedRectSliderTrackShape(),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: _hue,
                  min: 0,
                  max: 359,
                  onChanged: (value) => setState(() => _hue = value),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Saturation slider
            const Text('Saturation', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Slider(
              value: _saturation,
              min: 0,
              max: 1,
              activeColor: _currentColor,
              onChanged: (value) => setState(() => _saturation = value),
            ),

            // Lightness slider
            const Text('Lightness', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Slider(
              value: _lightness,
              min: 0.2,
              max: 0.8,
              activeColor: _currentColor,
              onChanged: (value) => setState(() => _lightness = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(_currentColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
