part of 'parking_space_bloc.dart';

abstract class ParkingSpaceEvent extends Equatable {
  const ParkingSpaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadParkingSpaces extends ParkingSpaceEvent {}

class SelectParkingSpace extends ParkingSpaceEvent {
  final ParkingSpace parkingSpace;

  const SelectParkingSpace(this.parkingSpace);

  @override
  List<Object?> get props => [parkingSpace];
}

class StartParking extends ParkingSpaceEvent {}

class StopParking extends ParkingSpaceEvent {}

class DeselectParkingSpace extends ParkingSpaceEvent {}

// class CreateParkingSpace extends ParkingSpaceEvent {
//   final ParkingSpace parkingSpace;

//   CreateParkingSpace({required this.parkingSpace});
// }

// class UpdateParkingSpace extends ParkingSpaceEvent {
//   final ParkingSpace parkingSpace;

//   UpdateParkingSpace({required this.parkingSpace});
// }

// class DeleteParkingSpace extends ParkingSpaceEvent {
//   final ParkingSpace parkingSpace;

//   DeleteParkingSpace({required this.parkingSpace});
// }

// class SelectParkingSpace extends ParkingSpaceEvent {
//   final ParkingSpace parkingSpace;

//   SelectParkingSpace({required this.parkingSpace});
// }

// class ClearSelectedParkingSpace extends ParkingSpaceEvent {}

// class ToggleParkingState extends ParkingSpaceEvent {}

// class StartParking extends ParkingSpaceEvent {}

// class StopParking extends ParkingSpaceEvent {}
