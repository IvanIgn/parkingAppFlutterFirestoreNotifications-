import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared/shared.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'person_event.dart';
part 'person_state.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  final PersonRepository repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PersonBloc({required this.repository}) : super(PersonInitialState()) {
    on<FetchPersonsEvent>(_onFetchPersons);
    on<AddPersonEvent>(_onAddPerson);
    on<UpdatePersonEvent>(_onUpdatePerson);
    on<DeletePersonEvent>(_onDeletePerson);
  }

  Future<void> _onFetchPersons(
      FetchPersonsEvent event, Emitter<PersonState> emit) async {
    emit(PersonLoadingState());
    try {
      final persons = await repository.getAllPersons();
      emit(PersonLoadedState(persons)); // Ensure the updated list is emitted
    } catch (e) {
      emit(PersonErrorState("Error fetching persons: $e"));
    }
  }

  Future<void> _onAddPerson(
      AddPersonEvent event, Emitter<PersonState> emit) async {
    emit(PersonLoadingState());

    try {
      // 🔍 Validate Input Fields
      if (event.name.isEmpty) {
        emit(PersonErrorState("Fyll i namn"));
        return;
      }
      if (event.personNum.isEmpty ||
          !isNumeric(event.personNum) ||
          event.personNum.length != 12) {
        emit(PersonErrorState(
            "Personnummer måste vara 12 siffror och numeriskt"));
        return;
      }
      if (!isEmail(event.email) || event.email.isEmpty) {
        emit(PersonErrorState("Fyll i en giltig e-post"));
        return;
      }
      if (event.password.isEmpty || event.password.length < 6) {
        emit(PersonErrorState("Lösenordet måste vara minst 6 tecken långt"));
        return;
      }

      // 🔥 Check if Email Already Exists
      final emailExists = await _firestore
          .collection('persons')
          .where('email', isEqualTo: event.email)
          .get();

      if (emailExists.docs.isNotEmpty) {
        emit(PersonErrorState("E-postadressen är redan registrerad"));
        return;
      }

      // 🔐 Register User in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        emit(PersonErrorState(
            "Registreringsfel: Kunde inte lägga till en ny användare"));
        return;
      }

      // ✅ Update FirebaseAuth Display Name
      await firebaseUser.updateDisplayName(event.name);
      await firebaseUser.reload(); // Ensure updates are applied
      firebaseUser = _auth.currentUser; // Refresh user instance

      // Get Firebase UID
      String uid = firebaseUser!.uid;

      // 👤 Create Person Model with Auth ID
      final newPerson = Person(
        id: uid, // Assign Firebase UID as Firestore Document ID
        name: event.name,
        personNumber: event.personNum,
        email: event.email,
        authId: uid, // Store Auth ID for future authentication
      );

      // 🔥 Save Person to Firestore
      await _firestore.collection('persons').doc(uid).set(newPerson.toMap());

      // 🎉 Success!
      emit(PersonAddedState(newPerson));
    } catch (e) {
      emit(PersonErrorState(
          "Det gick inte att lägga till en ny användare: ${e.toString()}"));
    }
  }

  bool isNumeric(String str) {
    final numericRegex = RegExp(r'^[0-9]+$');
    return numericRegex.hasMatch(str);
  }

  bool isEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _onUpdatePerson(
      UpdatePersonEvent event, Emitter<PersonState> emit) async {
    try {
      emit(PersonLoadingState()); // Emit loading state first

      // Update person in repository
      await repository.updatePerson(event.person.id, event.person);

      // Emit the updated state with the updated person
      emit(PersonUpdatedState(event.person));

      if (state is PersonLoadedState) {
        final currentState = state as PersonLoadedState;
        final updatedList = currentState.persons.map((p) {
          return p.id == event.person.id ? event.person : p;
        }).toList();
        emit(PersonLoadedState(
            updatedList)); // Emit loaded state with updated list
      }
    } catch (e) {
      emit(PersonErrorState("Error updating person: $e"));
    }
  }

  Future<void> _onDeletePerson(
      DeletePersonEvent event, Emitter<PersonState> emit) async {
    try {
      emit(PersonLoadingState()); // Emit loading state first

      await repository.deletePerson(event.personId.toString());

      // Ensure the state update is valid
      if (state is PersonLoadedState &&
          (state as PersonLoadedState).persons.isNotEmpty) {
        final currentState = state as PersonLoadedState;
        final updatedList =
            currentState.persons.where((p) => p.id != event.personId).toList();
        emit(PersonLoadedState(updatedList)); // Emit updated list
      } else {
        emit(PersonLoadedState(
            const [])); // Emit empty list if no previous state
      }
    } catch (e) {
      emit(PersonErrorState("Error deleting person: $e"));
    }
  }
}



  // Future<void> _onAddPerson(
  //     AddPersonEvent event, Emitter<PersonState> emit) async {
  //   try {
  //     final newPerson = await repository.createPerson(event.person);

  //     if (state is PersonLoadedState) {
  //       final currentState = state as PersonLoadedState;
  //       final updatedList = List<Person>.from(currentState.persons)
  //         ..add(newPerson);
  //       emit(PersonLoadedState(updatedList));
  //     } else {
  //       emit(PersonLoadedState(
  //           [newPerson])); // Handle case where state is not loaded
  //     }
  //   } catch (e) {
  //     emit(PersonErrorState("Error adding person: $e"));
  //   }
  // }