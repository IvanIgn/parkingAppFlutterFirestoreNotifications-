import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:clock/clock.dart';
import 'dart:convert';
import 'package:parkingapp_user/blocs/notifications/notification_bloc.dart'; // Adjust import as needed

part 'parking_event.dart';
part 'parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final ParkingRepository parkingRepository;
  final SharedPreferences sharedPreferences;
  final NotificationBloc notificationBloc; // New dependency

  List<Parking> _parkingList = [];
  final List<Person> _personList = [];

  ParkingBloc({
    required this.parkingRepository,
    required this.sharedPreferences,
    required this.notificationBloc, // Injected here
  }) : super(ParkingsInitial()) {
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
      // Retrieve logged-in person's info from SharedPreferences
      final loggedInPersonJson = sharedPreferences.getString('loggedInPerson');
      if (loggedInPersonJson == null) {
        throw Exception("Failed to load active parkings");
      }
      final loggedInPersonMap =
          json.decode(loggedInPersonJson) as Map<String, dynamic>;
      final loggedInUserEmail = loggedInPersonMap['email'];

      // Fetch all parkings from repository
      _parkingList = await parkingRepository.getAllParkings();

      // Filter only active parkings for the logged-in user
      List<Parking> activeParkings = _parkingList
          .where(
            (parking) =>
                parking.vehicle?.owner?.email == loggedInUserEmail &&
                parking.endTime.isAfter(DateTime.now()),
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
      emit(ParkingsLoaded(parkings: parkings));
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

  Future<void> onCreateParking(
      Emitter<ParkingState> emit, Parking parking) async {
    emit(ParkingsLoading());
    try {
      await parkingRepository.createParking(parking);

      // Dispatch event to schedule notification 10 minutes before parking ends.
      notificationBloc.add(
        ScheduleNotification(
          id: int.parse(parking.id), // Convert parking id to int
          title: "Parkeringstid snart slut",
          content: "Din parkering slutar om 10 minuter.",
          deliveryTime: parking.endTime,
        ),
      );

      // Fetch updated list of active parkings.
      final allParkings = await parkingRepository.getAllParkings();
      final activeParkings =
          allParkings.where((p) => p.endTime.isAfter(DateTime.now())).toList();
      emit(ActiveParkingsLoaded(parkings: activeParkings));
    } catch (e) {
      emit(ParkingsError(message: e.toString()));
    }
  }

  Future<void> onUpdateParking(
      Emitter<ParkingState> emit, Parking parking) async {
    try {
      await parkingRepository.updateParking(parking.id, parking);

      // Cancel the old notification and schedule a new one with updated end time.
      notificationBloc.add(CancelNotification(id: int.parse(parking.id)));
      notificationBloc.add(
        ScheduleNotification(
          id: int.parse(parking.id),
          title: "Parkeringstid uppdaterad",
          content: "Din parkering slutar om 10 minuter.",
          deliveryTime: parking.endTime,
        ),
      );

      add(LoadActiveParkings());
    } catch (e) {
      emit(ParkingsError(
          message: 'Failed to edit parking. Details: ${e.toString()}'));
    }
  }

  Future<void> onDeleteParking(
      Emitter<ParkingState> emit, Parking parking) async {
    try {
      await parkingRepository.deleteParking(parking.id);

      // Cancel the scheduled notification.
      notificationBloc.add(CancelNotification(id: int.parse(parking.id)));

      emit(ParkingsLoading());
      final allParkings = await parkingRepository.getAllParkings();
      emit(ParkingsLoaded(parkings: allParkings));
    } catch (e) {
      emit(ParkingsError(
          message: 'Failed to delete parking. Details: ${e.toString()}'));
    }
  }
}
