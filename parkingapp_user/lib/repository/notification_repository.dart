// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:uuid/uuid.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;

// import 'dart:async';
// import 'dart:io' show Platform, exit;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'dart:html' as html show Notification; // Import dart:html for web notifications

// Future<void> _configureLocalTimeZone() async {
//   if (kIsWeb) return;
//   tz.initializeTimeZones();
//   final String timeZoneName = await FlutterTimezone.getLocalTimezone();
//   tz.setLocalLocation(tz.getLocation(timeZoneName));
// }

// Future<FlutterLocalNotificationsPlugin> initializeNotifications() async {
//   var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   var initializationSettingsAndroid =
//       const AndroidInitializationSettings('@mipmap/ic_launcher');
//   var initializationSettingsIOS = const DarwinInitializationSettings();
//   var initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
//   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   return flutterLocalNotificationsPlugin;
// }

// class NotificationRepository {
//   static NotificationRepository? _instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

//   // Private constructor
//   NotificationRepository._(this._flutterLocalNotificationsPlugin);

//   // Asynchronous singleton getter
//   static Future<NotificationRepository> get instance async {
//     if (_instance == null) {
//       await _configureLocalTimeZone();
//       final plugin = await initializeNotifications();
//       _instance = NotificationRepository._(plugin);
//     }
//     return _instance!;
//   }

//   Future<void> cancelScheduledNotification(int id) async {
//     if (kIsWeb) return; // No need to cancel notifications on web
//     await _flutterLocalNotificationsPlugin.cancel(id);
//   }

//   Future<void> scheduleNotification({
//     required String title,
//     required String content,
//     required DateTime deliveryTime,
//     required int id,
//   }) async {
//     await requestPermissions();

//     if (kIsWeb) {
//       // Handle Web Notifications
//       Future.delayed(deliveryTime.difference(DateTime.now()), () {
//         _showWebNotification(title, content);
//       });
//       return;
//     }

//     if (deliveryTime.isBefore(DateTime.now())) {
//       debugPrint('Skipping notification scheduled in the past');
//       return;
//     }

//     // Mobile (Android/iOS) Notifications
//     String channelId = const Uuid().v4();
//     const String channelName = "notifications_channel";
//     String channelDescription = "Standard notifications";
//     var androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       channelId,
//       channelName,
//       channelDescription: channelDescription,
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//     );
//     var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
//     var platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: iOSPlatformChannelSpecifics,
//     );

//     return await _flutterLocalNotificationsPlugin.zonedSchedule(
//       id,
//       title,
//       content,
//       tz.TZDateTime.from(deliveryTime, tz.local),
//       platformChannelSpecifics,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> requestPermissions() async {
//     if (kIsWeb) {
//       // Request permission for Web Notifications
//       if (html.Notification.permission == "default") {
//         await html.Notification.requestPermission();
//       }
//       return;
//     }

//     // Handle permissions for mobile (Android/iOS)
//     if (defaultTargetPlatform == TargetPlatform.iOS ||
//         defaultTargetPlatform == TargetPlatform.macOS) {
//       await _flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//       await _flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               MacOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//     } else if (defaultTargetPlatform == TargetPlatform.android) {
//       final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//           _flutterLocalNotificationsPlugin
//               .resolvePlatformSpecificImplementation<
//                   AndroidFlutterLocalNotificationsPlugin>();
//       await androidImplementation?.requestNotificationsPermission();
//     }
//   }

//   void _showWebNotification(String title, String content) {
//     if (html.Notification.permission == "granted") {
//       html.Notification(title, body: content);
//     }
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:uuid/uuid.dart';

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

  static Future<NotificationRepository> get instance async {
    if (_instance == null) {
      await _configureLocalTimeZone();
      final plugin = await _initializeNotifications();
      _instance = NotificationRepository._(plugin);
    }
    return _instance!;
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  static Future<FlutterLocalNotificationsPlugin>
      _initializeNotifications() async {
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const DarwinInitializationSettings();

    await flutterLocalNotificationsPlugin.initialize(InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    ));

    return flutterLocalNotificationsPlugin;
  }

  @override
  Future<void> cancelScheduledNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String content,
    required DateTime deliveryTime,
    required int id,
  }) async {
    if (deliveryTime.isBefore(DateTime.now())) {
      debugPrint('Skipping notification scheduled in the past');
      return;
    }

    final String channelId = const Uuid().v4();
    const String channelName = "notifications_channel";
    const String channelDescription = "Standard notifications";

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      tz.TZDateTime.from(deliveryTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
}
