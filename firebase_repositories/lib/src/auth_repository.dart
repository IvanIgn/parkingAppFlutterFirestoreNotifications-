import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final authService = FirebaseAuth.instance;

  Future<UserCredential> login(
      {required String email, required String password}) {
    // as per documentation, this method throws an exception if login fails
    // as per documentaiton, successful login updates authStateChanges stream
    return authService.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> logout() async {
    await authService.signOut();
  }

  Stream<User?> get userStream {
    // stream emits when any of the above functions complete
    // emits null when user is signed out, otherwise User
    return authService.authStateChanges();
  }
}

  // Future<UserCredential> register(
  //     {required String email,
  //     required String password,
  //     required String personName,
  //     required String personNumber}) {
  //   return authService.createUserWithEmailAndPassword(
  //       email: email, password: password);
  // }

//  Future<bool> register(String name, String email, String personNumber,
//     String password, BuildContext context) async {
//   try {
//     // Show loading dialog
//    // showLoadingDialog(context);

//     UserCredential credential = await authService.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );

//     if (credential.user == null) return false;

//     // Create user model
//     Person user = Person(
//       name: name,
//       personNumber: personNumber,
//       email: credential.user!.email.toString(),
//       authId: credential.user!.uid.toString(),
//     );

//     // Upload user model to Firestore
//     await fireStore.collection('persons').doc(credential.user!.uid).set(user.toMap());

//     // Show success message
//     showSnackBar(context, "Sign Up Successful!");

//     return true;
//   } on FirebaseAuthException catch (exception) {
//     showSnackBar(context, getMessageFromErrorCode(exception.code));
//     return false;
//   } finally {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context); // Close loading dialog only if it's active
//     }
//   }
// }

//}
