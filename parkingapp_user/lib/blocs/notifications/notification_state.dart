part of 'notification_bloc.dart';

class NotificationState {
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationScheduled extends NotificationState {
  final String title;
  final DateTime deliveryTime;

  NotificationScheduled({required this.title, required this.deliveryTime});

  @override
  List<Object> get props => [title, deliveryTime];
}

class NotificationCancelled extends NotificationState {
  final int id;

  NotificationCancelled({required this.id});

  @override
  List<Object> get props => [id];
}

class NotificationError extends NotificationState {
  final String message;

  NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}
