import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

abstract class BaseNotificationRepository {
  Future<void> cancelScheduledNotification(int id);
  Future<void> scheduleNotification({
    required String title,
    required String content,
    required DateTime deliveryTime,
    required int id,
  });
  Future<void> requestPermissions();
}

class NotificationRepository implements BaseNotificationRepository {
  static NotificationRepository? _instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationRepository._(this._flutterLocalNotificationsPlugin);

  // Add this method to check current permission status
  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      // ignore: unrelated_type_equality_checks
      return result == true;
    }
    return true; // Android doesn't require runtime permission checks
  }

  static Future<NotificationRepository> get instance async {
    if (_instance == null) {
      await _configureLocalTimeZone();
      final plugin = await initializeNotifications();
      _instance = NotificationRepository._(plugin);
    }
    return _instance!;
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('System Timezone: $timeZoneName');
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      debugPrint('Configured Timezone: ${tz.local.name}');
    } catch (e) {
      debugPrint('Error configuring timezone: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  static Future<FlutterLocalNotificationsPlugin>
      initializeNotifications() async {
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android-inställningar
    var initializationSettingsAndroid = const AndroidInitializationSettings(
        '@mipmap/ic_launcher'); // Eller använd egen ikon: '@drawable/ic_notification'

    // iOS-inställningar
    var initializationSettingsIOS = const DarwinInitializationSettings();

    // Kombinera plattformsinställningar
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    return flutterLocalNotificationsPlugin;
  }

  @override
  Future<void> cancelScheduledNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // @override
  // Future<void> scheduleNotification({
  //   required String title,
  //   required String content,
  //   required DateTime deliveryTime,
  //   required int id,
  // }) async {
  //   if (!await hasPermission()) {
  //     debugPrint('Notifications disabled by user - cannot schedule');
  //     return;
  //   }

  //   // Convert to a TZDateTime in the local zone
  //   final tzDateTime = tz.TZDateTime.from(deliveryTime, tz.local);
  //   debugPrint('Scheduling one‑off notif (#$id) at $tzDateTime');

  //   const androidDetails = AndroidNotificationDetails(
  //     'parking_channel',
  //     'Parking Notifications',
  //     channelDescription: 'Time‑sensitive parking reminders',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     enableVibration: true,
  //     playSound: true,
  //     timeoutAfter: 60000,
  //   );

  //   const iOSDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   await _flutterLocalNotificationsPlugin.zonedSchedule(
  //     id,
  //     title,
  //     content,
  //     tzDateTime,
  //     const NotificationDetails(
  //       android: androidDetails,
  //       iOS: iOSDetails,
  //     ),
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //   );

  //   debugPrint('✅ Scheduled one‑off notif (#$id) for $tzDateTime');
  // }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String content,
    required DateTime deliveryTime,
    required int id,
  }) async {
    if (!await hasPermission()) return;

    // Convert the incoming deliveryTime (which is in the device's local zone)
    // into a TZDateTime in our local timezone:
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(deliveryTime.toLocal(), tz.local);

    // If it’s not strictly in the future, bail out:
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      debugPrint(
        '❌ Not scheduling notification #$id at $scheduledDate: not in the future.',
      );
      return;
    }

    debugPrint('✅ Scheduling notification #$id at $scheduledDate');

    const androidDetails = AndroidNotificationDetails(
      'parking_channel',
      'Parking Notifications',
      channelDescription: 'Time‑sensitive parking reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      timeoutAfter: 60000,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      scheduledDate,
      const NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ← NO matchDateTimeComponents!  we want a one‑off
    );
  }

  Future<void> showInstantNotification(String message) async {
    if (!await hasPermission()) return;

    const android = AndroidNotificationDetails(
      'parking_channel',
      'Parking Notifications',
      channelDescription: 'Time-sensitive parking reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      timeoutAfter: 60000,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // ID 0 for instant notifications
      'Parkering Startad',
      message,
      NotificationDetails(android: android),
    );
  }
}
