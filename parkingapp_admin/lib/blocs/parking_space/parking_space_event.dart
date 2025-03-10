part of 'parking_space_bloc.dart';

abstract class ParkingSpaceEvent extends Equatable {
  const ParkingSpaceEvent();

  @override
  List<Object> get props => [];
}

class LoadParkingSpaces extends ParkingSpaceEvent {
  const LoadParkingSpaces();
}

class AddParkingSpace extends ParkingSpaceEvent {
  final ParkingSpace parkingSpace;

  const AddParkingSpace(this.parkingSpace);

  @override
  List<Object> get props => [parkingSpace];
}

class UpdateParkingSpace extends ParkingSpaceEvent {
  final ParkingSpace parkingSpace;

  const UpdateParkingSpace(this.parkingSpace);

  @override
  List<Object> get props => [parkingSpace];
}

class DeleteParkingSpace extends ParkingSpaceEvent {
  final String parkingSpaceId;

  const DeleteParkingSpace(this.parkingSpaceId);

  @override
  List<Object> get props => [parkingSpaceId];
}
