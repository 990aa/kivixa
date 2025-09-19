import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kivixa/features/notes/models/notes_settings.dart';
import 'package:kivixa/features/notes/services/settings_service.dart';

class NotesSettingsScreen extends StatefulWidget {
  const NotesSettingsScreen({super.key});

  @override
  State<NotesSettingsScreen> createState() => _NotesSettingsScreenState();
}

class _NotesSettingsScreenState extends State<NotesSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  NotesSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _updateSetting(VoidCallback updater) {
    setState(() {
      updater();
      _settingsService.saveSettings(_settings!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Settings'),
      ),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('Note Preferences'),
                _buildDropdownSetting<PaperType>(
                  title: 'Default Paper Type',
                  value: _settings!.defaultPaperType,
                  items: PaperType.values,
                  onChanged: (value) => _updateSetting(() => _settings!.defaultPaperType = value!),
                ),
                _buildColorPickerSetting(
                  title: 'Default Pen Color',
                  color: _settings!.defaultPenColor,
                  onColorChanged: (color) => _updateSetting(() => _settings!.defaultPenColor = color),
                ),
                _buildSliderSetting(
                  title: 'Default Stroke Width',
                  value: _settings!.defaultStrokeWidth,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  onChanged: (value) => _updateSetting(() => _settings!.defaultStrokeWidth = value),
                ),
                _buildDropdownSetting<AutoSaveFrequency>(
                  title: 'Auto-save Frequency',
                  value: _settings!.autoSaveFrequency,
                  items: AutoSaveFrequency.values,
                  onChanged: (value) => _updateSetting(() => _settings!.autoSaveFrequency = value!),
                ),
                _buildDropdownSetting<PaperSize>(
                  title: 'Paper Size',
                  value: _settings!.paperSize,
                  items: PaperSize.values,
                  onChanged: (value) => _updateSetting(() => _settings!.paperSize = value!),
                ),
                _buildDropdownSetting<ExportQuality>(
                  title: 'Export Quality',
                  value: _settings!.exportQuality,
                  items: ExportQuality.values,
                  onChanged: (value) => _updateSetting(() => _settings!.exportQuality = value!),
                ),
                _buildSectionTitle('Drawing Preferences'),
                _buildSwitchSetting(
                  title: 'Stylus-only Mode',
                  value: _settings!.stylusOnlyMode,
                  onChanged: (value) => _updateSetting(() => _settings!.stylusOnlyMode = value),
                ),
                _buildSliderSetting(
                  title: 'Palm Rejection Sensitivity',
                  value: _settings!.palmRejectionSensitivity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => _updateSetting(() => _settings!.palmRejectionSensitivity = value),
                ),
                _buildSliderSetting(
                  title: 'Pressure Sensitivity',
                  value: _settings!.pressureSensitivity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => _updateSetting(() => _settings!.pressureSensitivity = value),
                ),
                _buildSwitchSetting(
                  title: 'Enable Zoom Gestures',
                  value: _settings!.zoomGestureEnabled,
                  onChanged: (value) => _updateSetting(() => _settings!.zoomGestureEnabled = value),
                ),
                _buildSectionTitle('Storage and Sync'),
                _buildDropdownSetting<AutoCleanup>(
                  title: 'Auto-cleanup Old Documents',
                  value: _settings!.autoCleanup,
                  items: AutoCleanup.values,
                  onChanged: (value) => _updateSetting(() => _settings!.autoCleanup = value!),
                ),
                _buildSliderSetting(
                  title: 'Max Storage Limit (MB)',
                  value: _settings!.maxStorageLimit,
                  min: 100.0,
                  max: 2000.0,
                  divisions: 19,
                  onChanged: (value) => _updateSetting(() => _settings!.maxStorageLimit = value),
                ),
                _TextFieldSetting(
                  title: 'Export Location',
                  initialValue: _settings!.exportLocation,
                  onChanged: (value) => _updateSetting(() => _settings!.exportLocation = value),
                ),
                _TextFieldSetting(
                  title: 'Document Naming Pattern',
                  initialValue: _settings!.documentNamePattern,
                  onChanged: (value) => _updateSetting(() => _settings!.documentNamePattern = value),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString().split('.').last),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildColorPickerSetting({
    required String title,
    required Color color,
    required ValueChanged<Color> onColorChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pick a color'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: color,
                  onColorChanged: onColorChanged,
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: value.toStringAsFixed(2),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TextFieldSetting extends StatefulWidget {
  final String title;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TextFieldSetting({
    required this.title,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_TextFieldSetting> createState() => _TextFieldSettingState();
}

class _TextFieldSettingState extends State<_TextFieldSetting> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: TextFormField(
        controller: _controller,
      ),
    );
  }
}
