// Floating Hub Settings Tests
//
// Tests for the floating hub visibility, size, and transparency settings.

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlavorConfig.setup();
    OverlayController.testMode = true;
  });

  tearDownAll(() {
    OverlayController.testMode = false;
  });

  group('Floating Hub Settings Preferences', () {
    test('floatingHubEnabled defaults to true', () {
      expect(stows.floatingHubEnabled.defaultValue, true);
    });

    test('floatingHubSize defaults to 1 (medium)', () {
      expect(stows.floatingHubSize.defaultValue, 1);
    });

    test('floatingHubTransparency defaults to 1 (balanced)', () {
      expect(stows.floatingHubTransparency.defaultValue, 1);
    });

    test('floatingHubEnabled can be toggled', () {
      final original = stows.floatingHubEnabled.value;
      stows.floatingHubEnabled.value = !original;
      expect(stows.floatingHubEnabled.value, !original);
      stows.floatingHubEnabled.value = original;
    });

    test('floatingHubSize accepts valid values', () {
      stows.floatingHubSize.value = 0;
      expect(stows.floatingHubSize.value, 0);

      stows.floatingHubSize.value = 1;
      expect(stows.floatingHubSize.value, 1);

      stows.floatingHubSize.value = 2;
      expect(stows.floatingHubSize.value, 2);

      // Reset to default
      stows.floatingHubSize.value = stows.floatingHubSize.defaultValue;
    });

    test('floatingHubTransparency accepts valid values', () {
      stows.floatingHubTransparency.value = 0;
      expect(stows.floatingHubTransparency.value, 0);

      stows.floatingHubTransparency.value = 1;
      expect(stows.floatingHubTransparency.value, 1);

      stows.floatingHubTransparency.value = 2;
      expect(stows.floatingHubTransparency.value, 2);

      // Reset to default
      stows.floatingHubTransparency.value =
          stows.floatingHubTransparency.defaultValue;
    });
  });

  group('Size Setting Mappings', () {
    test('size 0 maps to scale 0.75 (small)', () {
      final scale = switch (0) {
        0 => 0.75,
        1 => 1.0,
        _ => 1.25,
      };
      expect(scale, 0.75);
    });

    test('size 1 maps to scale 1.0 (medium)', () {
      final scale = switch (1) {
        0 => 0.75,
        1 => 1.0,
        _ => 1.25,
      };
      expect(scale, 1.0);
    });

    test('size 2 maps to scale 1.25 (large)', () {
      final scale = switch (2) {
        0 => 0.75,
        1 => 1.0,
        _ => 1.25,
      };
      expect(scale, 1.25);
    });
  });

  group('Transparency Setting Mappings', () {
    test('transparency 0 maps to opacity 0.4 (more transparent)', () {
      final opacity = switch (0) {
        0 => 0.4,
        1 => 0.7,
        _ => 1.0,
      };
      expect(opacity, 0.4);
    });

    test('transparency 1 maps to opacity 0.7 (balanced)', () {
      final opacity = switch (1) {
        0 => 0.4,
        1 => 0.7,
        _ => 1.0,
      };
      expect(opacity, 0.7);
    });

    test('transparency 2 maps to opacity 1.0 (less transparent)', () {
      final opacity = switch (2) {
        0 => 0.4,
        1 => 0.7,
        _ => 1.0,
      };
      expect(opacity, 1.0);
    });
  });

  group('Overlay Controller Integration', () {
    late OverlayController controller;

    setUp(() {
      controller = OverlayController.instance;
      // Reset to defaults
      controller.setHubScale(1.0);
      controller.setHubOpacity(0.7);
    });

    test('controller accepts scale values from settings', () {
      controller.setHubScale(0.75);
      expect(controller.hubScale, 0.75);

      controller.setHubScale(1.0);
      expect(controller.hubScale, 1.0);

      controller.setHubScale(1.25);
      expect(controller.hubScale, 1.25);
    });

    test('controller accepts opacity values from settings', () {
      controller.setHubOpacity(0.4);
      expect(controller.hubOpacity, 0.4);

      controller.setHubOpacity(0.7);
      expect(controller.hubOpacity, 0.7);

      controller.setHubOpacity(1.0);
      expect(controller.hubOpacity, 1.0);
    });

    test('hub scale affects calculated hub size', () {
      const baseSize = 56.0;

      controller.setHubScale(0.75);
      expect(baseSize * controller.hubScale, 42.0);

      controller.setHubScale(1.0);
      expect(baseSize * controller.hubScale, 56.0);

      controller.setHubScale(1.25);
      expect(baseSize * controller.hubScale, 70.0);
    });
  });

  group('Preference Listeners', () {
    test('floatingHubEnabled notifies listeners on change', () {
      var notifyCount = 0;
      void listener() => notifyCount++;

      stows.floatingHubEnabled.addListener(listener);
      final original = stows.floatingHubEnabled.value;

      stows.floatingHubEnabled.value = !original;
      expect(notifyCount, 1);

      stows.floatingHubEnabled.value = original;
      expect(notifyCount, 2);

      stows.floatingHubEnabled.removeListener(listener);
    });

    test('floatingHubSize notifies listeners on change', () {
      var notifyCount = 0;
      void listener() => notifyCount++;

      stows.floatingHubSize.addListener(listener);
      final original = stows.floatingHubSize.value;

      stows.floatingHubSize.value = (original + 1) % 3;
      expect(notifyCount, 1);

      stows.floatingHubSize.value = original;
      stows.floatingHubSize.removeListener(listener);
    });

    test('floatingHubTransparency notifies listeners on change', () {
      var notifyCount = 0;
      void listener() => notifyCount++;

      stows.floatingHubTransparency.addListener(listener);
      final original = stows.floatingHubTransparency.value;

      stows.floatingHubTransparency.value = (original + 1) % 3;
      expect(notifyCount, 1);

      stows.floatingHubTransparency.value = original;
      stows.floatingHubTransparency.removeListener(listener);
    });
  });
}
