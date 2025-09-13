// GestureSettingsService: Saves gesture toggles and provides device capability report.
class GestureSettingsService {
  bool quickSwipeRight = true;
  bool doubleTapFit = true;
  bool twoFingerTapUndo = true;
  bool threeFingerTapRedo = true;

  // Save a gesture toggle
  void setGesture(String gesture, bool enabled) {
    switch (gesture) {
      case 'quickSwipeRight':
        quickSwipeRight = enabled;
        break;
      case 'doubleTapFit':
        doubleTapFit = enabled;
        break;
      case 'twoFingerTapUndo':
        twoFingerTapUndo = enabled;
        break;
      case 'threeFingerTapRedo':
        threeFingerTapRedo = enabled;
        break;
    }
  }

  // Get all gesture settings
  Map<String, bool> getGestureSettings() => {
    'quickSwipeRight': quickSwipeRight,
    'doubleTapFit': doubleTapFit,
    'twoFingerTapUndo': twoFingerTapUndo,
    'threeFingerTapRedo': threeFingerTapRedo,
  };

  // Device capability report (stubbed for now)
  Map<String, bool> getDeviceCapabilities() => {
    'supportsQuickSwipeRight': true,
    'supportsDoubleTapFit': true,
    'supportsTwoFingerTapUndo': true,
    'supportsThreeFingerTapRedo': true,
  };
}
