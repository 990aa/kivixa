import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

export 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// Windows-specific initialization settings for the notification plugin.
class WindowsInitializationSettings {
  /// Creates a new [WindowsInitializationSettings].
  const WindowsInitializationSettings({
    this.appName,
    this.appUserModelId,
    this.guid,
    this.iconPath,
  });

  /// The app name.
  final String? appName;

  /// The app user model id.
  final String? appUserModelId;

  /// The GUID.
  final String? guid;

  /// The icon path.
  final String? iconPath;
}

/// Windows-specific notification details.
class WindowsNotificationDetails {
  /// Creates a new [WindowsNotificationDetails].
  const WindowsNotificationDetails({
    this.subtitle,
  });

  /// The subtitle.
  final String? subtitle;
}

/// Callback for when a notification is received.
typedef NotificationReceivedCallback = void Function(
    NotificationResponse response);

/// A stub implementation of [FlutterLocalNotificationsPlatform] for Windows.
/// This implementation does nothing and is used to allow building on Windows
/// without the ATL library requirement.
class FlutterLocalNotificationsWindows
    extends FlutterLocalNotificationsPlatform {
  /// Registers this class as the default instance of [FlutterLocalNotificationsPlatform].
  static void registerWith() {
    FlutterLocalNotificationsPlatform.instance =
        FlutterLocalNotificationsWindows();
  }

  /// Initialize the plugin with the given settings.
  Future<bool?> initialize(
    WindowsInitializationSettings settings, {
    NotificationReceivedCallback? onNotificationReceived,
  }) async {
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    return null;
  }

  @override
  Future<void> show(int id, String? title, String? body,
      {WindowsNotificationDetails? details, String? payload}) async {}

  /// Schedule a notification to be shown at the given time.
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    dynamic scheduledDate,
    WindowsNotificationDetails? details, {
    String? payload,
  }) async {}

  @override
  Future<void> periodicallyShow(
    int id,
    String? title,
    String? body,
    RepeatInterval repeatInterval,
  ) async {}

  @override
  Future<void> periodicallyShowWithDuration(
    int id,
    String? title,
    String? body,
    Duration repeatDurationInterval,
  ) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllPendingNotifications() async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [];
  }

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async {
    return [];
  }
}
