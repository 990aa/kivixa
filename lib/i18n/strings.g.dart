/// Generated file from en.i18n.yaml
/// This is a simplified version without slang dependency
///
// ignore_for_file: type=lint, unused_import, camel_case_types

import 'package:flutter/widgets.dart';

class Translations {
  final TranslationsCommon common = TranslationsCommon();
  final TranslationsHome home = TranslationsHome();
  final TranslationsSentry sentry = TranslationsSentry();
  final TranslationsSettings settings = TranslationsSettings();
  final TranslationsLogs logs = TranslationsLogs();
  final TranslationsLogin login = TranslationsLogin();
  final TranslationsProfile profile = TranslationsProfile();
  final TranslationsAppInfo appInfo = TranslationsAppInfo();
  final TranslationsUpdate update = TranslationsUpdate();
  final TranslationsEditor editor = TranslationsEditor();
}

class TranslationsCommon {
  String get done => 'Done';
  String get continueBtn => 'Continue';
  String get cancel => 'Cancel';
  String get rename => 'Rename';
  String get delete => 'Delete';
  String get error => 'Error';
}

class TranslationsHome {
  final TranslationsHomeTabs tabs = TranslationsHomeTabs();
  final TranslationsHomeTitles titles = TranslationsHomeTitles();
  final TranslationsHomeTooltips tooltips = TranslationsHomeTooltips();
  final TranslationsHomeCreate create = TranslationsHomeCreate();
  String get welcome => 'Welcome to kivixa';
  String get invalidFormat =>
      'The file you selected is not supported. Please select a kvx or pdf file.';
  String get noFiles => 'No files found';
  String get noPreviewAvailable => 'No preview available';
  String get createNewNote => 'Tap the + button to create a new note';
  String get backFolder => 'Go back to the previous folder';
  final TranslationsHomeNewFolder newFolder = TranslationsHomeNewFolder();
  final TranslationsHomeRenameNote renameNote = TranslationsHomeRenameNote();
  final TranslationsHomeMoveNote moveNote = TranslationsHomeMoveNote();
  String get deleteNote => 'Delete note';
  String get renameFile => 'Rename file';
  String get deleteFile => 'Delete file';
  String get fileName => 'File name';
  String get fileRenamed => 'File renamed successfully';
  String get fileDeleted => 'File deleted successfully';
  String get deleteFileConfirmation =>
      'Are you sure you want to delete this file? This action cannot be undone.';
  final TranslationsHomeRenameFolder renameFolder =
      TranslationsHomeRenameFolder();
  final TranslationsHomeDeleteFolder deleteFolder =
      TranslationsHomeDeleteFolder();
}

class TranslationsHomeTabs {
  String get home => 'Home';
  String get browse => 'Browse';
  String get whiteboard => 'Whiteboard';
  String get settings => 'Settings';
}

class TranslationsHomeTitles {
  String get home => 'Recent notes';
  String get browse => 'Browse';
  String get whiteboard => 'Whiteboard';
  String get settings => 'Settings';
}

class TranslationsHomeTooltips {
  String get newNote => 'New note';
  String get showUpdateDialog => 'Show update dialog';
  String get exportNote => 'Export note';
}

class TranslationsHomeCreate {
  String get newNote => 'New note';
  String get importNote => 'Import note';
}

class TranslationsHomeNewFolder {
  String get newFolder => 'New folder';
  String get folderName => 'Folder name';
  String get create => 'Create';
  String get folderNameEmpty => 'Folder name can\'t be empty';
  String get folderNameContainsSlash => 'Folder name can\'t contain a slash';
  String get folderNameExists => 'Folder already exists';
}

class TranslationsHomeRenameNote {
  String get renameNote => 'Rename note';
  String get noteName => 'Note name';
  String get rename => 'Rename';
  String get noteNameEmpty => 'Note name can\'t be empty';
  String get noteNameContainsSlash => 'Note name can\'t contain a slash';
  String get noteNameExists => 'A note with this name already exists';
}

class TranslationsHomeMoveNote {
  String get moveNote => 'Move note';
  String moveNotes({required Object n}) => 'Move ${n} notes';
  String moveName({required Object f}) => 'Move ${f}';
  String get move => 'Move';
  String renamedTo({required Object newName}) =>
      'Note will be renamed to ${newName}';
  String get multipleRenamedTo => 'The following notes will be renamed:';
  String numberRenamedTo({required Object n}) =>
      '${n} notes will be renamed to avoid conflicts';
}

class TranslationsHomeRenameFolder {
  String get renameFolder => 'Rename folder';
  String get folderName => 'Folder name';
  String get rename => 'Rename';
  String get folderNameEmpty => 'Folder name can\'t be empty';
  String get folderNameContainsSlash => 'Folder name can\'t contain a slash';
  String get folderNameExists => 'A folder with this name already exists';
}

class TranslationsHomeDeleteFolder {
  String get deleteFolder => 'Delete folder';
  String deleteName({required Object f}) => 'Delete ${f}';
  String get delete => 'Delete';
  String get alsoDeleteContents => 'Also delete all notes inside this folder';
}

class TranslationsSentry {
  final TranslationsSentryConsent consent = TranslationsSentryConsent();
}

class TranslationsSentryConsent {
  String get title => 'Help improve kivixa?';
  final TranslationsSentryConsentDescription description =
      TranslationsSentryConsentDescription();
  final TranslationsSentryConsentAnswers answers =
      TranslationsSentryConsentAnswers();
}

class TranslationsSentryConsentDescription {
  String get question =>
      'Would you like to automatically report unexpected errors? This helps me identify and fix issues faster.';
  String get scope =>
      'The reports may contain information about the error and your device. I\'ve made every effort to filter out personal data but some may remain.';
  String get currentlyOff =>
      'If you grant consent, error reporting will be enabled after you restart the app.';
  String get currentlyOn =>
      'If you revoke consent, please restart the app to disable error reporting.';
}

class TranslationsSentryConsentAnswers {
  String get yes => 'Yes';
  String get no => 'No';
  String get later => 'Ask me later';
}

class TranslationsSettings {
  final TranslationsSettingsPrefCategories prefCategories =
      TranslationsSettingsPrefCategories();
  final TranslationsSettingsPrefLabels prefLabels =
      TranslationsSettingsPrefLabels();
  final TranslationsSettingsPrefDescriptions prefDescriptions =
      TranslationsSettingsPrefDescriptions();
  final TranslationsSettingsThemeModes themeModes =
      TranslationsSettingsThemeModes();
  final TranslationsSettingsLayoutSizes layoutSizes =
      TranslationsSettingsLayoutSizes();
  final TranslationsSettingsAccentColorPicker accentColorPicker =
      TranslationsSettingsAccentColorPicker();
  String get systemLanguage => 'Auto';
  List<String> get axisDirections => ['Top', 'Right', 'Bottom', 'Left'];
  final TranslationsSettingsReset reset = TranslationsSettingsReset();
  String get resyncEverything => 'Resync everything';
  String get openDataDir => 'Open kivixa folder';
  final TranslationsSettingsCustomDataDir customDataDir =
      TranslationsSettingsCustomDataDir();
  String get autosaveDisabled => 'Never';
  String get shapeRecognitionDisabled => 'Never';
}

class TranslationsSettingsPrefCategories {
  String get general => 'General';
  String get writing => 'Writing';
  String get editor => 'Editor';
  String get performance => 'Performance';
  String get advanced => 'Advanced';
}

class TranslationsSettingsPrefLabels {
  String get locale => 'Language';
  String get appTheme => 'App theme';
  String get platform => 'Theme type';
  String get layoutSize => 'Layout type';
  String get customAccentColor => 'Custom accent color';
  String get hyperlegibleFont => 'Atkinson Hyperlegible font';
  String get shouldCheckForUpdates => 'Check for kivixa updates';
  String get shouldAlwaysAlertForUpdates => 'Faster updates';
  String get allowInsecureConnections => 'Allow insecure connections';
  String get editorToolbarAlignment => 'Toolbar position';
  String get editorToolbarShowInFullscreen =>
      'Show the toolbar in fullscreen mode';
  String get editorAutoInvert => 'Invert notes in dark mode';
  String get preferGreyscale => 'Prefer greyscale colors';
  String get maxImageSize => 'Maximum image size';
  String get autoClearWhiteboardOnExit => 'Auto-clear the whiteboard';
  String get disableEraserAfterUse => 'Auto-disable the eraser';
  String get hideFingerDrawingToggle => 'Hide the finger drawing toggle';
  String get editorPromptRename => 'Prompt you to rename new notes';
  String get recentColorsDontSavePresets =>
      'Don\'t save preset colors in recent colors';
  String get recentColorsLength => 'How many recent colors to store';
  String get printPageIndicators => 'Print page indicators';
  String get autosave => 'Auto-save';
  String get shapeRecognitionDelay => 'Shape recognition delay';
  String get autoStraightenLines => 'Auto straighten lines';
  String get simplifiedHomeLayout => 'Simplified home layout';
  String get customDataDir => 'Custom kivixa folder';
  String get pencilSoundSetting => 'Pencil sound effect';
  String get sentry => 'Error reporting';
}

class TranslationsSettingsPrefDescriptions {
  String get hyperlegibleFont =>
      'Increases legibility for users with low vision';
  String get allowInsecureConnections =>
      '(Not recommended) Allow kivixa to connect to servers with self-signed/untrusted certificates';
  String get preferGreyscale => 'For e-ink displays';
  String get autoClearWhiteboardOnExit =>
      'Clears the whiteboard after you exit the app';
  String get disableEraserAfterUse =>
      'Automatically switches back to the pen after using the eraser';
  String get maxImageSize => 'Larger images will be compressed';
  final TranslationsSettingsPrefDescriptionsHideFingerDrawing
  hideFingerDrawing = TranslationsSettingsPrefDescriptionsHideFingerDrawing();
  String get editorPromptRename => 'You can always rename notes later';
  String get printPageIndicators => 'Show page indicators in exports';
  String get autosave => 'Auto-save after a short delay, or never';
  String get shapeRecognitionDelay => 'How often to update the shape preview';
  String get autoStraightenLines =>
      'Straightens long lines without having to use the shape pen';
  String get simplifiedHomeLayout =>
      'Sets a fixed height for each note preview';
  String get shouldAlwaysAlertForUpdates =>
      'Tell me about updates as soon as they\'re available';
  final TranslationsSettingsPrefDescriptionsPencilSoundSetting
  pencilSoundSetting = TranslationsSettingsPrefDescriptionsPencilSoundSetting();
  final TranslationsSettingsPrefDescriptionsSentry sentry =
      TranslationsSettingsPrefDescriptionsSentry();
}

class TranslationsSettingsPrefDescriptionsHideFingerDrawing {
  String get shown => 'Prevents accidental toggling';
  String get fixedOn => 'Finger drawing is fixed as enabled';
  String get fixedOff => 'Finger drawing is fixed as disabled';
}

class TranslationsSettingsPrefDescriptionsPencilSoundSetting {
  String get off => 'No sound';
  String get onButNotInSilentMode => 'Enabled (unless in silent mode)';
  String get onAlways => 'Enabled (even in silent mode)';
}

class TranslationsSettingsPrefDescriptionsSentry {
  String get active => 'Active';
  String get inactive => 'Inactive';
  String get activeUntilRestart => 'Active until you restart the app';
  String get inactiveUntilRestart => 'Inactive until you restart the app';
}

class TranslationsSettingsThemeModes {
  String get system => 'System';
  String get light => 'Light';
  String get dark => 'Dark';
}

class TranslationsSettingsLayoutSizes {
  String get auto => 'Auto';
  String get phone => 'Phone';
  String get tablet => 'Tablet';
}

class TranslationsSettingsAccentColorPicker {
  String get pickAColor => 'Pick a color';
}

class TranslationsSettingsReset {
  String get title => 'Reset this setting?';
  String get button => 'Reset';
}

class TranslationsSettingsCustomDataDir {
  String get cancel => 'Cancel';
  String get select => 'Select';
  String get mustBeEmpty => 'Selected folder must be empty';
  String get mustBeDoneSyncing =>
      'Make sure syncing is complete before changing the folder';
  String get unsupported =>
      'This feature is currently only for developers. Using it will likely result in data loss.';
}

class TranslationsLogs {
  String get logs => 'Logs';
  String get viewLogs => 'View logs';
  String get debuggingInfo =>
      'Logs contain information useful for debugging and development';
  String get noLogs => 'No logs here!';
  String get useTheApp => 'Logs will appear here as you use the app';
}

class TranslationsLogin {
  String get title => 'Login';
  final TranslationsLoginForm form = TranslationsLoginForm();
  final TranslationsLoginStatus status = TranslationsLoginStatus();
  final TranslationsLoginNcLoginStep ncLoginStep =
      TranslationsLoginNcLoginStep();
  final TranslationsLoginEncLoginStep encLoginStep =
      TranslationsLoginEncLoginStep();
}

class TranslationsLoginForm {}

class TranslationsLoginStatus {
  String get loggedOut => 'Logged out';
  String get tapToLogin => 'Tap to log in with Nextcloud';
  String hi({required Object u}) => 'Hi, ${u}!';
  String get almostDone => 'Almost ready for syncing, tap to finish logging in';
  String get loggedIn => 'Logged in with Nextcloud';
}

class TranslationsLoginNcLoginStep {
  String get whereToStoreData => 'Choose where you want to store your data:';
  String get kivixaNcServer => 'kivixa\'s Nextcloud server';
  String get otherNcServer => 'Other Nextcloud server';
  String get serverUrl => 'Server URL';
  String get loginWithkivixa => 'Login with kivixa';
  String get loginWithNextcloud => 'Login with Nextcloud';
  final TranslationsLoginNcLoginStepLoginFlow loginFlow =
      TranslationsLoginNcLoginStepLoginFlow();
}

class TranslationsLoginNcLoginStepLoginFlow {
  String get pleaseAuthorize =>
      'Please authorize kivixa to access your Nextcloud account';
  String get followPrompts =>
      'Please follow the prompts in the Nextcloud interface';
  String get browserDidntOpen => 'Login page didn\'t open? Click here';
}

class TranslationsLoginEncLoginStep {
  String get enterEncPassword =>
      'To protect your data, please enter your encryption password:';
  String get newTokivixa =>
      'New to kivixa? Just enter a new encryption password.';
  String get encPassword => 'Encryption password';
  String get encFaqTitle => 'Frequently asked questions';
  String get wrongEncPassword =>
      'Decryption failed with the provided password. Please try entering it again.';
  String get connectionFailed =>
      'Something went wrong connecting to the server. Please try again later.';
  List<dynamic> get encFaq => [];
}

class TranslationsProfile {
  String get title => 'My profile';
  String get logout => 'Log out';
  String quotaUsage({
    required Object used,
    required Object total,
    required Object percent,
  }) => 'You\'re using ${used} of ${total} (${percent}%)';
  String get connectedTo => 'Connected to';
  final TranslationsProfileQuickLinks quickLinks =
      TranslationsProfileQuickLinks();
  String get faqTitle => 'Frequently asked questions';
  List<dynamic> get faq => [];
}

class TranslationsProfileQuickLinks {
  String get serverHomepage => 'Server homepage';
  String get deleteAccount => 'Delete account';
}

class TranslationsAppInfo {
  String licenseNotice({required Object buildYear}) =>
      'kivixa  Copyright © 2022-${buildYear}  990aa\nThis program comes with absolutely no warranty. This is free software, and you are welcome to redistribute it under certain conditions.';
  String get dirty => 'DIRTY';
  String get debug => 'DEBUG';
  String get sponsorButton => 'Tap here to sponsor me or buy more storage';
  String get licenseButton => 'Tap here to view more license information';
  String get privacyPolicyButton => 'Tap here to view the privacy policy';
}

class TranslationsUpdate {
  String get updateAvailable => 'Update available';
  String get updateAvailableDescription =>
      'A new version of the app is available:';
  String get update => 'Update';
  String get downloadNotAvailableYet =>
      'The download isn\'t available yet for your platform. Please check back shortly.';
}

class TranslationsEditor {
  final TranslationsEditorToolbar toolbar = TranslationsEditorToolbar();
  final TranslationsEditorPens pens = TranslationsEditorPens();
  final TranslationsEditorPenOptions penOptions =
      TranslationsEditorPenOptions();
  final TranslationsEditorColors colors = TranslationsEditorColors();
  final TranslationsEditorImageOptions imageOptions =
      TranslationsEditorImageOptions();
  final TranslationsEditorSelectionBar selectionBar =
      TranslationsEditorSelectionBar();
  final TranslationsEditorMenu menu = TranslationsEditorMenu();
  final TranslationsEditorNewerFileFormat newerFileFormat =
      TranslationsEditorNewerFileFormat();
  final TranslationsEditorQuill quill = TranslationsEditorQuill();
  final TranslationsEditorHud hud = TranslationsEditorHud();
  String get pages => 'Pages';
  String get untitled => 'Untitled';
  String get needsToSaveBeforeExiting =>
      'Saving your changes... You can safely exit the editor when it\'s done';
}

class TranslationsEditorToolbar {
  String get toggleColors => 'Toggle colors (Ctrl C)';
  String get select => 'Select';
  String get toggleEraser => 'Toggle eraser (Ctrl E)';
  String get photo => 'Images';
  String get text => 'Text';
  String get toggleFingerDrawing => 'Toggle finger drawing (Ctrl F)';
  String get undo => 'Undo';
  String get redo => 'Redo';
  String get export => 'Export (Ctrl Shift S)';
  String get exportAs => 'Export as:';
  String get fullscreen => 'Toggle fullscreen (F11)';
}

class TranslationsEditorPens {
  String get fountainPen => 'Fountain pen';
  String get ballpointPen => 'Ballpoint pen';
  String get highlighter => 'Highlighter';
  String get pencil => 'Pencil';
  String get shapePen => 'Shape pen';
  String get laserPointer => 'Laser pointer';
}

class TranslationsEditorPenOptions {
  String get size => 'Size';
}

class TranslationsEditorColors {
  String get colorPicker => 'Color picker';
  String customBrightnessHue({required Object b, required Object h}) =>
      'Custom ${b} ${h}';
  String customHue({required Object h}) => 'Custom ${h}';
  String get dark => 'dark';
  String get light => 'light';
  String get black => 'Black';
  String get darkGrey => 'Dark grey';
  String get grey => 'Grey';
  String get lightGrey => 'Light grey';
  String get white => 'White';
  String get red => 'Red';
  String get green => 'Green';
  String get cyan => 'Cyan';
  String get blue => 'Blue';
  String get yellow => 'Yellow';
  String get purple => 'Purple';
  String get pink => 'Pink';
  String get orange => 'Orange';
  String get pastelRed => 'Pastel red';
  String get pastelOrange => 'Pastel orange';
  String get pastelYellow => 'Pastel yellow';
  String get pastelGreen => 'Pastel green';
  String get pastelCyan => 'Pastel cyan';
  String get pastelBlue => 'Pastel blue';
  String get pastelPurple => 'Pastel purple';
  String get pastelPink => 'Pastel pink';
}

class TranslationsEditorImageOptions {
  String get title => 'Image options';
  String get invertible => 'Invertible';
  String get download => 'Download';
  String get setAsBackground => 'Set as background';
  String get removeAsBackground => 'Remove as background';
  String get delete => 'Delete';
}

class TranslationsEditorSelectionBar {
  String get delete => 'Delete';
  String get duplicate => 'Duplicate';
}

class TranslationsEditorMenu {
  String clearPage({required Object page, required Object totalPages}) =>
      'Clear page ${page}/${totalPages}';
  String get clearAllPages => 'Clear all pages';
  String get insertPage => 'Insert page below';
  String get duplicatePage => 'Duplicate page';
  String get deletePage => 'Delete page';
  String get lineHeight => 'Line height';
  String get lineHeightDescription =>
      'Also controls the text size for typed notes';
  String get lineThickness => 'Line thickness';
  String get lineThicknessDescription => 'Background line thickness';
  String get backgroundImageFit => 'Background image fit';
  String get backgroundPattern => 'Background pattern';
  String get import => 'Import';
  String get watchServer => 'Watch for updates on the server';
  String get watchServerReadOnly =>
      'Editing is disabled while watching the server';
  final TranslationsEditorMenuBoxFits boxFits = TranslationsEditorMenuBoxFits();
  final TranslationsEditorMenuBgPatterns bgPatterns =
      TranslationsEditorMenuBgPatterns();
}

class TranslationsEditorMenuBoxFits {
  String get fill => 'Stretch';
  String get cover => 'Cover';
  String get contain => 'Contain';
}

class TranslationsEditorMenuBgPatterns {
  String get none => 'Blank';
  String get college => 'College-ruled';
  String get collegeRtl => 'College-ruled (Reverse)';
  String get lined => 'Lined';
  String get grid => 'Grid';
  String get dots => 'Dots';
  String get staffs => 'Staffs';
  String get tablature => 'Tablature';
  String get cornell => 'Cornell';
}

class TranslationsEditorNewerFileFormat {
  String get readOnlyMode => 'Read-only mode';
  String get title => 'This note was edited using a newer version of kivixa';
  String get subtitle =>
      'Editing this note may result in some information being lost. Do you want to ignore this and edit it anyway?';
  String get allowEditing => 'Allow editing';
}

class TranslationsEditorQuill {
  String get typeSomething => 'Type something here...';
}

class TranslationsEditorHud {
  String get unlockZoom => 'Unlock zoom';
  String get lockZoom => 'Lock zoom';
  String get unlockSingleFingerPan => 'Enable single-finger panning';
  String get lockSingleFingerPan => 'Disable single-finger panning';
  String get unlockAxisAlignedPan => 'Unlock panning to horizontal or vertical';
  String get lockAxisAlignedPan => 'Lock panning to horizontal or vertical';
}

/// Global translations instance
final t = Translations();
