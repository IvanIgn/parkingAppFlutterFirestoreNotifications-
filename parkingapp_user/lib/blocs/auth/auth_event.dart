part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  // final String id;
  final String? personName;
  //final String personNum;
  final String email;
  final String password;

  const LoginRequested({
    this.personName,
    /*required this.personNum,*/
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
        personName,
        /*personNum,*/
        email,
        password,
      ];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class AuthReset extends AuthEvent {}
