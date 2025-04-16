import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

class NotificationWebRepository implements BaseNotificationRepository {
  static NotificationWebRepository? _instance;

  NotificationWebRepository._();

  static Future<NotificationWebRepository> get instance async {
    _instance ??= NotificationWebRepository._();
    return _instance!;
  }

  @override
  Future<void> cancelScheduledNotification(int id) async {
    // Web notifications don't have a direct cancellation API
    // Implement custom cancellation logic if needed
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String content,
    required DateTime deliveryTime,
    required int id,
  }) async {
    final delayDuration = deliveryTime.difference(DateTime.now());
    if (delayDuration.isNegative) return;

    Future.delayed(delayDuration, () {
      _showWebNotification(title, content);
    });
  }

  @override
  Future<void> requestPermissions() async {
    final permission = web.Notification.permission;
    if (permission == "default".toJS) {
      await web.Notification.requestPermission().toDart;
    }
  }

  void _showWebNotification(String title, String content) {
    if (web.Notification.permission == "granted".toJS) {
      final options = web.NotificationOptions(body: content.toJS.toDart);
      web.Notification(title.toJS.toDart, options);
    }
  }
}
