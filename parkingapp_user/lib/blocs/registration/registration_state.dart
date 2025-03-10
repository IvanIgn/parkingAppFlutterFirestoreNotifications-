part of 'registration_bloc.dart';

abstract class RegistrationState extends Equatable {
  @override
  List<Object> get props => [];
}

class RegistrationInitial extends RegistrationState {}

class RegistrationLoading extends RegistrationState {}

class RegistrationSuccess extends RegistrationState {
  final String successMessage;

  RegistrationSuccess({required this.successMessage});

  @override
  List<Object> get props => [successMessage];
}

class RegistrationError extends RegistrationState {
  final String errorMessage;

  RegistrationError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
