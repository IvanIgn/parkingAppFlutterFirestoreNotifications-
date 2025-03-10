part of 'person_bloc.dart';

/// Base class for all person-related states.
class PersonState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is first created.
class PersonInitialState extends PersonState {}

/// State indicating a loading process.
class PersonLoadingState extends PersonState {}

/// State when the list of persons is successfully loaded.
class PersonLoadedState extends PersonState {
  final List<Person> persons;

  PersonLoadedState(this.persons);

  @override
  List<Object?> get props => [persons];
}

/// State indicating an error occurred.
class PersonErrorState extends PersonState {
  final String message;

  PersonErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// State after successfully adding a person.
class PersonAddedState extends PersonState {
  final Person person;

  PersonAddedState(this.person);

  @override
  List<Object?> get props => [person];
}

/// State after successfully updating a person.
class PersonUpdatedState extends PersonState {
  final Person person; // ✅ Include the updated person

  PersonUpdatedState(this.person);

  @override
  List<Object?> get props => [person];
}

/// State after successfully deleting a person.
class PersonDeletedState extends PersonState {
  final String personId; // ✅ Include the deleted person's ID

  PersonDeletedState(this.personId);

  @override
  List<Object?> get props => [personId];
}
