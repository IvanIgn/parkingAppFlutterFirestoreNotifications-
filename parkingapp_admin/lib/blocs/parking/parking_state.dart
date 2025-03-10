part of 'parking_bloc.dart';

abstract class MonitorParkingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MonitorParkingsLoadingState extends MonitorParkingsState {}

class MonitorParkingsLoadedState extends MonitorParkingsState {
  final List<Parking> parkings;

  MonitorParkingsLoadedState(this.parkings);

  @override
  List<Object?> get props => [parkings];
}

class MonitorParkingsErrorState extends MonitorParkingsState {
  final String errorMessage;

  MonitorParkingsErrorState(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class MonitorParkingsInitialState extends MonitorParkingsState {}

class MonitorParkingsEmptyState extends MonitorParkingsState {}
