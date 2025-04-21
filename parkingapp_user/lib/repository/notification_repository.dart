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

  // static Future<void> _configureLocalTimeZone() async {
  //   if (kIsWeb || Platform.isLinux) {
  //     return;
  //   }
  //   tz.initializeTimeZones();
  //   if (Platform.isWindows) {
  //     return;
  //   }
  //   final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  //   tz.setLocalLocation(tz.getLocation(timeZoneName));
  // }

  // static Future<void> _configureLocalTimeZone() async {
  //   if (kIsWeb || Platform.isLinux) return;

  //   tz.initializeTimeZones();
  //   if (Platform.isWindows) return; // Skip for Windows
  //   if (Platform.isMacOS) return; // Skip for macOSs

  //   try {
  //     final timeZoneName = await FlutterTimezone.getLocalTimezone();
  //     debugPrint('Configured local timezone: $timeZoneName'); // Add debug print
  //     tz.setLocalLocation(tz.getLocation(timeZoneName));
  //   } catch (e) {
  //     debugPrint('Error configuring timezone: $e');
  //     tz.setLocalLocation(tz.UTC); // Fallback to UTC
  //   }
  // }

  // static Future<void> _configureLocalTimeZone() async {
  //   tz.initializeTimeZones();

  //   try {
  //     if (Platform.isWindows) {
  //       // Windows fallback: Use local time directly
  //       tz.setLocalLocation(tz.local);
  //       debugPrint('Windows timezone configured to local offset');
  //     } else if (!kIsWeb && !Platform.isLinux) {
  //       // Handle other platforms with flutter_timezone
  //       final timeZoneName = await FlutterTimezone.getLocalTimezone();
  //       tz.setLocalLocation(tz.getLocation(timeZoneName));
  //       debugPrint('Configured local timezone: $timeZoneName');
  //     }
  //   } catch (e) {
  //     debugPrint('Error configuring timezone: $e');
  //     tz.setLocalLocation(tz.UTC);
  //   }
  // }

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

  @override
  Future<void> scheduleNotification({
    required String title,
    required String content,
    required DateTime deliveryTime,
    required int id,
  }) async {
    // Check if permissions are granted
    if (!await hasPermission()) {
      debugPrint('Notifications disabled by user - cannot schedule');
      return;
    }

    // Handle timezone conversion
    //tz.initializeTimeZones();
    final location = tz.local;
    var scheduledDate = tz.TZDateTime.from(deliveryTime.toLocal(), location);

    debugPrint('''
  Scheduling notification:
  - Local time: ${deliveryTime.toLocal()}
  - Timezone: ${location.name}
  - Scheduled: $scheduledDate
  ''');
    // Create platform-specific details
    const androidDetails = AndroidNotificationDetails(
      'parking_channel',
      'Parking Notifications',
      channelDescription: 'Time-sensitive parking reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      timeoutAfter: 60000, // 1 minute visibility
    );

    if (Platform.isWindows) {
      final offset =
          tz.local.timeZone(deliveryTime.millisecondsSinceEpoch).offset;
      scheduledDate = tz.TZDateTime.from(
        deliveryTime.add(Duration(milliseconds: offset)),
        tz.local,
      );
      debugPrint('Windows time adjustment: $offset');
    }

// In the showInstantNotification method

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Schedule the notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      scheduledDate,
      const NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Scheduled notification for ${scheduledDate.toLocal()}');
  }

  Future<void> cancelScheduledNotificaion(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
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



  // @override
  // Future<void> requestPermissions() async {
  //   if (defaultTargetPlatform == TargetPlatform.iOS ||
  //       defaultTargetPlatform == TargetPlatform.macOS) {
  //     await _flutterLocalNotificationsPlugin
  //         .resolvePlatformSpecificImplementation<
  //             IOSFlutterLocalNotificationsPlugin>()
  //         ?.requestPermissions(
  //           alert: true,
  //           badge: true,
  //           sound: true,
  //         );
  //   } else if (defaultTargetPlatform == TargetPlatform.android) {
  //     await _flutterLocalNotificationsPlugin
  //         .resolvePlatformSpecificImplementation<
  //             AndroidFlutterLocalNotificationsPlugin>()
  //         ?.requestNotificationsPermission();
  //   }
  // }

  // static Future<FlutterLocalNotificationsPlugin>
  //     _initializeNotifications() async {
  //   var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //   var initializationSettingsAndroid =
  //       const AndroidInitializationSettings('@mipmap/ic_launcher');
  //   var initializationSettingsIOS = const DarwinInitializationSettings();

  //   await flutterLocalNotificationsPlugin.initialize(InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsIOS,
  //   ));

  //   return flutterLocalNotificationsPlugin;
  // }


  // @override
  // Future<void> scheduleNotification({
  //   required String title,
  //   required String content,
  //   required DateTime deliveryTime,
  //   required int id,
  // }) async {
  //   if (deliveryTime.isBefore(DateTime.now())) {
  //     debugPrint('Skipping notification scheduled in the past');
  //     return;
  //   }

  //   final String channelId = const Uuid().v4();
  //   const String channelName = "notifications_channel";
  //   const String channelDescription = "Standard notifications";

  //   final androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     channelId,
  //     channelName,
  //     channelDescription: channelDescription,
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //   );

  //   final platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: const DarwinNotificationDetails(),
  //   );

  //   await _flutterLocalNotificationsPlugin.zonedSchedule(
  //     id,
  //     title,
  //     content,
  //     tz.TZDateTime.from(deliveryTime, tz.local),
  //     platformChannelSpecifics,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //   );
  // }

    // static Future<void> _configureLocalTimeZone() async {
  //   tz.initializeTimeZones();
  //   final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  //   tz.setLocalLocation(tz.getLocation(timeZoneName));
  // }

    // Future<void> scheduleNotification(
  //     {required String title,
  //     required String content,
  //     required DateTime deliveryTime,
  //     required int id}) async {
  //   await requestPermissions(); // be om tillåtelse innan schemaläggning sker (kommer ihåg ditt val sen tidigare)

  //   String channelId = const Uuid().v4();
  //   const String channelName =
  //       "notifications_channel"; // kanal av notiser där alla notiser inom denna kanal levereras på liknande sätt. Går att konfigurera kanaler på olika sätt.
  //   String channelDescription =
  //       "Standard notifications"; // Beskrivningen av denna kanal som dyker upp i settings på android.

  //   // Android-specifika inställningar
  //   var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //       channelId, channelName,
  //       channelDescription: channelDescription,
  //       importance: Importance.max,
  //       priority: Priority.high,
  //       ticker: 'ticker');

  //   // iOS-specifika inställningar
  //   var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();

  //   // Kombinera plattformsinställningar
  //   var platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //       iOS: iOSPlatformChannelSpecifics);

  //   await _flutterLocalNotificationsPlugin.zonedSchedule(id, title, content,
  //       tz.TZDateTime.from(deliveryTime, tz.local), platformChannelSpecifics,
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //       uiLocalNotificationDateInterpretation:
  //           UILocalNotificationDateInterpretation.absoluteTime);
  // }