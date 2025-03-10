import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:clock/clock.dart';
import 'dart:convert';

part 'parking_event.dart';
part 'parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final ParkingRepository parkingRepository;
  final SharedPreferences sharedPreferences;
  List<Parking> _parkingList = [];
  final List<Person> _personList = [];

  ParkingBloc(
      {required this.parkingRepository, required this.sharedPreferences})
      : super(ParkingsInitial()) {
    on<LoadParkings>((event, emit) async {
      await onLoadParkings(emit);
    });

    on<LoadActiveParkings>((event, emit) async {
      await onLoadActiveParkings(emit);
    });

    on<LoadNonActiveParkings>((event, emit) async {
      await onLoadNonActiveParkings(emit);
    });

    on<DeleteParking>((event, emit) async {
      await onDeleteParking(emit, event.parking);
    });

    on<CreateParking>((event, emit) async {
      await onCreateParking(emit, event.parking);
    });

    on<UpdateParking>((event, emit) async {
      await onUpdateParking(emit, event.parking);
    });

    on<LoadParkingByPersonEmail>((event, emit) async {
      await onLoadParkingByPersonEmail(event, emit);
    });
  }

  Future<void> onLoadActiveParkings(Emitter<ParkingState> emit) async {
    emit(ParkingsLoading());
    try {
      // Retrieve logged-in user's ID from SharedPreferences
      final loggedInPersonJson = sharedPreferences.getString('loggedInPerson');

      if (loggedInPersonJson == null) {
        throw Exception("Failed to load active parkings");
      }

      final loggedInPersonMap =
          json.decode(loggedInPersonJson) as Map<String, dynamic>;
      final loggedInUserEmail = loggedInPersonMap['email'];

      // Fetch all parkings from repository
      _parkingList = await parkingRepository.getAllParkings();

      // Filter only active parkings added by the logged-in user
      List<Parking> activeParkings = _parkingList
          .where(
            (parking) =>
                parking.vehicle?.owner?.email ==
                    loggedInUserEmail && // Filter by logged-in user
                parking.endTime.isAfter(
                    DateTime.now()), // Check if parking is still active
          )
          .toList();

      emit(ActiveParkingsLoaded(parkings: activeParkings));
    } catch (e) {
      emit(ParkingsError(message: e.toString()));
    }
  }

  Future<void> onLoadParkingByPersonEmail(
      LoadParkingByPersonEmail event, Emitter<ParkingState> emit) async {
    emit(ParkingsLoading());
    try {
      final parkings =
          await parkingRepository.getParkingByUserEmail(event.userEmail);
      emit(ParkingsLoaded(parkings: parkings)); // Emit user-specific vehicles
    } catch (e) {
      emit(ParkingsError(message: 'Failed to load parkings: $e'));
    }
  }

  Future<void> onLoadParkings(Emitter<ParkingState> emit) async {
    emit(ParkingsLoading());
    try {
      _parkingList = await parkingRepository.getAllParkings();
      emit(ParkingsLoaded(parkings: _parkingList));
    } catch (e) {
      emit(ParkingsError(message: e.toString()));
    }
  }

  Future<void> onLoadNonActiveParkings(Emitter<ParkingState> emit) async {
    emit(ParkingsLoading());
    try {
      _parkingList = await parkingRepository.getAllParkings();

      List<Parking> nonActiveParkings = _parkingList
          .where((parking) => parking.endTime.isBefore(clock.now()))
          .toList();

      emit(ParkingsLoaded(parkings: nonActiveParkings));
    } catch (e) {
      emit(ParkingsError(message: e.toString()));
    }
  }

  onCreateParking(Emitter<ParkingState> emit, Parking parking) async {
    emit(ParkingsLoading()); // Emit loading state
    try {
      // emit(ParkingsLoading());
      await parkingRepository.createParking(parking);

      // Fetch all parkings from the repository
      final allParkings = await parkingRepository.getAllParkings();

      // Filter active parkings
      final activeParkings =
          allParkings.where((p) => p.endTime.isAfter(DateTime.now())).toList();

      // Emit loaded state with active parkings
      emit(ActiveParkingsLoaded(parkings: activeParkings));
    } catch (e) {
      // Emit an error state if something goes wrong
      emit(ParkingsError(message: e.toString()));
    }
  }

  onUpdateParking(Emitter<ParkingState> emit, Parking parking) async {
    try {
      await parkingRepository.updateParking(parking.id, parking);
      add(LoadActiveParkings());
    } catch (e) {
      // Modify error message to match the expected format
      emit(ParkingsError(
          message: 'Failed to edit parking. Details: ${e.toString()}'));
    }
  }

  onDeleteParking(Emitter<ParkingState> emit, Parking parking) async {
    try {
      // Try to delete parking
      await parkingRepository.deleteParking(parking.id);

      // Emit loading state only if the delete operation is successful
      emit(ParkingsLoading());

      // After successful deletion, fetch the updated list of parkings
      final allParkings = await parkingRepository.getAllParkings();
      emit(ParkingsLoaded(parkings: allParkings));
    } catch (e) {
      // If an error occurs, directly emit the error state without loading state
      emit(ParkingsError(
          message: 'Failed to delete parking. Details: ${e.toString()}'));
    }
  }
}
