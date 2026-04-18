import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  var initialized = false;
  var cancelAllCount = 0;
  List<int> cancelledIds = [];
  List<Map<String, dynamic>> scheduledNotifications = [];
  List<Map<String, dynamic>> shownNotifications = [];

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized = true;
    return true;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
      'notificationDetails': notificationDetails,
    });
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }

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

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return null;
  }

  @override
  Future<void> periodicallyShow(
    int id,
    String? title,
    String? body,
    RepeatInterval repeatInterval,
    NotificationDetails notificationDetails, {
    String? payload,
    AndroidScheduleMode? androidScheduleMode,
  }) async {}

  @override
  Future<void> periodicallyShowWithDuration(
    int id,
    String? title,
    String? body,
    Duration repeatDurationInterval,
    NotificationDetails notificationDetails, {
    String? payload,
    AndroidScheduleMode? androidScheduleMode,
  }) async {}

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => null;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'notificationDetails': notificationDetails,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
