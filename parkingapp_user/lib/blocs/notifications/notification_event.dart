part of 'notification_bloc.dart';

sealed class NotificationEvent {
  @override
  List<Object> get props => [];
}

class ScheduleNotification extends NotificationEvent {
  final int id;
  final String title;
  final String content;
  final DateTime deliveryTime;

  ScheduleNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.deliveryTime,
  });

  @override
  List<Object> get props => [id, title, content, deliveryTime];
}

class CancelNotification extends NotificationEvent {
  final int id;

  CancelNotification({required this.id});

  @override
  List<Object> get props => [id];
}
