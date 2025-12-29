import 'dart:io';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/dialogs/legal_documents_viewer.dart';
import 'package:kivixa/components/navbar/responsive_navbar.dart';
import 'package:kivixa/components/settings/clear_app_data_widget.dart';
import 'package:kivixa/components/settings/notification_settings_widget.dart';
import 'package:kivixa/components/settings/release_notes_dialog.dart';
import 'package:kivixa/components/settings/settings_button.dart';
import 'package:kivixa/components/settings/settings_color.dart';
import 'package:kivixa/components/settings/settings_directory_selector.dart';
import 'package:kivixa/components/settings/settings_selection.dart';
import 'package:kivixa/components/settings/settings_subtitle.dart';
import 'package:kivixa/components/settings/settings_switch.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/adaptive_alert_dialog.dart';
import 'package:kivixa/components/theming/adaptive_toggle_buttons.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/data/tools/shape_pen.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/lock_screen.dart';
import 'package:kivixa/services/app_lock_service.dart';
import 'package:kivixa/services/browser_service.dart';
import 'package:kivixa/services/life_git/life_git_service.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:kivixa/services/quick_notes/quick_notes_service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:stow/stow.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool?> showResetDialog({
    required BuildContext context,
    required Stow pref,
    required String prefTitle,
  }) async {
    if (pref.value == pref.defaultValue) return null;
    return await showDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.settings.reset.title),
        content: Text(prefTitle),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              pref.value = pref.defaultValue;
              Navigator.of(context).pop(true);
            },
            child: Text(t.settings.reset.button),
          ),
        ],
      ),
    );
  }
}

abstract class _SettingsStows {
  static final appTheme = TransformedStow(
    stows.appTheme,
    (ThemeMode value) => value.index,
    (int value) => ThemeMode.values[value],
  );

  static final platform = TransformedStow(
    stows.platform,
    (TargetPlatform value) => value.index,
    (int value) => TargetPlatform.values[value],
  );

  static final layoutSize = TransformedStow(
    stows.layoutSize,
    (LayoutSize value) => value.index,
    (int value) => LayoutSize.values[value],
  );

  static final editorToolbarAlignment = TransformedStow(
    stows.editorToolbarAlignment,
    (AxisDirection value) => value.index,
    (int value) => AxisDirection.values[value],
  );

  // Pencil sound removed
  // static final pencilSound = TransformedStow(
  //   stows.pencilSound,
  //   (PencilSoundSetting value) => value.index,
  //   (int value) => PencilSoundSetting.values[value],
  // );
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    UpdateManager.status.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  static const materialDirectionIcons = [
    Icons.north,
    Icons.east,
    Icons.south,
    Icons.west,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final requiresManualUpdates = FlavorConfig.appStore.isEmpty;

    final IconData materialIcon = switch (defaultTargetPlatform) {
      TargetPlatform.windows => FontAwesomeIcons.windows,
      _ => Icons.android,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverAppBar(
              collapsedHeight: kToolbarHeight,
              expandedHeight: 100,
              pinned: true,
              scrolledUnderElevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  t.home.titles.settings,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 16,
                ),
              ),
              actions: [
                if (UpdateManager.status.value != UpdateStatus.upToDate)
                  IconButton(
                    tooltip: t.home.tooltips.showUpdateDialog,
                    icon: const Icon(Icons.system_update),
                    onPressed: () {
                      UpdateManager.showUpdateDialog(
                        context,
                        userTriggered: true,
                      );
                    },
                  ),
              ],
            ),
          ),
          SliverSafeArea(
            sliver: SliverList.list(
              children: [
                // Legal documents section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              LegalDocumentsViewer.showTerms(context),
                          icon: const Icon(Icons.gavel, size: 18),
                          label: const Text('Terms & Conditions'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              LegalDocumentsViewer.showPrivacyPolicy(context),
                          icon: const Icon(
                            Icons.privacy_tip_outlined,
                            size: 18,
                          ),
                          label: const Text('Privacy Policy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => const UpdatesDialog(),
                          ),
                          icon: const Icon(
                            Icons.system_update_outlined,
                            size: 18,
                          ),
                          label: const Text('Updates'),
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsSubtitle(subtitle: t.settings.prefCategories.general),
                SettingsSelection(
                  title: t.settings.prefLabels.appTheme,
                  iconBuilder: (i) {
                    if (i == ThemeMode.system.index)
                      return Icons.brightness_auto;
                    if (i == ThemeMode.light.index) return Icons.light_mode;
                    if (i == ThemeMode.dark.index) return Icons.dark_mode;
                    return null;
                  },
                  pref: _SettingsStows.appTheme,
                  optionsWidth: 60,
                  options: [
                    ToggleButtonsOption(
                      ThemeMode.system.index,
                      Icon(
                        Icons.brightness_auto,
                        semanticLabel: t.settings.themeModes.system,
                      ),
                    ),
                    ToggleButtonsOption(
                      ThemeMode.light.index,
                      Icon(
                        Icons.light_mode,
                        semanticLabel: t.settings.themeModes.light,
                      ),
                    ),
                    ToggleButtonsOption(
                      ThemeMode.dark.index,
                      Icon(
                        Icons.dark_mode,
                        semanticLabel: t.settings.themeModes.dark,
                      ),
                    ),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.platform,
                  iconBuilder: (i) => materialIcon,
                  pref: _SettingsStows.platform,
                  optionsWidth: 60,
                  options: [
                    ToggleButtonsOption(
                      TargetPlatform.android.index,
                      const Icon(Icons.android, semanticLabel: 'Android'),
                    ),
                    ToggleButtonsOption(
                      TargetPlatform.windows.index,
                      const Icon(
                        FontAwesomeIcons.windows,
                        semanticLabel: 'Windows',
                      ),
                    ),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.layoutSize,
                  subtitle: switch (stows.layoutSize.value) {
                    LayoutSize.auto => t.settings.layoutSizes.auto,
                    LayoutSize.phone => t.settings.layoutSizes.phone,
                    LayoutSize.tablet => t.settings.layoutSizes.tablet,
                  },
                  afterChange: (_) => setState(() {}),
                  iconBuilder: (i) => switch (LayoutSize.values[i]) {
                    LayoutSize.auto => Icons.aspect_ratio,
                    LayoutSize.phone => Icons.smartphone,
                    LayoutSize.tablet => Icons.tablet,
                  },
                  pref: _SettingsStows.layoutSize,
                  optionsWidth: 60,
                  options: [
                    ToggleButtonsOption(
                      LayoutSize.auto.index,
                      Icon(
                        Icons.aspect_ratio,
                        semanticLabel: t.settings.layoutSizes.auto,
                      ),
                    ),
                    ToggleButtonsOption(
                      LayoutSize.phone.index,
                      Icon(
                        Icons.smartphone,
                        semanticLabel: t.settings.layoutSizes.phone,
                      ),
                    ),
                    ToggleButtonsOption(
                      LayoutSize.tablet.index,
                      Icon(
                        Icons.tablet,
                        semanticLabel: t.settings.layoutSizes.tablet,
                      ),
                    ),
                  ],
                ),
                SettingsColor(
                  title: t.settings.prefLabels.customAccentColor,
                  icon: Icons.colorize,
                  pref: stows.accentColor,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.hyperlegibleFont,
                  subtitle: t.settings.prefDescriptions.hyperlegibleFont,
                  iconBuilder: (b) {
                    if (b) return Icons.font_download;
                    return Icons.font_download_off;
                  },
                  pref: stows.hyperlegibleFont,
                ),
                SettingsSubtitle(subtitle: t.settings.prefCategories.writing),
                SettingsSwitch(
                  title: t.settings.prefLabels.preferGreyscale,
                  subtitle: t.settings.prefDescriptions.preferGreyscale,
                  iconBuilder: (b) {
                    return b
                        ? Icons.monochrome_photos
                        : Icons.enhance_photo_translate;
                  },
                  pref: stows.preferGreyscale,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.autoClearWhiteboardOnExit,
                  subtitle:
                      t.settings.prefDescriptions.autoClearWhiteboardOnExit,
                  icon: Icons.cleaning_services,
                  pref: stows.autoClearWhiteboardOnExit,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.disableEraserAfterUse,
                  subtitle: t.settings.prefDescriptions.disableEraserAfterUse,
                  icon: FontAwesomeIcons.eraser,
                  pref: stows.disableEraserAfterUse,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.hideFingerDrawingToggle,
                  subtitle: () {
                    if (!stows.hideFingerDrawingToggle.value) {
                      return t
                          .settings
                          .prefDescriptions
                          .hideFingerDrawing
                          .shown;
                    } else if (stows.editorFingerDrawing.value) {
                      return t
                          .settings
                          .prefDescriptions
                          .hideFingerDrawing
                          .fixedOn;
                    } else {
                      return t
                          .settings
                          .prefDescriptions
                          .hideFingerDrawing
                          .fixedOff;
                    }
                  }(),
                  icon: CupertinoIcons.hand_draw,
                  pref: stows.hideFingerDrawingToggle,
                  afterChange: (_) => setState(() {}),
                ),
                const NotificationSettingsWidget(),
                SettingsSubtitle(subtitle: t.settings.prefCategories.editor),
                SettingsSelection(
                  title: t.settings.prefLabels.editorToolbarAlignment,
                  subtitle:
                      t.settings.axisDirections[_SettingsStows
                          .editorToolbarAlignment
                          .value],
                  iconBuilder: (num i) {
                    if (i is! int || i >= materialDirectionIcons.length)
                      return null;
                    return materialDirectionIcons[i];
                  },
                  pref: _SettingsStows.editorToolbarAlignment,
                  optionsWidth: 60,
                  options: [
                    for (final AxisDirection direction in AxisDirection.values)
                      ToggleButtonsOption(
                        direction.index,
                        Icon(
                          materialDirectionIcons[direction.index],
                          semanticLabel:
                              t.settings.axisDirections[direction.index],
                        ),
                      ),
                  ],
                  afterChange: (_) => setState(() {}),
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.editorToolbarShowInFullscreen,
                  icon: Icons.fullscreen,
                  pref: stows.editorToolbarShowInFullscreen,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.editorAutoInvert,
                  iconBuilder: (b) {
                    return b ? Icons.invert_colors_on : Icons.invert_colors_off;
                  },
                  pref: stows.editorAutoInvert,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.editorPromptRename,
                  subtitle: t.settings.prefDescriptions.editorPromptRename,
                  iconBuilder: (b) {
                    if (b) return Icons.keyboard;
                    return Icons.keyboard_hide;
                  },
                  pref: stows.editorPromptRename,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.recentColorsDontSavePresets,
                  icon: Icons.palette,
                  pref: stows.recentColorsDontSavePresets,
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.recentColorsLength,
                  icon: Icons.history,
                  pref: stows.recentColorsLength,
                  options: const [
                    ToggleButtonsOption(5, Text('5')),
                    ToggleButtonsOption(10, Text('10')),
                  ],
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.printPageIndicators,
                  subtitle: t.settings.prefDescriptions.printPageIndicators,
                  icon: Icons.numbers,
                  pref: stows.printPageIndicators,
                ),
                // Pencil sound removed
                // SettingsSelection(
                //   title: t.settings.prefLabels.pencilSoundSetting,
                //   subtitle: stows.pencilSound.value.description,
                //   icon: stows.pencilSound.value.icon,
                //   pref: _SettingsStows.pencilSound,
                //   optionsWidth: 60,
                //   options: [
                //     for (final setting in PencilSoundSetting.values)
                //       ToggleButtonsOption(
                //         setting.index,
                //         Icon(setting.icon, semanticLabel: setting.description),
                //       ),
                //   ],
                //   afterChange: (_) {
                //     PencilSound.setAudioContext();
                //     setState(() {});
                //   },
                // ),
                SettingsSubtitle(
                  subtitle: t.settings.prefCategories.performance,
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.maxImageSize,
                  subtitle: t.settings.prefDescriptions.maxImageSize,
                  icon: Icons.photo_size_select_large,
                  pref: stows.maxImageSize,
                  options: const <ToggleButtonsOption<double>>[
                    ToggleButtonsOption(500, Text('500')),
                    ToggleButtonsOption(1000, Text('1000')),
                    ToggleButtonsOption(2000, Text('2000')),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.autosave,
                  subtitle: t.settings.prefDescriptions.autosave,
                  icon: Icons.save,
                  pref: stows.autosaveDelay,
                  options: [
                    const ToggleButtonsOption(5000, Text('5s')),
                    const ToggleButtonsOption(10000, Text('10s')),
                    ToggleButtonsOption(-1, Text(t.settings.autosaveDisabled)),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.shapeRecognitionDelay,
                  subtitle: t.settings.prefDescriptions.shapeRecognitionDelay,
                  icon: FontAwesomeIcons.shapes,
                  pref: stows.shapeRecognitionDelay,
                  options: [
                    const ToggleButtonsOption(500, Text('0.5s')),
                    const ToggleButtonsOption(1000, Text('1s')),
                    ToggleButtonsOption(
                      -1,
                      Text(t.settings.shapeRecognitionDisabled),
                    ),
                  ],
                  afterChange: (ms) {
                    ShapePen.debounceDuration = ShapePen.getDebounceFromPref();
                  },
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.autoStraightenLines,
                  subtitle: t.settings.prefDescriptions.autoStraightenLines,
                  icon: Icons.straighten,
                  pref: stows.autoStraightenLines,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.simplifiedHomeLayout,
                  subtitle: t.settings.prefDescriptions.simplifiedHomeLayout,
                  iconBuilder: (simplified) =>
                      simplified ? Icons.grid_view : Symbols.browse,
                  pref: stows.simplifiedHomeLayout,
                ),
                const SettingsSubtitle(subtitle: 'Floating Hub'),
                SettingsSwitch(
                  title: 'Enable Floating Hub',
                  subtitle: 'Show floating menu for quick access to tools',
                  icon: Icons.blur_circular,
                  pref: stows.floatingHubEnabled,
                ),
                SettingsSelection(
                  title: 'Hub Size',
                  subtitle: switch (stows.floatingHubSize.value) {
                    0 => 'Small',
                    1 => 'Medium',
                    _ => 'Large',
                  },
                  icon: Icons.format_size,
                  pref: stows.floatingHubSize,
                  afterChange: (_) => setState(() {}),
                  options: const [
                    ToggleButtonsOption(0, Text('S')),
                    ToggleButtonsOption(1, Text('M')),
                    ToggleButtonsOption(2, Text('L')),
                  ],
                ),
                SettingsSelection(
                  title: 'Hub Transparency',
                  subtitle: switch (stows.floatingHubTransparency.value) {
                    0 => 'More transparent',
                    1 => 'Balanced',
                    _ => 'Less transparent',
                  },
                  icon: Icons.opacity,
                  pref: stows.floatingHubTransparency,
                  afterChange: (_) => setState(() {}),
                  options: const [
                    ToggleButtonsOption(0, Icon(Icons.lens_blur)),
                    ToggleButtonsOption(1, Icon(Icons.blur_on)),
                    ToggleButtonsOption(2, Icon(Icons.blur_off)),
                  ],
                ),
                const SettingsSubtitle(subtitle: 'Productivity Timer'),
                const _ProductivityTimerSettingsSection(),
                const SettingsSubtitle(subtitle: 'Quick Notes'),
                const _QuickNotesSettingsSection(),
                SettingsSubtitle(subtitle: t.settings.prefCategories.security),
                _AppLockSettingsSection(onChanged: () => setState(() {})),
                SettingsSubtitle(subtitle: t.settings.prefCategories.advanced),
                if (Platform.isAndroid)
                  SettingsDirectorySelector(
                    title: t.settings.prefLabels.customDataDir,
                    icon: Icons.folder,
                  ),
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                  SettingsButton(
                    title: t.settings.openDataDir,
                    icon: Icons.folder_open,
                    onPressed: () {
                      if (Platform.isWindows) {
                        Process.run('explorer', [
                          FileManager.documentsDirectory,
                        ]);
                      } else if (Platform.isLinux) {
                        Process.run('xdg-open', [
                          FileManager.documentsDirectory,
                        ]);
                      } else if (Platform.isMacOS) {
                        Process.run('open', [FileManager.documentsDirectory]);
                      }
                    },
                  ),
                if (requiresManualUpdates ||
                    stows.shouldCheckForUpdates.value !=
                        stows.shouldCheckForUpdates.defaultValue) ...[
                  SettingsSwitch(
                    title: t.settings.prefLabels.shouldCheckForUpdates,
                    icon: Icons.system_update,
                    pref: stows.shouldCheckForUpdates,
                    afterChange: (_) => setState(() {}),
                  ),
                  Collapsible(
                    collapsed: !stows.shouldCheckForUpdates.value,
                    axis: CollapsibleAxis.vertical,
                    child: SettingsSwitch(
                      title: t.settings.prefLabels.shouldAlwaysAlertForUpdates,
                      subtitle: t
                          .settings
                          .prefDescriptions
                          .shouldAlwaysAlertForUpdates,
                      icon: Icons.system_security_update_warning,
                      pref: stows.shouldAlwaysAlertForUpdates,
                    ),
                  ),
                ],
                SettingsButton(
                  title: t.logs.viewLogs,
                  subtitle: t.logs.debuggingInfo,
                  icon: Icons.receipt_long,
                  onPressed: () => context.push(RoutePaths.logs),
                ),
                const SettingsSubtitle(subtitle: 'Extensions'),
                SettingsButton(
                  title: 'Lua Plugins',
                  subtitle: 'Automate tasks with Lua scripts',
                  icon: Icons.extension,
                  onPressed: () => context.push(RoutePaths.plugins),
                ),
                SettingsButton(
                  title: 'Version History',
                  subtitle: 'View file snapshots and commits',
                  icon: Icons.history,
                  onPressed: () => context.push(RoutePaths.lifeGitHistory),
                ),
                const _LifeGitAutoCleanupSetting(),
                _LifeGitStatsWidget(),
                const SettingsSubtitle(subtitle: 'Browser'),
                const _BrowserSettingsSection(),
                const SettingsSubtitle(subtitle: 'Data Management'),
                const _DeleteDataOnUninstallWidget(),
                const ClearAppDataWidget(),
                const _ResetAllSettingsWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    UpdateManager.status.removeListener(onChanged);
    super.dispose();
  }
}

/// Settings section for app lock functionality
class _AppLockSettingsSection extends StatefulWidget {
  const _AppLockSettingsSection({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_AppLockSettingsSection> createState() =>
      _AppLockSettingsSectionState();
}

class _AppLockSettingsSectionState extends State<_AppLockSettingsSection> {
  final _appLockService = AppLockService();

  Future<void> _setupPin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinSetupDialog(),
    );

    if (result ?? false) {
      setState(() {});
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App lock enabled')));
      }
    }
  }

  Future<void> _changePin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinSetupDialog(isChanging: true),
    );

    if ((result ?? false) && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
    }
  }

  Future<void> _removePin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RemovePinDialog(),
    );

    if (result ?? false) {
      setState(() {});
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App lock disabled')));
      }
    }
  }

  void _toggleAppLock(bool value) {
    if (value && !_appLockService.isPinSet) {
      _setupPin();
    } else {
      if (value) {
        _appLockService.enable();
      } else {
        _appLockService.disable();
      }
      setState(() {});
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _appLockService.isEnabled;
    final isPinSet = _appLockService.isPinSet;

    return Column(
      children: [
        // Main app lock toggle
        SettingsSwitch(
          title: t.settings.prefLabels.appLock,
          subtitle: t.settings.prefDescriptions.appLock,
          iconBuilder: (enabled) => enabled ? Icons.lock : Icons.lock_open,
          pref: stows.appLockEnabled,
          afterChange: _toggleAppLock,
        ),

        // Additional options when PIN is set
        if (isPinSet) ...[
          Collapsible(
            collapsed: !isEnabled,
            axis: CollapsibleAxis.vertical,
            child: Column(
              children: [
                SettingsButton(
                  title: t.settings.prefLabels.changePin,
                  subtitle: t.settings.prefDescriptions.changePin,
                  icon: Icons.pin,
                  onPressed: _changePin,
                ),
                SettingsButton(
                  title: t.settings.prefLabels.removeAppLock,
                  subtitle: t.settings.prefDescriptions.removeAppLock,
                  icon: Icons.no_encryption,
                  onPressed: _removePin,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Settings widget for Life Git auto-cleanup
class _LifeGitAutoCleanupSetting extends StatefulWidget {
  const _LifeGitAutoCleanupSetting();

  @override
  State<_LifeGitAutoCleanupSetting> createState() =>
      _LifeGitAutoCleanupSettingState();
}

class _LifeGitAutoCleanupSettingState
    extends State<_LifeGitAutoCleanupSetting> {
  @override
  void initState() {
    super.initState();
    stows.lifeGitAutoCleanupDays.addListener(_onChanged);
  }

  @override
  void dispose() {
    stows.lifeGitAutoCleanupDays.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  String _getSubtitle() {
    final days = stows.lifeGitAutoCleanupDays.value;
    if (days <= 0) return 'Never';
    return 'Delete commits older than $days days';
  }

  @override
  Widget build(BuildContext context) {
    return SettingsButton(
      title: 'Auto-cleanup old history',
      subtitle: _getSubtitle(),
      icon: Icons.auto_delete_outlined,
      onPressed: () => _showAutoCleanupDialog(context),
    );
  }

  Future<void> _showAutoCleanupDialog(BuildContext context) async {
    final options = [
      (value: 0, label: 'Never (keep all history)'),
      (value: 7, label: 'After 7 days'),
      (value: 14, label: 'After 14 days'),
      (value: 30, label: 'After 30 days'),
      (value: 60, label: 'After 60 days'),
      (value: 90, label: 'After 90 days'),
    ];

    var currentValue = stows.lifeGitAutoCleanupDays.value;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Auto-cleanup Settings'),
          content: RadioGroup<int>(
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => currentValue = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Automatically delete old version history to save storage space.',
                ),
                const SizedBox(height: 16),
                ...options.map(
                  (option) => RadioListTile<int>(
                    title: Text(option.label),
                    value: option.value,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                stows.lifeGitAutoCleanupDays.value = currentValue;
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget showing Life Git storage statistics
class _LifeGitStatsWidget extends StatefulWidget {
  @override
  State<_LifeGitStatsWidget> createState() => _LifeGitStatsWidgetState();
}

class _LifeGitStatsWidgetState extends State<_LifeGitStatsWidget> {
  Map<String, dynamic>? _stats;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await LifeGitService.instance.getStorageStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stats == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = ColorScheme.of(context);
    final commitCount = _stats!['commitCount'] as int? ?? 0;
    final objectCount = _stats!['objectCount'] as int? ?? 0;
    final objectsSize = _stats!['objectsSize'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Life Git Storage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Commits',
                    value: commitCount.toString(),
                    icon: Icons.commit,
                  ),
                  _StatItem(
                    label: 'Snapshots',
                    value: objectCount.toString(),
                    icon: Icons.photo_library,
                  ),
                  _StatItem(
                    label: 'Size',
                    value: _formatBytes(objectsSize),
                    icon: Icons.data_usage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Widget to reset all settings to their default values
class _ResetAllSettingsWidget extends StatelessWidget {
  const _ResetAllSettingsWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ListTile(
          leading: Icon(
            Icons.settings_backup_restore,
            color: colorScheme.error,
          ),
          title: const Text('Reset All Settings'),
          subtitle: const Text('Restore all settings to default values'),
          trailing: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showResetConfirmation(context),
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final colorScheme = ColorScheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text(
          'This will restore all settings to their default values. '
          'This action cannot be undone.\n\n'
          'Note: This will not delete your files or app data, only preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      _resetAllSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings have been reset to defaults'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetAllSettings() {
    // Reset all user-facing preferences to their defaults
    stows.appTheme.value = stows.appTheme.defaultValue;
    stows.platform.value = stows.platform.defaultValue;
    stows.layoutSize.value = stows.layoutSize.defaultValue;
    stows.accentColor.value = stows.accentColor.defaultValue;
    stows.hyperlegibleFont.value = stows.hyperlegibleFont.defaultValue;
    stows.editorToolbarAlignment.value =
        stows.editorToolbarAlignment.defaultValue;
    stows.editorToolbarShowInFullscreen.value =
        stows.editorToolbarShowInFullscreen.defaultValue;
    stows.editorFingerDrawing.value = stows.editorFingerDrawing.defaultValue;
    stows.editorAutoInvert.value = stows.editorAutoInvert.defaultValue;
    stows.preferGreyscale.value = stows.preferGreyscale.defaultValue;
    stows.editorPromptRename.value = stows.editorPromptRename.defaultValue;
    stows.autosaveDelay.value = stows.autosaveDelay.defaultValue;
    stows.shapeRecognitionDelay.value =
        stows.shapeRecognitionDelay.defaultValue;
    stows.autoStraightenLines.value = stows.autoStraightenLines.defaultValue;
    stows.simplifiedHomeLayout.value = stows.simplifiedHomeLayout.defaultValue;
    stows.printPageIndicators.value = stows.printPageIndicators.defaultValue;
    stows.maxImageSize.value = stows.maxImageSize.defaultValue;
    stows.autoClearWhiteboardOnExit.value =
        stows.autoClearWhiteboardOnExit.defaultValue;
    stows.disableEraserAfterUse.value =
        stows.disableEraserAfterUse.defaultValue;
    stows.hideFingerDrawingToggle.value =
        stows.hideFingerDrawingToggle.defaultValue;
    stows.recentColorsLength.value = stows.recentColorsLength.defaultValue;
    stows.recentColorsDontSavePresets.value =
        stows.recentColorsDontSavePresets.defaultValue;
    stows.shouldCheckForUpdates.value =
        stows.shouldCheckForUpdates.defaultValue;
    stows.shouldAlwaysAlertForUpdates.value =
        stows.shouldAlwaysAlertForUpdates.defaultValue;
    stows.lifeGitAutoCleanupDays.value =
        stows.lifeGitAutoCleanupDays.defaultValue;
    stows.deleteDataOnUninstall.value =
        stows.deleteDataOnUninstall.defaultValue;
    stows.browserBackgroundAudio.value =
        stows.browserBackgroundAudio.defaultValue;

    // Note: We intentionally do NOT reset:
    // - appLockEnabled/appLockPinSet (security settings)
    // - customDataDir (data location)
    // - recentFiles (user data)
    // - Tool colors/options (user preferences that are editor-specific)
  }
}

/// Widget to control whether app data is deleted on uninstall
class _DeleteDataOnUninstallWidget extends StatefulWidget {
  const _DeleteDataOnUninstallWidget();

  @override
  State<_DeleteDataOnUninstallWidget> createState() =>
      _DeleteDataOnUninstallWidgetState();
}

class _DeleteDataOnUninstallWidgetState
    extends State<_DeleteDataOnUninstallWidget> {
  @override
  void initState() {
    super.initState();
    stows.deleteDataOnUninstall.addListener(_onChanged);
  }

  @override
  void dispose() {
    stows.deleteDataOnUninstall.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleSetting() async {
    final currentValue = stows.deleteDataOnUninstall.value;

    if (!currentValue) {
      // User is trying to enable deletion - show warning
      final confirmed = await _showWarningDialog();
      if (confirmed ?? false) {
        stows.deleteDataOnUninstall.value = true;
      }
    } else {
      // User is disabling - no warning needed
      stows.deleteDataOnUninstall.value = false;
    }
  }

  Future<bool?> _showWarningDialog() async {
    final colorScheme = ColorScheme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: colorScheme.error,
          size: 48,
        ),
        title: const Text('Delete All Data on Uninstall?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARNING: If you enable this option, ALL your data will be '
              'permanently deleted when you uninstall the app. This includes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• All your notes and documents'),
            Text('• All canvas drawings'),
            Text('• Version history'),
            Text('• Plugins and scripts'),
            Text('• All app settings'),
            SizedBox(height: 16),
            Text(
              'It is strongly recommended that you backup your important '
              'files before enabling this option.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone after uninstall.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('I Understand, Enable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isEnabled = stows.deleteDataOnUninstall.value;

    // Only show on Android where this setting is relevant
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: isEnabled ? colorScheme.errorContainer : null,
        child: ListTile(
          leading: Icon(
            isEnabled ? Icons.delete_forever : Icons.folder_off,
            color: isEnabled ? colorScheme.error : colorScheme.primary,
          ),
          title: const Text('Delete Data on Uninstall'),
          subtitle: Text(
            isEnabled
                ? 'All data will be deleted when app is uninstalled'
                : 'Data will be kept when app is uninstalled (recommended)',
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (_) => _toggleSetting(),
            activeTrackColor: colorScheme.error,
          ),
          onTap: _toggleSetting,
        ),
      ),
    );
  }
}

/// Browser settings section
class _BrowserSettingsSection extends StatefulWidget {
  const _BrowserSettingsSection();

  @override
  State<_BrowserSettingsSection> createState() =>
      _BrowserSettingsSectionState();
}

class _BrowserSettingsSectionState extends State<_BrowserSettingsSection> {
  final _browserService = BrowserService.instance;

  @override
  void initState() {
    super.initState();
    _browserService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _browserService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear your browsing history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _browserService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Browsing history cleared')),
        );
      }
    }
  }

  Future<void> _clearBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Bookmarks'),
        content: const Text('Are you sure you want to delete all bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _browserService.clearBookmarks();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All bookmarks deleted')));
      }
    }
  }

  Future<void> _clearTabs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close All Tabs'),
        content: const Text('Are you sure you want to close all open tabs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // Close all tabs and create a fresh one
      final tabs = _browserService.tabs;
      for (var i = tabs.length - 1; i > 0; i--) {
        await _browserService.closeTab(i);
      }
      if (tabs.isNotEmpty) {
        await _browserService.closeTab(0);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All tabs closed')));
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all browser cache and cookies?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await InAppWebViewController.clearAllCache();
      await CookieManager.instance().deleteAllCookies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Browser cache and cookies cleared')),
        );
      }
    }
  }

  Future<void> _clearAllBrowserData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Browser Data'),
        content: const Text(
          'This will clear all browsing data including:\n'
          '• History\n'
          '• Bookmarks\n'
          '• Tabs\n'
          '• Cache & Cookies\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _browserService.clearAll();
      await InAppWebViewController.clearAllCache();
      await CookieManager.instance().deleteAllCookies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All browser data cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final historyCount = _browserService.history.length;
    final bookmarkCount = _browserService.bookmarks.length;
    final tabCount = _browserService.tabs.length;

    return Column(
      children: [
        SettingsSwitch(
          title: 'Background Audio',
          subtitle:
              'Continue playing audio when floating browser is closed or loses focus',
          icon: Icons.volume_up,
          pref: stows.browserBackgroundAudio,
        ),
        SettingsButton(
          title: 'Clear History',
          subtitle: '$historyCount items',
          icon: Icons.history,
          onPressed: historyCount > 0 ? _clearHistory : null,
        ),
        SettingsButton(
          title: 'Clear Bookmarks',
          subtitle: '$bookmarkCount bookmarks',
          icon: Icons.bookmark,
          onPressed: bookmarkCount > 0 ? _clearBookmarks : null,
        ),
        SettingsButton(
          title: 'Close All Tabs',
          subtitle: '$tabCount tabs open',
          icon: Icons.tab,
          onPressed: tabCount > 1 ? _clearTabs : null,
        ),
        SettingsButton(
          title: 'Clear Cache & Cookies',
          subtitle: 'Remove cached data and cookies',
          icon: Icons.delete_outline,
          onPressed: _clearCache,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            color: colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: colorScheme.error),
              title: const Text('Clear All Browser Data'),
              subtitle: const Text('History, bookmarks, tabs, cache'),
              onTap: _clearAllBrowserData,
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Productivity Timer Settings Section
class _ProductivityTimerSettingsSection extends StatefulWidget {
  const _ProductivityTimerSettingsSection();

  @override
  State<_ProductivityTimerSettingsSection> createState() =>
      _ProductivityTimerSettingsSectionState();
}

class _ProductivityTimerSettingsSectionState
    extends State<_ProductivityTimerSettingsSection> {
  final _timerService = ProductivityTimerService.instance;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onUpdate);
    _timerService.initialize();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timerService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification permission
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Permission'),
          subtitle: Text(
            _timerService.notificationsPermissionGranted
                ? 'Granted - Timer notifications enabled'
                : 'Not granted - Tap to enable timer notifications',
          ),
          trailing: _timerService.notificationsPermissionGranted
              ? Icon(Icons.check_circle, color: Colors.green[700])
              : TextButton(
                  onPressed: () async {
                    await _timerService.requestNotificationPermission();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Enable'),
                ),
        ),
        // Sound enabled
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('Sound Notifications'),
          subtitle: const Text('Play sound when timer completes'),
          value: _timerService.soundEnabled,
          onChanged: (value) => _timerService.setSoundEnabled(value),
        ),
        // Pre-end warning
        SwitchListTile(
          secondary: const Icon(Icons.warning_amber),
          title: const Text('Pre-End Warning'),
          subtitle: Text(
            'Notify ${_timerService.preEndWarningMinutes} min before session ends',
          ),
          value: _timerService.showPreEndWarning,
          onChanged: (value) => _timerService.setPreEndWarning(value),
        ),
        // Auto-start break
        SwitchListTile(
          secondary: const Icon(Icons.coffee),
          title: const Text('Auto-Start Break'),
          subtitle: const Text('Start break automatically after focus session'),
          value: _timerService.autoStartBreak,
          onChanged: (value) => _timerService.setAutoStartBreak(value),
        ),
        // Auto-start next session
        SwitchListTile(
          secondary: const Icon(Icons.play_circle),
          title: const Text('Auto-Start Next Session'),
          subtitle: const Text('Start next focus session after break'),
          value: _timerService.autoStartNextSession,
          onChanged: (value) => _timerService.setAutoStartNextSession(value),
        ),
        // Daily focus goal
        ListTile(
          leading: const Icon(Icons.flag),
          title: const Text('Daily Focus Goal'),
          subtitle: Text('${_timerService.goal.dailyFocusMinutes} minutes'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_timerService.goal.dailyFocusMinutes > 30) {
                    _timerService.setGoal(
                      _timerService.goal.copyWith(
                        dailyFocusMinutes:
                            _timerService.goal.dailyFocusMinutes - 30,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _timerService.setGoal(
                    _timerService.goal.copyWith(
                      dailyFocusMinutes:
                          _timerService.goal.dailyFocusMinutes + 30,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Daily sessions goal
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Daily Sessions Goal'),
          subtitle: Text('${_timerService.goal.dailySessions} sessions'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_timerService.goal.dailySessions > 1) {
                    _timerService.setGoal(
                      _timerService.goal.copyWith(
                        dailySessions: _timerService.goal.dailySessions - 1,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _timerService.setGoal(
                    _timerService.goal.copyWith(
                      dailySessions: _timerService.goal.dailySessions + 1,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Reset statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: const Text('Reset Timer Statistics'),
              subtitle: const Text('Clear all session history and streaks'),
              onTap: () => _showResetConfirmation(context),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will permanently delete all your session history, streaks, and progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _timerService.resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Statistics reset')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// Settings section for Quick Notes auto-deletion
class _QuickNotesSettingsSection extends StatefulWidget {
  const _QuickNotesSettingsSection();

  @override
  State<_QuickNotesSettingsSection> createState() =>
      _QuickNotesSettingsSectionState();
}

class _QuickNotesSettingsSectionState
    extends State<_QuickNotesSettingsSection> {
  final _service = QuickNotesService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enable auto-delete
        SwitchListTile(
          secondary: const Icon(Icons.auto_delete),
          title: const Text('Auto-Delete Notes'),
          subtitle: Text(
            _service.autoDeleteEnabled
                ? 'Notes automatically deleted after ${QuickNoteAutoDeletePresets.formatDuration(_service.autoDeleteDuration)}'
                : 'Notes persist until manually deleted',
          ),
          value: _service.autoDeleteEnabled,
          onChanged: (value) => _service.setAutoDeleteEnabled(value),
        ),
        // Auto-delete duration
        if (_service.autoDeleteEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text(
                          'Auto-Delete After',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: QuickNoteAutoDeletePresets.presets.map((
                        duration,
                      ) {
                        final isSelected =
                            _service.autoDeleteDuration == duration;
                        return ChoiceChip(
                          label: Text(
                            QuickNoteAutoDeletePresets.formatDuration(duration),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _service.setAutoDeleteDuration(duration);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Current notes count
        ListTile(
          leading: Icon(Icons.sticky_note_2, color: colorScheme.primary),
          title: const Text('Current Quick Notes'),
          subtitle: Text(
            _service.isEmpty
                ? 'No quick notes'
                : '${_service.count} note${_service.count > 1 ? 's' : ''}',
          ),
          trailing: _service.isEmpty
              ? null
              : TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear All'),
                  onPressed: () => _showClearConfirmation(context),
                ),
        ),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Quick Notes?'),
        content: const Text(
          'This will permanently delete all your quick notes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _service.clearAllNotes();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All quick notes cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
