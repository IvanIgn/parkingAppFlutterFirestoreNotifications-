import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PersonRepository personRepository;
  final AuthRepository authRepository = AuthRepository();

  AuthBloc({required this.personRepository}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthReset>((_, emit) => emit(AuthLoggedOut()));
  }

  @override
  void onEvent(AuthEvent event) {
    super.onEvent(event);
    if (event is LoginRequested) {
      // Сбросить ошибки перед новым запросом
      if (state is AuthError) {
        add(LogoutRequested());
      }
    }
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (state is! AuthLoggedOut) {
          emit(AuthLoggedOut());
        }
        return;
      }

      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('persons')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        print("❌ No Firestore document found for user ID: ${firebaseUser.uid}");
        emit(const AuthError(
            errorMessage:
                "Ingen användardata hittades. Vänligen kontakta supporten."));
        return;
      }

      final userData = userDoc.data() ?? {};
      String userName = userData['name'] ?? 'Användare'; // Default if missing

      // Update display name ONLY if it's different
      if (firebaseUser.displayName != userName) {
        await firebaseUser.updateDisplayName(userName);
      }

      // Emit state **only if it has changed**
      if (state is! AuthAuthenticated ||
          (state as AuthAuthenticated).name != userName) {
        emit(AuthAuthenticated(
          name: userName,
          email: firebaseUser.email ?? '',
          password: '', // Never store password in state
          personNumber: '',
        ));
      }
    } catch (e) {
      print("⚠️ Error checking authentication status: $e");
      if (state is! AuthError) {
        emit(const AuthError(
            errorMessage: "Ett fel uppstod vid kontroll av inloggning."));
      }
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      // 🔍 Steg 1: Kontrollera om e-posten finns i Firestore
      final emailQuery = await FirebaseFirestore.instance
          .collection('persons')
          .where('email', isEqualTo: event.email)
          .limit(1)
          .get();

      if (emailQuery.docs.isEmpty) {
        emit(AuthLoggedOut());
        emit(const AuthError(
            errorMessage: "❌ Personen med detta email är inte registrerad."));
        return;
      }

      // 🔐 Steg 2: Försök att logga in med Firebase Auth
      UserCredential userCredential = await authRepository.login(
          email: event.email, password: event.password);

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        emit(const AuthError(
            errorMessage: "❌ Inloggningsfel. Användare hittades inte."));
        return;
      }

      // 🔍 Steg 3: Hämta användarinformation från Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('persons')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        emit(const AuthError(
            errorMessage: "❌ Inga användare hittades i databasen."));
        return;
      }

      final userData = userDoc.data() ?? {};
      String name = userData['name'] ?? 'Okänd användare';
      String email = firebaseUser.email ?? '';
      String personNumber = userData['personNumber'] ?? '';

      print("✅ LOGIN SUCCESS: $email ($name)");

      // Spara inloggad användare i SharedPreferences
      final loggedInPerson = {
        'name': name,
        'personNumber': personNumber,
        'email': email,
        'authId': firebaseUser.uid,
        'id': firebaseUser.uid,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInPerson', json.encode(loggedInPerson));

      emit(AuthAuthenticated(
        name: name,
        email: email,
        password: '',
        personNumber: personNumber,
      ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        emit(const AuthError(errorMessage: "❌ Lösenordet är fel."));
      } else {
        emit(
            AuthError(errorMessage: "❌ Inloggning misslyckades: ${e.message}"));
      }
    } catch (e) {
      emit(AuthError(errorMessage: "❌ Ett oväntat fel uppstod: $e"));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await authRepository.logout();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(errorMessage: 'Ett fel uppstod under utloggning: $e'));
    }
  }
}
