import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showInstant({
    required String id,
    required String title,
    required String body,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sunday_channel',
        'Sun Day Alerts',
        channelDescription: 'Sunrise, sunset, and exposure alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(id.hashCode, title, body, details);
  }

  Future<void> scheduleAt({
    required String id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (when.isBefore(DateTime.now())) return; // only future
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sunday_channel',
        'Sun Day Alerts',
        channelDescription: 'Sunrise, sunset, and exposure alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.schedule(
      id.hashCode,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: null,
    );
  }

  Future<void> cancelIds(List<String> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id.hashCode);
    }
  }
}
