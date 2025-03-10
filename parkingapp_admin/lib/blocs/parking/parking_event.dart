// parking_event.dart

part of 'parking_bloc.dart';

abstract class MonitorParkingsEvent {}

class LoadParkingsEvent extends MonitorParkingsEvent {
  LoadParkingsEvent();
}

class AddParkingEvent extends MonitorParkingsEvent {
  final Parking parking;

  AddParkingEvent(this.parking);
}

class EditParkingEvent extends MonitorParkingsEvent {
  final String parkingId;
  final Parking parking;

  EditParkingEvent({required this.parkingId, required this.parking});
}

class DeleteParkingEvent extends MonitorParkingsEvent {
  final String parkingId;

  DeleteParkingEvent(this.parkingId);
}
