part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoggedIn extends AuthState {
  // Login success state
  //final String id;
  final String name;
  final String personNumber;
  final String email;
  final String password;

  const AuthLoggedIn(
      {/*required this.id,*/
      required this.name,
      required this.personNumber,
      required this.email,
      required this.password});

  @override
  List<Object?> get props => [
        name,
        /*personNumber*/
        email,
        password
      ];
}

class AuthAuthenticated extends AuthState {
  //final String id;
  final String name;
  final String personNumber;
  final String email;
  final String password;

  const AuthAuthenticated(
      {required this.name,
      required this.personNumber,
      required this.email,
      required this.password});

  @override
  List<Object?> get props => [name, personNumber, email, password];
}

class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String errorMessage;

  const AuthError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
