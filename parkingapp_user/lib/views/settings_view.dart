import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'dart:convert';
import '../main.dart'; // To access the global isDarkModeNotifier
import '../blocs/auth/auth_bloc.dart'; // Import your AuthBloc

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
  }

  // Function to prompt the user to reauthenticate before deleting their account
  void _showReauthenticateDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bekräfta din identitet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-post',
                ),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Lösenord',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fyll i alla fält')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Check if the entered email matches the current user's email
                    if (user.email != email) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-posten matchar inte')),
                      );
                      return;
                    }

                    // If email matches, reauthenticate the user
                    final credential = EmailAuthProvider.credential(
                        email: email, password: password);
                    await user.reauthenticateWithCredential(credential);

                    // After successful reauthentication, proceed to delete the profile
                    _deleteProfile(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingen användare inloggad')),
                    );
                  }
                } catch (e) {
                  debugPrint('Reauthentication error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fel vid autentisering')),
                  );
                }
              },
              child: const Text(
                'Bekräfta',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to delete the profile from Firebase Authentication and Firestore
  Future<void> _deleteProfile(BuildContext context) async {
    final authBloc = context.read<AuthBloc>(); // Get the AuthBloc

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user from Firestore
        final prefs = await SharedPreferences.getInstance();
        final loggedInPersonJson = prefs.getString('loggedInPerson');
        if (loggedInPersonJson != null) {
          final loggedInPerson =
              json.decode(loggedInPersonJson) as Map<String, dynamic>;
          final loggedInPersonId = loggedInPerson['id']?.toString();

          if (loggedInPersonId != null) {
            await PersonRepository.instance.deletePerson(loggedInPersonId);
          }
        }

        // Delete user from Firebase Authentication
        await user.delete();

        // After deletion, log the user out
        authBloc.add(LogoutRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilen har tagits bort')),
        );
        Navigator.of(context).pop(); // Close the settings screen
      }
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fel vid borttagning av profil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadDarkModePreference(); // Ensure the current preference is loaded

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inställningar'),
      ),
      body: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDarkMode, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Välj tema',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SwitchListTile(
                  title: const Text('Mörkt läge'),
                  value: isDarkMode,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    isDarkModeNotifier.value = value; // Update the notifier
                    await prefs.setBool(
                        'isDarkMode', value); // Persist the preference
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tema ändrades till ${value ? 'Mörkt' : 'Ljust'} läge',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showReauthenticateDialog(
                        context); // Show reauthentication dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red color for delete button
                  ),
                  child: const Text('Ta bort profil'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_repositories/firebase_repositories.dart';
// import 'dart:convert';
// import '../main.dart'; // To access the global isDarkModeNotifier
// import '../blocs/auth/auth_bloc.dart'; // Import your AuthBloc

// class SettingsView extends StatelessWidget {
//   const SettingsView({super.key});

//   Future<void> _loadDarkModePreference() async {
//     final prefs = await SharedPreferences.getInstance();
//     isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
//   }

//   // Function to prompt the user to reauthenticate before deleting their account
//   void _showReauthenticateDialog(BuildContext context) {
//     final emailController = TextEditingController();
//     final passwordController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Bekräfta din identitet'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'E-post',
//                 ),
//               ),
//               TextField(
//                 controller: passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Lösenord',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text('Avbryt'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 final email = emailController.text.trim();
//                 final password = passwordController.text.trim();

//                 if (email.isEmpty || password.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Fyll i alla fält')),
//                   );
//                   return;
//                 }

//                 try {
//                   // Reauthenticate user with Firebase
//                   final user = FirebaseAuth.instance.currentUser;
//                   if (user != null) {
//                     // Use the email and password to reauthenticate
//                     final credential = EmailAuthProvider.credential(
//                         email: email, password: password);
//                     await user.reauthenticateWithCredential(credential);

//                     // After successful reauthentication, proceed to delete the profile
//                     _deleteProfile(context);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Ingen användare inloggad')),
//                     );
//                   }
//                 } catch (e) {
//                   debugPrint('Reauthentication error: $e');
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Fel vid autentisering')),
//                   );
//                 }
//               },
//               child: const Text(
//                 'Bekräfta',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to delete the profile from Firebase Authentication and Firestore
//   Future<void> _deleteProfile(BuildContext context) async {
//     final authBloc = context.read<AuthBloc>(); // Get the AuthBloc

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Delete user from Firestore
//         final prefs = await SharedPreferences.getInstance();
//         final loggedInPersonJson = prefs.getString('loggedInPerson');
//         if (loggedInPersonJson != null) {
//           final loggedInPerson =
//               json.decode(loggedInPersonJson) as Map<String, dynamic>;
//           final loggedInPersonId = loggedInPerson['id']?.toString();

//           if (loggedInPersonId != null) {
//             await PersonRepository.instance.deletePerson(loggedInPersonId);
//           }
//         }

//         // Delete user from Firebase Authentication
//         await user.delete();

//         // After deletion, log the user out
//         authBloc.add(LogoutRequested());
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profilen har tagits bort')),
//         );
//         Navigator.of(context).pop(); // Close the settings screen
//       }
//     } catch (e) {
//       debugPrint('Error deleting profile: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Fel vid borttagning av profil')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     _loadDarkModePreference(); // Ensure the current preference is loaded

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Inställningar'),
//       ),
//       body: Center(
//         child: ValueListenableBuilder<bool>(
//           valueListenable: isDarkModeNotifier,
//           builder: (context, isDarkMode, _) {
//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Välj tema',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 SwitchListTile(
//                   title: const Text('Mörkt läge'),
//                   value: isDarkMode,
//                   onChanged: (value) async {
//                     final prefs = await SharedPreferences.getInstance();
//                     isDarkModeNotifier.value = value; // Update the notifier
//                     await prefs.setBool(
//                         'isDarkMode', value); // Persist the preference
//                     // ignore: use_build_context_synchronously
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Tema ändrades till ${value ? 'Mörkt' : 'Ljust'} läge',
//                         ),
//                         duration: const Duration(seconds: 1),
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     _showReauthenticateDialog(
//                         context); // Show reauthentication dialog
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red, // Red color for delete button
//                   ),
//                   child: const Text('Ta bort profil'),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
