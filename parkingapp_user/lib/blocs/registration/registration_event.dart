part of 'registration_bloc.dart';

abstract class RegistrationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class RegistrationSubmitted extends RegistrationEvent {
  final String name;
  final String personNum;
  final String confirmPersonNum;
  final String email;
  final String confirmEmail;
  final String password;
  final String confirmPassword;

  RegistrationSubmitted(
      {required this.name,
      required this.personNum,
      required this.confirmPersonNum,
      required this.email,
      required this.confirmEmail,
      required this.password,
      required this.confirmPassword});

  @override
  List<Object> get props => [
        name,
        personNum,
        confirmPersonNum,
        email,
        confirmEmail,
        password,
        confirmPassword
      ];
}

class FinalizeRegistration extends RegistrationEvent {
  final String authId;
  final String name;
  final String personNum;
  final String email;
  final String password;

  FinalizeRegistration(
      {required this.authId,
      required this.name,
      required this.personNum,
      required this.email,
      required this.password});
}
