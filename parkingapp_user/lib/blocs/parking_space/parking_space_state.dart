// parking_space_state.dart
part of 'parking_space_bloc.dart';

abstract class ParkingSpaceState extends Equatable {
  const ParkingSpaceState();

  @override
  List<Object?> get props => [];
}

class ParkingSpaceInitial extends ParkingSpaceState {}

class ParkingSpaceLoading extends ParkingSpaceState {}

class ParkingSpaceError extends ParkingSpaceState {
  final String message;

  const ParkingSpaceError(this.message);

  @override
  List<Object?> get props => [message];
}

class ParkingEnded extends ParkingSpaceState {
  final int totalMinutes;
  final double totalPrice;
  final Parking parking;

  const ParkingEnded({
    required this.totalMinutes,
    required this.totalPrice,
    required this.parking,
  });

  @override
  List<Object?> get props => [totalMinutes, totalPrice, parking];
}

class ParkingExtensionSuccess extends ParkingSpaceState {
  final int extendedMinutes;

  const ParkingExtensionSuccess(this.extendedMinutes);

  @override
  List<Object?> get props => [extendedMinutes];
}

class ParkingSpaceLoaded extends ParkingSpaceState {
  final List<ParkingSpace> parkingSpaces; // Define parkingSpaces
  final ParkingSpace? selectedParkingSpace; // Add selectedParkingSpace
  final bool isParkingActive; // Add isParkingActive
  final bool refreshTrigger;
  final DateTime? endTime; // Add endTime property
  final int? updateTime;

  // Add refreshTrigger to props
  @override
  List<Object?> get props => [
        parkingSpaces,
        selectedParkingSpace,
        isParkingActive,
        endTime,
        refreshTrigger,
        updateTime,
      ];

  const ParkingSpaceLoaded({
    required this.isParkingActive,
    required this.parkingSpaces,
    this.selectedParkingSpace,
    this.refreshTrigger = false,
    this.endTime, // Initialize endTime
    this.updateTime,
  });

  ParkingSpaceLoaded copyWith({
    List<ParkingSpace>? parkingSpaces,
    ParkingSpace? selectedParkingSpace,
    bool? isParkingActive,
    DateTime? endTime,
    bool? refreshTrigger,
    int? updateTime,
  }) {
    return ParkingSpaceLoaded(
      isParkingActive: isParkingActive ?? this.isParkingActive,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      selectedParkingSpace: selectedParkingSpace ?? this.selectedParkingSpace,
      endTime: endTime ?? this.endTime,
      refreshTrigger: refreshTrigger ?? this.refreshTrigger,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}

class ParkingSpaceExtendDialog extends ParkingSpaceState {
  // You can include extra information if needed.
  const ParkingSpaceExtendDialog();

  @override
  List<Object?> get props => [];
}
