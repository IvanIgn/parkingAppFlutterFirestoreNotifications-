part of 'person_bloc.dart';

sealed class PersonEvent extends Equatable {
  const PersonEvent(); // Ensure const constructors for immutability

  @override
  List<Object?> get props => [];
}

class LoadPersons extends PersonEvent {}

class LoadPersonsById extends PersonEvent {
  final Person person;

  const LoadPersonsById({required this.person});

  @override
  List<Object?> get props => [person]; // Compare based on the person
}

class CreatePerson extends PersonEvent {
  final Person person;

  const CreatePerson({required this.person});

  @override
  List<Object?> get props => [person]; // Compare based on the person
}

class UpdatePersons extends PersonEvent {
  final Person person;

  const UpdatePersons({required this.person});

  @override
  List<Object?> get props => [person]; // Compare based on the person
}

class DeletePersons extends PersonEvent {
  final Person person;

  const DeletePersons({required this.person});

  @override
  List<Object?> get props => [person]; // Compare based on the person
}
