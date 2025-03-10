part of 'parking_space_bloc.dart';

abstract class ParkingSpaceState extends Equatable {
  const ParkingSpaceState();

  @override
  List<Object> get props => [];
}

class ParkingSpaceLoading extends ParkingSpaceState {}

class ParkingSpaceLoaded extends ParkingSpaceState {
  final List<ParkingSpace> parkingSpaces;

  const ParkingSpaceLoaded(this.parkingSpaces);

  @override
  List<Object> get props => [parkingSpaces];
}

class ParkingSpaceError extends ParkingSpaceState {
  final String message;

  const ParkingSpaceError(this.message);

  @override
  List<Object> get props => [message];
}

class ParkingSpaceUpdated extends ParkingSpaceState {}

class ParkingSpaceAdded extends ParkingSpaceState {} // New state for addition

class ParkingSpaceDeleted extends ParkingSpaceState {} // New state for deletion
