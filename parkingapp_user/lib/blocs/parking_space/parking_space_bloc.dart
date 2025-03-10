import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

part 'parking_space_event.dart';
part 'parking_space_state.dart';

class ParkingSpaceBloc extends Bloc<ParkingSpaceEvent, ParkingSpaceState> {
  final ParkingSpaceRepository parkingSpaceRepository;
  final PersonRepository personRepository;
  final ParkingRepository parkingRepository;
  final VehicleRepository vehicleRepository;
  ParkingSpaceBloc(
      {required this.parkingSpaceRepository,
      required this.parkingRepository,
      required this.personRepository,
      required this.vehicleRepository})
      : super(ParkingSpaceInitial()) {
    on<LoadParkingSpaces>(_onLoadParkingSpaces);
    on<SelectParkingSpace>(_onSelectParkingSpace);
    on<StartParking>(_onStartParking);
    on<StopParking>(_onStopParking);
    on<DeselectParkingSpace>(_onDeselectParkingSpace);
  }

  Future<void> _onLoadParkingSpaces(
    LoadParkingSpaces event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    emit(ParkingSpaceLoading());
    try {
      final parkingSpaces = await parkingSpaceRepository.getAllParkingSpaces();
      final prefs = await SharedPreferences.getInstance();

      // Load selected parking space safely
      final selectedParkingSpaceJson = prefs.getString('selectedParkingSpace');
      ParkingSpace? selectedParkingSpace;

      if (selectedParkingSpaceJson != null &&
          selectedParkingSpaceJson.isNotEmpty) {
        try {
          final decodedJson = json.decode(selectedParkingSpaceJson);
          final parsedSpace = ParkingSpace.fromJson(decodedJson);

          if (parkingSpaces.any((space) => space.id == parsedSpace.id)) {
            selectedParkingSpace = parsedSpace;
          }
        } catch (e) {
          debugPrint('Error decoding selectedParkingSpace JSON: $e');
        }
      }

      // Load active parking state safely
      final isParkingActive = prefs.getBool('isParkingActive') ?? false;

      emit(ParkingSpaceLoaded(
        parkingSpaces: parkingSpaces,
        selectedParkingSpace: selectedParkingSpace,
        isParkingActive: isParkingActive,
      ));
    } catch (e) {
      debugPrint('Error loading parking spaces: $e'); // Log the error
      emit(ParkingSpaceError(e.toString()));
    }
  }

  Future<void> _onSelectParkingSpace(
    SelectParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final parkingSpaceJson = json.encode(event.parkingSpace.toJson());
    await prefs.setString('selectedParkingSpace', parkingSpaceJson);
    final selectedVehicleJson = prefs.getString('selectedVehicle');

    if (state is ParkingSpaceLoaded) {
      final currentState = state as ParkingSpaceLoaded;
      emit(ParkingSpaceLoaded(
        parkingSpaces: currentState.parkingSpaces,
        selectedParkingSpace: event.parkingSpace,
        isParkingActive: currentState.isParkingActive,
      ));
    }
  }

  Future<void> _onDeselectParkingSpace(
    DeselectParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear the selected parking space from shared preferences
    await prefs.remove('selectedParkingSpace');

    if (state is ParkingSpaceLoaded) {
      final currentState = state as ParkingSpaceLoaded;

      // Emit a new state with `selectedParkingSpace` set to null
      emit(ParkingSpaceLoaded(
        parkingSpaces: currentState.parkingSpaces,
        selectedParkingSpace: null,
        isParkingActive: currentState.isParkingActive,
      ));
    }
  }

  Future<Map<String, dynamic>> _loadParkingData(SharedPreferences prefs) async {
    final selectedParkingSpaceJson = prefs.getString('selectedParkingSpace');
    final selectedVehicleJson = prefs.getString('selectedVehicle');

    if (selectedParkingSpaceJson == null || selectedVehicleJson == null) {
      throw Exception("Missing parking or vehicle data in SharedPreferences.");
    }

    try {
      final selectedParkingSpace =
          ParkingSpace.fromJson(json.decode(selectedParkingSpaceJson));
      final selectedVehicle =
          Vehicle.fromJson(json.decode(selectedVehicleJson));

      return {
        'parkingSpace': selectedParkingSpace,
        'vehicle': selectedVehicle,
      };
    } catch (e) {
      throw Exception("Error parsing parking or vehicle data: $e");
    }
  }

  Future<void> _onStartParking(
    StartParking event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final loggedInPersonJson = prefs.getString('loggedInPerson');
      if (loggedInPersonJson == null) {
        throw Exception("Missing logged-in person data in SharedPreferences.");
      }

      // Create logged-in person object
      final loggedInPersonMap =
          json.decode(loggedInPersonJson) as Map<String, dynamic>;
      final loggedInPerson = Person(
        id: loggedInPersonMap['id'],
        name: loggedInPersonMap['name'],
        personNumber: loggedInPersonMap['personNumber'],
        email: loggedInPersonMap['email'],
        authId: loggedInPersonMap['authId'],
      );

      // Helper method to load selected parking space and vehicle
      final parkingData = await _loadParkingData(prefs);
      final selectedParkingSpace = parkingData['parkingSpace'] as ParkingSpace;
      final selectedVehicle = parkingData['vehicle'] as Vehicle;

      // Debug logs
      debugPrint('Selected Parking Space: $selectedParkingSpace');
      debugPrint('Selected Vehicle: $selectedVehicle');

      final parkingInstance = Parking(
        // id: "",
        vehicle: selectedVehicle.copyWith(owner: loggedInPerson),
        parkingSpace: selectedParkingSpace,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      );

// Save to the database
      final createdParking =
          await parkingRepository.createParking(parkingInstance);

// Fetch the parking again using the actual assigned ID
      final allParkings = await parkingRepository.getAllParkings();
      final exactParking = allParkings.firstWhere(
        (parking) => parking.id == createdParking.id,
        orElse: () => throw Exception("Parking not found"),
      );

      debugPrint(
          "Exact parking retrieved: ${json.encode(exactParking.toJson())}");

      // Store the parking data in SharedPreferences
      await prefs.setString('parking', json.encode(exactParking.toJson()));
      await prefs.setString(
          'activeParkingSpace', json.encode(selectedParkingSpace.toJson()));
      await prefs.setBool('isParkingActive', true);

      // Attempt to create parking in the repository

      // Emit the updated state after parking starts
      if (state is ParkingSpaceLoaded) {
        final currentState = state as ParkingSpaceLoaded;
        emit(ParkingSpaceLoaded(
          parkingSpaces: currentState.parkingSpaces,
          selectedParkingSpace: selectedParkingSpace,
          isParkingActive: true,
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _onStartParking: $e');
      debugPrint(stackTrace.toString());
      emit(ParkingSpaceError('Error starting parking: ${e.toString()}'));
    }
  }

  Future<void> _onStopParking(
    StopParking event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final parkingJson = prefs.getString('parking');

    if (parkingJson != null) {
      final parkingInstance = Parking.fromJson(json.decode(parkingJson));
      await parkingRepository.deleteParking(parkingInstance.id);

      await prefs.remove('isParkingActive');
      await prefs.remove('parking');
    }

    // Ensure a new state is emitted no matter what
    if (state is ParkingSpaceLoaded) {
      final currentState = state as ParkingSpaceLoaded;
      emit(ParkingSpaceLoaded(
        parkingSpaces: currentState.parkingSpaces,
        selectedParkingSpace: null,
        isParkingActive: false,
      ));
    }
  }
}
