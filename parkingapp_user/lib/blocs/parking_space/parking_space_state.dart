part of 'parking_space_bloc.dart';

abstract class ParkingSpaceState extends Equatable {
  const ParkingSpaceState();

  @override
  List<Object?> get props => [];
}

// Initial state when no parking data is available
class ParkingSpaceInitial extends ParkingSpaceState {}

class ParkingSpaceLoading extends ParkingSpaceState {}

class ParkingSpaceLoaded extends ParkingSpaceState {
  final List<ParkingSpace> parkingSpaces;
  final ParkingSpace? selectedParkingSpace;
  final bool isParkingActive;

  const ParkingSpaceLoaded({
    required this.parkingSpaces,
    this.selectedParkingSpace,
    this.isParkingActive = false,
  });

  @override
  List<Object?> get props =>
      [parkingSpaces, selectedParkingSpace, isParkingActive];
}

class ParkingSpaceError extends ParkingSpaceState {
  final String message;

  const ParkingSpaceError(this.message);

  @override
  List<Object?> get props => [message];
}

// State indicating that parking spaces have been successfully loaded
// class ParkingSpacesLoaded extends ParkingSpaceState {
//   final List<ParkingSpace> parkingSpaces;
//   final ParkingSpace? selectedParkingSpace; // Include selectedParkingSpace here
//   final bool? isActive; // Add isActive to the loaded state

//   ParkingSpacesLoaded({
//     required this.parkingSpaces,
//     this.selectedParkingSpace,
//     this.isActive, // Carry the active status when spaces are loaded
//   });
// }

// // State indicating an error occurred while loading parking spaces
// class ParkingSpacesError extends ParkingSpaceState {
//   final String message;

//   ParkingSpacesError({required this.message});
// }

// // State indicating a parking space has been selected
// class ParkingSpaceSelected extends ParkingSpaceState {
//   final ParkingSpace parkingSpace;

//   ParkingSpaceSelected({required this.parkingSpace});
// }

// // State indicating the selected parking space has been cleared
// class ParkingSpaceSelectionCleared extends ParkingSpaceState {}

// // State indicating that parking has started
// class ParkingSpaceStarted extends ParkingSpaceState {
//   final ParkingSpace
//       selectedParkingSpace; // Selected parking space when parking starts
//   final List<ParkingSpace> parkingSpaces; // List of all parking spaces

//   ParkingSpaceStarted({
//     required this.selectedParkingSpace,
//     required this.parkingSpaces,
//   });
// }

// // State indicating that parking has stopped
// class ParkingSpaceStopped extends ParkingSpaceState {
//   ParkingSpaceStopped();
// }

// // State indicating the parking session has been toggled (started or stopped)
// class ParkingStateToggled extends ParkingSpaceState {
//   final bool isActive;

//   ParkingStateToggled({required this.isActive});
//}
