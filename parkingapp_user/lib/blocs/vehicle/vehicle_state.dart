part of 'vehicle_bloc.dart';

abstract class VehicleState extends Equatable {
  const VehicleState();

  @override
  List<Object?> get props => [];
}

class VehiclesInitial extends VehicleState {}

class VehiclesLoading extends VehicleState {}

class VehiclesLoaded extends VehicleState {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;

  const VehiclesLoaded({required this.vehicles, this.selectedVehicle});

  @override
  List<Object?> get props => [vehicles, selectedVehicle];
}

class VehiclesError extends VehicleState {
  final String message;

  const VehiclesError({required this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'VehiclesError($message)';
}

class VehicleAdded extends VehicleState {
  final Vehicle vehicle;

  const VehicleAdded({required this.vehicle});

  @override
  List<Object> get props => [vehicle];
}

class VehicleUpdated extends VehicleState {
  final Vehicle vehicle;

  const VehicleUpdated({required this.vehicle});

  @override
  List<Object> get props => [vehicle];
}

class VehicleDeleted extends VehicleState {
  final Vehicle vehicle;

  const VehicleDeleted({required this.vehicle});

  @override
  List<Object> get props => [vehicle];
}
