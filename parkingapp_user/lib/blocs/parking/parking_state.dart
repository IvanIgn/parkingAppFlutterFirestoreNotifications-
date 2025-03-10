// part of 'parking_bloc.dart';

// sealed class ParkingState {}

// class ParkingInitial extends ParkingState {
//   List<Object?> get parkings => [];
// }

// class ParkingsLoading extends ParkingState {
//   List<Object?> get parkings => [];
// }

// class ParkingsLoaded extends ParkingState {
//   final List<Parking> parkings;

//   ParkingsLoaded({required this.parkings});
// }

// class ParkingsError extends ParkingState {
//   final String message;

//   ParkingsError({required this.message});

//   List<Object?> get props => [message];
// }

// class ActiveParkingsLoaded extends ParkingState {
//   final List<Parking> parkings;

//   ActiveParkingsLoaded({required this.parkings});
// }

part of 'parking_bloc.dart';

abstract class ParkingState extends Equatable {
  const ParkingState();

  @override
  List<Object> get props => [];
}

class ParkingsInitial extends ParkingState {}

class ParkingsLoading extends ParkingState {}

class ParkingsLoaded extends ParkingState {
  final List<Parking> parkings;

  const ParkingsLoaded({required this.parkings});

  @override
  List<Object> get props => [parkings];
}

class ActiveParkingsLoaded extends ParkingState {
  final List<Parking> parkings;

  const ActiveParkingsLoaded({required this.parkings});

  @override
  List<Object> get props => [parkings];
}

class ParkingsError extends ParkingState {
  final String message;

  const ParkingsError({required this.message});

  @override
  List<Object> get props => [message];
}
