part of 'person_bloc.dart';

// Assuming you have a Person class defined elsewhere

sealed class PersonState extends Equatable {
  const PersonState(); // You should provide a constructor for `PersonState`

  @override
  List<Object?> get props => [];
}

class PersonsInitial extends PersonState {
  @override
  List<Object?> get props => [];
}

class PersonsLoading extends PersonState {
  @override
  List<Object?> get props => [];
}

class PersonsLoaded extends PersonState {
  final List<Person> persons;

  const PersonsLoaded({required this.persons});

  @override
  List<Object?> get props =>
      [persons]; // Include the list of persons for equality comparison
}

class PersonLoaded extends PersonState {
  final Person person;

  const PersonLoaded({required this.person});

  @override
  List<Object?> get props =>
      [person]; // Include the person for equality comparison
}

class PersonsError extends PersonState {
  final String message;

  const PersonsError({required this.message});

  @override
  List<Object?> get props =>
      [message]; // Include the error message for equality comparison
}
