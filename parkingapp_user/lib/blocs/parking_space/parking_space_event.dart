part of 'parking_space_bloc.dart';

abstract class ParkingSpaceEvent extends Equatable {
  const ParkingSpaceEvent();
}

class LoadParkingSpaces extends ParkingSpaceEvent {
  final bool forceRefresh;

  const LoadParkingSpaces({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SelectParkingSpace extends ParkingSpaceEvent {
  final ParkingSpace parkingSpace;

  const SelectParkingSpace(this.parkingSpace);

  @override
  List<Object> get props => [parkingSpace];
}

@immutable
class StartParking extends ParkingSpaceEvent {
  final int parkingDurationInMinutes;

  const StartParking(this.parkingDurationInMinutes);

  @override
  List<Object> get props => [parkingDurationInMinutes];
}

class StopParking extends ParkingSpaceEvent {
  @override
  List<Object> get props => [];
}

class DeselectParkingSpace extends ParkingSpaceEvent {
  @override
  List<Object> get props => [];
}

class ExtendParking extends ParkingSpaceEvent {
  final int additionalMinutes;

  const ExtendParking({required this.additionalMinutes});

  @override
  List<Object> get props => [additionalMinutes];
}

class ScheduleNotification extends ParkingSpaceEvent {
  final DateTime endTime;

  const ScheduleNotification({required this.endTime});

  @override
  List<Object> get props => [endTime];
}

class ShowExtendTimeDialog extends ParkingSpaceEvent {
  const ShowExtendTimeDialog();

  @override
  List<Object?> get props => [];
}

class RefreshParkingSpaces extends ParkingSpaceEvent {
  @override
  List<Object?> get props => [];
}
