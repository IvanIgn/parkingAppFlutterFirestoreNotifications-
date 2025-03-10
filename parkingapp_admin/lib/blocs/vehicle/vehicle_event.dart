part of 'vehicle_bloc.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

// Event to load all vehicles
class LoadVehicles extends VehicleEvent {
  const LoadVehicles();
}

// Event to add a new vehicle
class AddVehicle extends VehicleEvent {
  final Vehicle vehicle;

  const AddVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

// Event to update an existing vehicle
class UpdateVehicle extends VehicleEvent {
  final Vehicle vehicle;

  const UpdateVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

// Event to delete a vehicle by its ID
class DeleteVehicle extends VehicleEvent {
  final String vehicleId;

  const DeleteVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}
