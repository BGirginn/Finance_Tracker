import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidPermissions();
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> showScheduledTransactionNotification({
    required String type,
    required String amount,
    required String currency,
    required DateTime date,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_transactions',
      'Planlı İşlemler',
      channelDescription: 'Planlı işlemler için bildirimler',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = type == 'income' ? 'Gelir Eklendi' : 'Gider Eklendi';
    final body = '$amount $currency - ${date.day}.${date.month}.${date.year}';

    await _notifications.show(
      id: date.millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
