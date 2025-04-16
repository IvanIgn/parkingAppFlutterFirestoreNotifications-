// monitor_parkings_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:equatable/equatable.dart';

part 'parking_event.dart';
part 'parking_state.dart';

class ParkingsBloc extends Bloc<MonitorParkingsEvent, MonitorParkingsState> {
  final ParkingRepository parkingRepository;

  ParkingsBloc({required this.parkingRepository})
      : super(MonitorParkingsInitialState()) {
    on<LoadParkingsEvent>(_onLoadParkingsEvent);
    on<AddParkingEvent>(_onAddParkingEvent);
    on<EditParkingEvent>(_onEditParkingEvent);
    on<DeleteParkingEvent>(_onDeleteParkingEvent);
  }

  Future<void> _onLoadParkingsEvent(
    LoadParkingsEvent event,
    Emitter<MonitorParkingsState> emit,
  ) async {
    emit(MonitorParkingsLoadingState());
    try {
      final parkings = await parkingRepository.getAllParkings();
      emit(MonitorParkingsLoadedState(parkings));
    } catch (e) {
      emit(MonitorParkingsErrorState(
          'Failed to load parkings. Details: ${e.toString()}'));
    }
  }

  Future<void> _onAddParkingEvent(
    AddParkingEvent event,
    Emitter<MonitorParkingsState> emit,
  ) async {
    emit(MonitorParkingsLoadingState()); // Emit a loading state
    try {
      await parkingRepository.createParking(event.parking);
      final parkings = await parkingRepository.getAllParkings();
      emit(MonitorParkingsLoadedState(parkings)); // Emit the updated state
    } catch (error) {
      emit(MonitorParkingsErrorState('Failed to add parking: $error'));
    }
  }

  Future<void> _onEditParkingEvent(
    EditParkingEvent event,
    Emitter<MonitorParkingsState> emit,
  ) async {
    try {
      await parkingRepository.updateParking(
          event.parkingId.toString(), event.parking);
      add(LoadParkingsEvent());
    } catch (e) {
      emit(MonitorParkingsErrorState(
          'Failed to edit parking. Details: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteParkingEvent(
    DeleteParkingEvent event,
    Emitter<MonitorParkingsState> emit,
  ) async {
    try {
      await parkingRepository.deleteParking(event.parkingId.toString());
      add(LoadParkingsEvent());
    } catch (e) {
      emit(MonitorParkingsErrorState(
          'Failed to delete parking. Details: ${e.toString()}'));
    }
  }
}

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_repositories/firebase_repositories.dart';
// import 'package:bloc/bloc.dart';
// import 'package:shared/shared.dart';
// import 'package:equatable/equatable.dart';

// part 'parking_event.dart';
// part 'parking_state.dart';

// class ParkingsBloc extends Bloc<MonitorParkingsEvent, MonitorParkingsState> {
//   final ParkingRepository parkingRepository;
//   final NotificationRepository notificationRepository;

//   ParkingsBloc({
//     required this.parkingRepository,
//     required this.notificationRepository,
//   }) : super(MonitorParkingsInitialState()) {
//     on<LoadParkingsEvent>(_onLoadParkingsEvent);
//     on<AddParkingEvent>(_onAddParkingEvent);
//     on<EditParkingEvent>(_onEditParkingEvent);
//     on<DeleteParkingEvent>(_onDeleteParkingEvent);
//   }

//   Future<void> _onLoadParkingsEvent(
//     LoadParkingsEvent event,
//     Emitter<MonitorParkingsState> emit,
//   ) async {
//     emit(MonitorParkingsLoadingState());
//     try {
//       final parkings = await parkingRepository.getAllParkings();
//       emit(MonitorParkingsLoadedState(parkings));
//     } catch (e) {
//       emit(MonitorParkingsErrorState(
//           'Failed to load parkings. Details: ${e.toString()}'));
//     }
//   }

//   Future<void> _onAddParkingEvent(
//     AddParkingEvent event,
//     Emitter<MonitorParkingsState> emit,
//   ) async {
//     emit(MonitorParkingsLoadingState());
//     try {
//       await parkingRepository.createParking(event.parking);
//       final parkings = await parkingRepository.getAllParkings();
//       emit(MonitorParkingsLoadedState(parkings));

//       // Skapa en notifikation för parkeringen
//       await notificationRepository.scheduleNotification(
//         id: event.parking.id.hashCode,
//         title: "Parkeringstid på väg att löpa ut",
//         content:
//             "Din parkering vid ${event.parking.location} går ut om 10 minuter.",
//         endTime: event.parking.endTime,
//       );
//     } catch (error) {
//       emit(MonitorParkingsErrorState('Failed to add parking: $error'));
//     }
//   }

//   Future<void> _onEditParkingEvent(
//     EditParkingEvent event,
//     Emitter<MonitorParkingsState> emit,
//   ) async {
//     try {
//       await parkingRepository.updateParking(
//           event.parkingId.toString(), event.parking);
//       add(LoadParkingsEvent());

//       // Uppdatera notifikationen med det nya slutdatumet
//       await notificationRepository.scheduleNotification(
//         id: event.parkingId.hashCode,
//         title: "Parkeringstid uppdaterad",
//         content:
//             "Din parkering vid ${event.parking.location} har nu en ny sluttid.",
//         endTime: event.parking.endTime,
//       );
//     } catch (e) {
//       emit(MonitorParkingsErrorState(
//           'Failed to edit parking. Details: ${e.toString()}'));
//     }
//   }

//   Future<void> _onDeleteParkingEvent(
//     DeleteParkingEvent event,
//     Emitter<MonitorParkingsState> emit,
//   ) async {
//     try {
//       await parkingRepository.deleteParking(event.parkingId.toString());
//       add(LoadParkingsEvent());

//       // Avbryt schemalagd notifikation
//       await notificationRepository.cancelNotification(event.parkingId.hashCode);
//     } catch (e) {
//       emit(MonitorParkingsErrorState(
//           'Failed to delete parking. Details: ${e.toString()}'));
//     }
//   }
// }
