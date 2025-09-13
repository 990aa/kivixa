import 'package:flutter/foundation.dart';

enum ToolbarMode { immersive, traditional }
enum InputBehavior { finger, pen }

class ToolbarSettings extends ChangeNotifier {
  static final ToolbarSettings _instance = ToolbarSettings._internal();
  factory ToolbarSettings() => _instance;
  ToolbarSettings._internal();

  // In-memory view for fast UI feedback
  ToolbarMode _toolbarMode = ToolbarMode.traditional;
  InputBehavior _inputBehavior = InputBehavior.pen;

  ToolbarMode get toolbarMode => _toolbarMode;
  InputBehavior get inputBehavior => _inputBehavior;

  Future<void> loadSettings() async {
    // In a real app, this would load from a persistent store like SharedPreferences
    // For now, we just use the default values.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async loading
    notifyListeners();
  }

  Future<void> setToolbarMode(ToolbarMode mode) async {
    if (_toolbarMode == mode) return;
    _toolbarMode = mode;
    // The UI update is synchronous
    notifyListeners();
    // The persistence is asynchronous
    await _persistSettings();
  }

  Future<void> setInputBehavior(InputBehavior behavior) async {
    if (_inputBehavior == behavior) return;
    _inputBehavior = behavior;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> _persistSettings() async {
    // In a real app, this would save to SharedPreferences or a database.
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate async save
    print('Toolbar settings persisted: mode=${_toolbarMode.name}, behavior=${_inputBehavior.name}');
  }
}
