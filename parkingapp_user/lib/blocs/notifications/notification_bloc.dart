import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/repository/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc(this.notificationRepository) : super(NotificationInitial()) {
    on<ScheduleNotification>((event, emit) async {
      try {
        await notificationRepository.scheduleNotification(
          title: event.title,
          content: event.content,
          deliveryTime: event.deliveryTime,
          id: event.id,
        );
        emit(NotificationScheduled(
            title: event.title, deliveryTime: event.deliveryTime));
      } catch (e) {
        emit(NotificationError(message: "Failed to schedule notification: $e"));
      }
    });

    on<CancelNotification>((event, emit) async {
      try {
        await notificationRepository.cancelScheduledNotification(event.id);
        emit(NotificationCancelled(id: event.id));
      } catch (e) {
        emit(NotificationError(message: "Failed to cancel notification: $e"));
      }
    });
  }
}
