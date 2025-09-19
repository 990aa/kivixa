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
  late Future<NotesSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _settingsService.loadSettings();
  }

  void _updateSetting(Function(NotesSettings) updater) {
    setState(() {
      _settingsFuture = _settingsFuture.then((settings) {
        updater(settings);
        _settingsService.saveSettings(settings);
        return settings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Settings'),
      ),
      body: FutureBuilder<NotesSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading settings'));
          }
          final settings = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle('Note Preferences'),
              _buildDropdownSetting<PaperType>(
                title: 'Default Paper Type',
                value: settings.defaultPaperType,
                items: PaperType.values,
                onChanged: (value) => _updateSetting((s) => s.copyWith(defaultPaperType: value)),
              ),
              _buildColorPickerSetting(
                title: 'Default Pen Color',
                color: settings.defaultPenColor,
                onColorChanged: (color) => _updateSetting((s) => s.copyWith(defaultPenColor: color)),
              ),
              _buildSliderSetting(
                title: 'Default Stroke Width',
                value: settings.defaultStrokeWidth,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                onChanged: (value) => _updateSetting((s) => s.copyWith(defaultStrokeWidth: value)),
              ),
              _buildDropdownSetting<AutoSaveFrequency>(
                title: 'Auto-save Frequency',
                value: settings.autoSaveFrequency,
                items: AutoSaveFrequency.values,
                onChanged: (value) => _updateSetting((s) => s.copyWith(autoSaveFrequency: value)),
              ),
              _buildDropdownSetting<PaperSize>(
                title: 'Paper Size',
                value: settings.paperSize,
                items: PaperSize.values,
                onChanged: (value) => _updateSetting((s) => s.copyWith(paperSize: value)),
              ),
              _buildDropdownSetting<ExportQuality>(
                title: 'Export Quality',
                value: settings.exportQuality,
                items: ExportQuality.values,
                onChanged: (value) => _updateSetting((s) => s.copyWith(exportQuality: value)),
              ),
              _buildSectionTitle('Drawing Preferences'),
              _buildSwitchSetting(
                title: 'Stylus-only Mode',
                value: settings.stylusOnlyMode,
                onChanged: (value) => _updateSetting((s) => s.copyWith(stylusOnlyMode: value)),
              ),
              _buildSliderSetting(
                title: 'Palm Rejection Sensitivity',
                value: settings.palmRejectionSensitivity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => _updateSetting((s) => s.copyWith(palmRejectionSensitivity: value)),
              ),
              _buildSliderSetting(
                title: 'Pressure Sensitivity',
                value: settings.pressureSensitivity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => _updateSetting((s) => s.copyWith(pressureSensitivity: value)),
              ),
              _buildSwitchSetting(
                title: 'Enable Zoom Gestures',
                value: settings.zoomGestureEnabled,
                onChanged: (value) => _updateSetting((s) => s.copyWith(zoomGestureEnabled: value)),
              ),
              _buildSectionTitle('Storage and Sync'),
              _buildDropdownSetting<AutoCleanup>(
                title: 'Auto-cleanup Old Documents',
                value: settings.autoCleanup,
                items: AutoCleanup.values,
                onChanged: (value) => _updateSetting((s) => s.copyWith(autoCleanup: value)),
              ),
              _buildSliderSetting(
                title: 'Max Storage Limit (MB)',
                value: settings.maxStorageLimit,
                min: 100.0,
                max: 2000.0,
                divisions: 19,
                onChanged: (value) => _updateSetting((s) => s.copyWith(maxStorageLimit: value)),
              ),
              _buildTextFieldSetting(
                title: 'Export Location',
                initialValue: settings.exportLocation,
                onChanged: (value) => _updateSetting((s) => s.copyWith(exportLocation: value)),
              ),
              _buildTextFieldSetting(
                title: 'Document Naming Pattern',
                initialValue: settings.documentNamePattern,
                onChanged: (value) => _updateSetting((s) => s.copyWith(documentNamePattern: value)),
              ),
            ],
          );
        },
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

  Widget _buildTextFieldSetting({
    required String title,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
      ),
    );
  }
}
