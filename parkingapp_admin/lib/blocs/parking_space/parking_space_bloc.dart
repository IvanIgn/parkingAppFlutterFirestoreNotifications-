import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared/shared.dart';

part 'parking_space_event.dart';
part 'parking_space_state.dart';

class ParkingSpaceBloc extends Bloc<ParkingSpaceEvent, ParkingSpaceState> {
  final ParkingSpaceRepository parkingSpaceRepository;

  ParkingSpaceBloc(this.parkingSpaceRepository) : super(ParkingSpaceLoading()) {
    on<LoadParkingSpaces>(_onLoadParkingSpaces);
    on<AddParkingSpace>(_onAddParkingSpace);
    on<UpdateParkingSpace>(_onUpdateParkingSpace);
    on<DeleteParkingSpace>(_onDeleteParkingSpace);
  }

  Future<void> _onLoadParkingSpaces(
    LoadParkingSpaces event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    emit(ParkingSpaceLoading());
    try {
      final parkingSpaces = await parkingSpaceRepository.getAllParkingSpaces();
      emit(ParkingSpaceLoaded(parkingSpaces));
    } catch (e) {
      emit(const ParkingSpaceError("Failed to load parking spaces."));
    }
  }

  Future<void> _onAddParkingSpace(
    AddParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    emit(ParkingSpaceLoading()); // Emit a loading state
    try {
      await parkingSpaceRepository.createParkingSpace(event.parkingSpace);
      final parkingSpaces = await parkingSpaceRepository.getAllParkingSpaces();
      emit(ParkingSpaceLoaded(parkingSpaces)); // Emit the updated state
    } catch (error) {
      emit(ParkingSpaceError('Failed to add parking space: $error'));
    }
  }

  Future<void> _onUpdateParkingSpace(
    UpdateParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    emit(ParkingSpaceLoading()); // Emit loading state
    try {
      // Attempt to update the parking space in the repository
      await parkingSpaceRepository.updateParkingSpace(
        event.parkingSpace.id,
        event.parkingSpace,
      );

      // Emit the ParkingSpaceUpdated state
      emit(ParkingSpaceUpdated());

      // Fetch the current list of parking spaces from the state or repository
      final updatedSpaces = await parkingSpaceRepository.getAllParkingSpaces();

      // Emit the updated parking spaces
      emit(ParkingSpaceLoaded(updatedSpaces));
    } catch (error) {
      // Emit an error if something goes wrong
      emit(ParkingSpaceError(
          'Error updating parking space: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteParkingSpace(
      DeleteParkingSpace event, Emitter<ParkingSpaceState> emit) async {
    emit(ParkingSpaceLoading()); // Emit loading state first
    try {
      await parkingSpaceRepository
          .deleteParkingSpace(event.parkingSpaceId.toString());
      emit(ParkingSpaceDeleted()); // Emit deleted state after deletion
      // Optionally fetch the updated list of parking spaces
      final updatedParkingSpaces =
          await parkingSpaceRepository.getAllParkingSpaces();
      emit(ParkingSpaceLoaded(
          updatedParkingSpaces)); // Emit loaded state with updated list
    } catch (e) {
      emit(ParkingSpaceError(
          "Failed to delete parking space: $e")); // Emit error state if something goes wrong
    }
  }
}
