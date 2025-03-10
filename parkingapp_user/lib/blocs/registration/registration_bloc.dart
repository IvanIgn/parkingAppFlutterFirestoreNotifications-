import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared/shared.dart'; // PersonRepository
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final PersonRepository _personRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RegistrationBloc({required PersonRepository personRepository})
      : _personRepository = personRepository,
        super(RegistrationInitial()) {
    on<RegistrationSubmitted>(_mapRegistrationSubmittedToState);
  }

  Future<void> _mapRegistrationSubmittedToState(
      RegistrationSubmitted event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());

    try {
      // 🔍 Validate Input Fields
      if (event.name.isEmpty) {
        emit(RegistrationError(errorMessage: "Fyll i namn"));
        return;
      }
      if (event.personNum.isEmpty ||
          !isNumeric(event.personNum) ||
          event.personNum.length != 12) {
        emit(RegistrationError(
            errorMessage: "Personnummer måste vara 12 siffror och numeriskt"));
        return;
      }
      if (event.confirmPersonNum != event.personNum) {
        emit(RegistrationError(errorMessage: "Personnummret matchar inte"));
        return;
      }
      if (!isEmail(event.email) || event.email.isEmpty) {
        emit(RegistrationError(errorMessage: "Fyll i en giltig e-post"));
        return;
      }
      if (event.confirmEmail != event.email) {
        emit(RegistrationError(errorMessage: "E-postadressen matchar inte"));
        return;
      }
      if (event.password.isEmpty || event.password.length < 6) {
        emit(RegistrationError(
            errorMessage: "Lösenordet måste vara minst 6 tecken långt"));
        return;
      }
      if (event.password != event.confirmPassword) {
        emit(RegistrationError(errorMessage: "Lösenorden matchar inte"));
        return;
      }

      // 🔥 **Check if Email Already Exists**
      final emailExists = await _firestore
          .collection('persons')
          .where('email', isEqualTo: event.email)
          .get();

      if (emailExists.docs.isNotEmpty) {
        emit(RegistrationError(
            errorMessage: "E-postadressen är redan registrerad"));
        return;
      }

      // 🔐 **Register User in Firebase Authentication**
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        emit(RegistrationError(
            errorMessage: "Registreringsfel: Kunde inte skapa konto"));
        return;
      }

      // ✅ **Update FirebaseAuth Display Name**
      await firebaseUser.updateDisplayName(event.name);
      await firebaseUser.reload(); // Ensure updates are applied
      firebaseUser = _auth.currentUser; // Refresh user instance

      // Get Firebase UID
      String uid = firebaseUser!.uid;

      // 👤 **Create Person Model**
      final newPerson = Person(
        name: event.name,
        personNumber: event.personNum,
        email: event.email,
        authId: uid,
      );

      // 🔥 **Save Person to Firestore**
      await _firestore
          .collection('persons')
          .doc(uid)
          .set(newPerson.copyWith(id: uid).toMap());

      // 🎉 **Success!**
      emit(RegistrationSuccess(
          successMessage: "Registrering lyckades! Välkommen, ${event.name}!"));
    } catch (e) {
      emit(
          RegistrationError(errorMessage: "Registreringsfel: ${e.toString()}"));
    }
  }

// 🛠 **Helper Functions**
  bool isNumeric(String str) {
    final numericRegex = RegExp(r'^[0-9]+$');
    return numericRegex.hasMatch(str);
  }

  bool isEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
}
