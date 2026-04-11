import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/settings/settings_color.dart';
import 'package:kivixa/components/settings/settings_dropdown.dart';
import 'package:kivixa/components/settings/settings_selection.dart';
import 'package:kivixa/components/settings/settings_switch.dart';
import 'package:kivixa/components/theming/adaptive_toggle_buttons.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const switchTitle = 'Stable Switch Title';
  const dropdownTitle = 'Stable Dropdown Title';
  const selectionTitle = 'Stable Selection Title';
  const colorTitle = 'Stable Color Title';

  late bool originalHubEnabled;
  late int originalHubSize;
  late int originalHubTransparency;
  late Color? originalAccentColor;

  Text _titleText(WidgetTester tester, String title) {
    return tester.widget<Text>(find.text(title).first);
  }

  void _expectNotItalic(Text text) {
    expect(text.style?.fontStyle, isNot(FontStyle.italic));
  }

  setUpAll(() {
    FlavorConfig.setup();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalHubEnabled = stows.floatingHubEnabled.value;
    originalHubSize = stows.floatingHubSize.value;
    originalHubTransparency = stows.floatingHubTransparency.value;
    originalAccentColor = stows.accentColor.value;
  });

  tearDown(() {
    stows.floatingHubEnabled.value = originalHubEnabled;
    stows.floatingHubSize.value = originalHubSize;
    stows.floatingHubTransparency.value = originalHubTransparency;
    stows.accentColor.value = originalAccentColor;
  });

  testWidgets('SettingsSwitch title remains non-italic when value changes', (
    tester,
  ) async {
    stows.floatingHubEnabled.value = stows.floatingHubEnabled.defaultValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsSwitch(title: switchTitle, pref: stows.floatingHubEnabled),
        ),
      ),
    );

    _expectNotItalic(_titleText(tester, switchTitle));

    stows.floatingHubEnabled.value = !stows.floatingHubEnabled.defaultValue;
    await tester.pumpAndSettle();

    _expectNotItalic(_titleText(tester, switchTitle));
  });

  testWidgets('SettingsDropdown title remains non-italic when value changes', (
    tester,
  ) async {
    const options = [
      ToggleButtonsOption<int>(0, Text('Small')),
      ToggleButtonsOption<int>(1, Text('Medium')),
      ToggleButtonsOption<int>(2, Text('Large')),
    ];

    stows.floatingHubSize.value = stows.floatingHubSize.defaultValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsDropdown<int>(
            title: dropdownTitle,
            pref: stows.floatingHubSize,
            options: options,
          ),
        ),
      ),
    );

    _expectNotItalic(_titleText(tester, dropdownTitle));

    stows.floatingHubSize.value = 0;
    await tester.pumpAndSettle();

    _expectNotItalic(_titleText(tester, dropdownTitle));
  });

  testWidgets('SettingsSelection title remains non-italic when value changes', (
    tester,
  ) async {
    const options = [
      ToggleButtonsOption<int>(0, Text('Low')),
      ToggleButtonsOption<int>(1, Text('Balanced')),
      ToggleButtonsOption<int>(2, Text('High')),
    ];

    stows.floatingHubTransparency.value =
        stows.floatingHubTransparency.defaultValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsSelection<int>(
            title: selectionTitle,
            pref: stows.floatingHubTransparency,
            options: options,
          ),
        ),
      ),
    );

    _expectNotItalic(_titleText(tester, selectionTitle));

    stows.floatingHubTransparency.value = 0;
    await tester.pumpAndSettle();

    _expectNotItalic(_titleText(tester, selectionTitle));
  });

  testWidgets('SettingsColor title remains non-italic when value changes', (
    tester,
  ) async {
    stows.accentColor.value = stows.accentColor.defaultValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsColor(title: colorTitle, pref: stows.accentColor),
        ),
      ),
    );

    _expectNotItalic(_titleText(tester, colorTitle));

    stows.accentColor.value = Colors.teal;
    await tester.pumpAndSettle();

    _expectNotItalic(_titleText(tester, colorTitle));
  });
}
