import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:equatable/equatable.dart';

part 'vehicle_event.dart';
part 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  StreamSubscription<List<Vehicle>>? _vehicleSubscription;
  final VehicleRepository repository;
  List<Vehicle> _vehicleList = [];

  VehicleBloc(this.repository) : super(VehiclesInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<LoadVehiclesByPerson>(_onLoadVehiclesByPerson);
    on<SubscribeToVehicles>(_onSubscribeToVehicles);
    on<UnsubscribeFromVehicles>(_onUnsubscribeFromVehicles);
    on<CreateVehicle>(_onCreateVehicle);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
    on<SelectVehicle>(_onSelectVehicle);

    // Start real-time updates when Bloc initializes
    add(SubscribeToVehicles());
  }

  // 🔹 Subscribe to Firestore real-time updates
  void _onSubscribeToVehicles(
      SubscribeToVehicles event, Emitter<VehicleState> emit) {
    emit(VehiclesLoading());

    _vehicleSubscription?.cancel(); // Cancel previous subscription if any
    _vehicleSubscription = repository.vehicleStream().listen(
      (vehicles) {
        emit(VehiclesLoaded(vehicles: vehicles));
      },
      onError: (error) {
        emit(VehiclesError(message: 'Real-time update error: $error'));
      },
    );
  }

  // 🔹 Unsubscribe from Firestore updates when no longer needed
  void _onUnsubscribeFromVehicles(
      UnsubscribeFromVehicles event, Emitter<VehicleState> emit) {
    _vehicleSubscription?.cancel();
  }

  Future<void> _onLoadVehicles(
      LoadVehicles event, Emitter<VehicleState> emit) async {
    emit(VehiclesLoading());
    try {
      _vehicleList = await repository.getAllVehicles();
      emit(VehiclesLoaded(vehicles: _vehicleList));
    } catch (e) {
      emit(VehiclesError(message: 'Failed to load vehicles: $e'));
    }
  }

  Future<void> _onLoadVehiclesByPerson(
      LoadVehiclesByPerson event, Emitter<VehicleState> emit) async {
    emit(VehiclesLoading());
    try {
      final vehicles = await repository.getVehiclesForUser(event.userId);
      emit(VehiclesLoaded(vehicles: vehicles)); // Emit user-specific vehicles
    } catch (e) {
      emit(VehiclesError(message: 'Failed to load vehicles: $e'));
    }
  }

  // 🔹 Create a new vehicle (Firestore will auto-update via listener)
  Future<void> _onCreateVehicle(
      CreateVehicle event, Emitter<VehicleState> emit) async {
    try {
      await repository.createVehicle(event.vehicle);
    } catch (e) {
      emit(VehiclesError(message: 'Failed to add vehicle: $e'));
    }
  }

  // 🔹 Update an existing vehicle (Firestore will auto-update via listener)
  Future<void> _onUpdateVehicle(
      UpdateVehicle event, Emitter<VehicleState> emit) async {
    try {
      await repository.updateVehicle(event.vehicle.id, event.vehicle);
    } catch (e) {
      emit(VehiclesError(message: 'Failed to update vehicle: $e'));
    }
  }

  // 🔹 Delete a vehicle (Firestore will auto-update via listener)
  Future<void> _onDeleteVehicle(
      DeleteVehicle event, Emitter<VehicleState> emit) async {
    try {
      await repository.deleteVehicle(event.vehicle.id);
    } catch (e) {
      emit(VehiclesError(message: 'Failed to delete vehicle: $e'));
    }
  }

  // 🔹 Select a vehicle and store in SharedPreferences
  Future<void> _onSelectVehicle(
      SelectVehicle event, Emitter<VehicleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final currentState = state;

    if (currentState is VehiclesLoaded) {
      final isSameVehicle =
          currentState.selectedVehicle?.id == event.vehicle.id;

      if (isSameVehicle) {
        await prefs.remove('selectedVehicle');
        emit(VehiclesLoaded(
            vehicles: currentState.vehicles, selectedVehicle: null));
      } else {
        final selectedVehicle = currentState.vehicles.firstWhere(
            (vehicle) => vehicle.id == event.vehicle.id,
            orElse: () => event.vehicle);

        final vehicleJson = json.encode(selectedVehicle.toJson());
        await prefs.setString('selectedVehicle', vehicleJson);
        emit(VehiclesLoaded(
            vehicles: currentState.vehicles, selectedVehicle: selectedVehicle));
      }
    }
  }

  // 🔹 Cleanup: Stop listening when Bloc is closed
  @override
  Future<void> close() {
    _vehicleSubscription?.cancel();
    return super.close();
  }
}
