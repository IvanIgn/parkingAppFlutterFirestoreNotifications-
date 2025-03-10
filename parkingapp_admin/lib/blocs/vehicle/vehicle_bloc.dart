import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared/shared.dart';
import 'package:equatable/equatable.dart';

part 'vehicle_event.dart';
part 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository vehicleRepository;

  VehicleBloc(this.vehicleRepository) : super(VehicleInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<AddVehicle>(_onAddVehicle);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      final vehicles = await vehicleRepository.getAllVehicles();
      emit(VehicleLoaded(vehicles));
    } catch (error) {
      emit(VehicleError('Failed to load vehicles: $error'));
    }
  }

  void _onAddVehicle(AddVehicle event, Emitter<VehicleState> emit) async {
    // First, emit the loading state
    emit(VehicleLoading());

    try {
      final newVehicle = event.vehicle;
      //print("Adding vehicle: $newVehicle");

      // Simulate adding the vehicle
      await vehicleRepository.createVehicle(newVehicle);

      // Fetch the updated list after adding the vehicle
      final allVehicles = await vehicleRepository.getAllVehicles();
      //print("All vehicles after addition: $allVehicles");

      // Emit the loaded state with the updated list
      emit(VehicleLoaded(allVehicles));
    } catch (e) {
      // In case of an error, print it and emit the error state
      //print("Error adding vehicle: $e");
      emit(VehicleError('Failed to add vehicle: $e'));
    }
  }

  Future<void> _onUpdateVehicle(
    UpdateVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      await vehicleRepository.updateVehicle(event.vehicle.id, event.vehicle);
      final updatedVehicles = await vehicleRepository.getAllVehicles();
      emit(VehicleUpdated());
      emit(VehicleLoaded(updatedVehicles));
    } catch (error) {
      emit(VehicleError('Error updating vehicle: $error'));
    }
  }

  Future<void> _onDeleteVehicle(
    DeleteVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading()); // Emit loading state

    try {
      await vehicleRepository
          .deleteVehicle(event.vehicleId.toString()); // Call delete
      emit(VehicleDeleted()); // Emit deleted state
      final updatedVehicles =
          await vehicleRepository.getAllVehicles(); // Fetch updated list
      emit(VehicleLoaded(updatedVehicles)); // Emit updated state
    } catch (error) {
      emit(VehicleError('Failed to delete vehicle: $error')); // Handle errors
    }
  }
}
