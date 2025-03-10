import 'package:bloc/bloc.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:equatable/equatable.dart';

part 'person_event.dart';
part 'person_state.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  List<Person> _personList = [];
  final PersonRepository repository;

  PersonBloc({required this.repository}) : super(PersonsInitial()) {
    on<LoadPersons>((event, emit) async {
      await onLoadPersons(emit);
    });

    on<LoadPersonsById>((event, emit) async {
      await onLoadPersonsById(emit, event.person);
    });

    on<DeletePersons>((event, emit) async {
      await onDeletePerson(event, emit);
    });

    on<CreatePerson>((event, emit) async {
      await onCreatePerson(emit, event.person);
    });

    on<UpdatePersons>((event, emit) async {
      await onUpdatePerson(event, emit);
    });
  }

  // Load all persons
  Future<void> onLoadPersons(Emitter<PersonState> emit) async {
    emit(PersonsLoading());
    try {
      _personList = await repository.getAllPersons();
      emit(PersonsLoaded(persons: _personList));
    } catch (e) {
      emit(PersonsError(message: e.toString()));
    }
  }

  // Load a single person by their ID
  Future<void> onLoadPersonsById(
      Emitter<PersonState> emit, Person person) async {
    emit(PersonsLoading());
    try {
      final personById = await repository.getPersonById(person.id);
      emit(PersonLoaded(person: personById));
      print('Emitted PersonLoaded: $personById');
    } catch (e) {
      emit(PersonsError(message: e.toString()));
    }
  }

  // Create a new person
  Future<void> onCreatePerson(Emitter<PersonState> emit, Person person) async {
    try {
      await repository.createPerson(person); // Await person creation
      _personList = await repository.getAllPersons(); // Fetch updated list
      emit(PersonsLoaded(persons: _personList)); // Emit updated list
    } catch (e) {
      emit(PersonsError(message: e.toString())); // Handle error case
    }
  }

  // Update an existing person
  Future<void> onUpdatePerson(
      UpdatePersons event, Emitter<PersonState> emit) async {
    emit(PersonsLoading()); // Emit loading state first
    try {
      await repository.updatePerson(event.person.id, event.person);
      final updatedPerson = await repository.getPersonById(event.person.id);
      emit(PersonLoaded(person: updatedPerson));
    } catch (e) {
      emit(PersonsError(message: e.toString())); // Emit error if update fails
    }
  }

  Future<void> onDeletePerson(
      DeletePersons event, Emitter<PersonState> emit) async {
    emit(PersonsLoading()); // Emit loading state first
    try {
      // Delete person from Firestore
      await repository.deletePerson(event.person.id);

      // Fetch updated list of persons after deletion
      _personList = await repository.getAllPersons();

      // Emit updated list of persons
      emit(PersonsLoaded(persons: _personList));
    } catch (e) {
      emit(PersonsError(message: e.toString())); // Emit error if delete fails
    }
  }

  // Delete a person
  // Future<void> onDeletePerson(Emitter<PersonState> emit, Person person) async {
  //   emit(PersonsLoading()); // Emit loading state first
  //   try {
  //     print("Deleting person with id: ${person.id}");

  //     // Delete person from Firestore and Firebase Auth
  //     await repository.deletePerson(person.id);

  //     // Fetch updated list of persons after deletion
  //     _personList = await repository.getAllPersons();
  //     print("Updated persons list: $_personList");

  //     emit(PersonsLoaded(persons: _personList)); // Emit updated list
  //   } catch (e) {
  //     emit(PersonsError(message: e.toString())); // Emit error if delete fails
  //   }
  // }
}
