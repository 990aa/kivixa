import 'package:kivixa/services/settings_service.dart';

enum FeatureFlag {
  experimentalInfiniteCanvasCache,
  anotherExperimentalFeature,
}

class LocalFeatureFlags {
  final SettingsService _settingsService;
  static const String _prefix = 'feature_flag_';

  LocalFeatureFlags(this._settingsService);

  String _key(FeatureFlag flag) => '$_prefix${flag.name}';

  Future<bool> isEnabled(FeatureFlag flag) async {
    return await _settingsService.get<bool>(_key(flag), defaultValue: false) ?? false;
  }

  void set(FeatureFlag flag, bool isEnabled) {
    _settingsService.set<bool>(_key(flag), isEnabled);
  }
}
