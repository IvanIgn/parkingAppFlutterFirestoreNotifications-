// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:parkingapp_user/blocs/auth/auth_bloc.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/services.dart';

// class LoginFormView extends StatefulWidget {
//   final VoidCallback onLoginSuccess;

//   const LoginFormView({super.key, required this.onLoginSuccess});

//   @override
//   LoginFormViewState createState() => LoginFormViewState();
// }

// class LoginFormViewState extends State<LoginFormView> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   String? emailError;
//   String? passwordError;

//   void _focusInputField() {
//     if (kIsWeb) {
//       Future.delayed(const Duration(milliseconds: 100), () {
//         SystemChannels.textInput.invokeMethod('TextInput.show');
//       });
//     }
//   }

//   void _login() {
//     _focusInputField();

//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();

//     setState(() {
//       emailError = email.isEmpty ? "Fyll i Email" : null;
//       passwordError = password.isEmpty ? "Fyll i lösenord" : null;
//     });

//     if (emailError == null && passwordError == null) {
//       // Trigger login event
//       BlocProvider.of<AuthBloc>(context).add(LoginRequested(
//         personName: "User Name",
//         email: email,
//         password: password,
//       ));

//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Kontrollera uppgifterna och försök igen"),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Logga In")),
//       body: BlocListener<AuthBloc, AuthState>(
//         listener: (context, state) {
//           if (state is AuthAuthenticated) {
//             // Close any open dialogs
//             Navigator.of(context).popUntil((route) => route.isFirst);

//             // Show success message
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("${state.email} har loggats in")),
//             );

//             // Navigate to home after login success
//             widget.onLoginSuccess();
//           } else if (state is AuthError) {
//             // Close any loading dialogs
//             if (Navigator.of(context).canPop()) {
//               Navigator.of(context).pop();
//             }

//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.errorMessage)),
//             );
//           }
//         },
//         child: SingleChildScrollView(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 400),
//                 child: Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         TextField(
//                           controller: emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: InputDecoration(
//                             labelText: "Email",
//                             errorText: emailError,
//                             border: const OutlineInputBorder(),
//                           ),
//                           onSubmitted: (_) => _login(),
//                         ),
//                         const SizedBox(height: 16),
//                         TextField(
//                           controller: passwordController,
//                           obscureText: true,
//                           decoration: InputDecoration(
//                             labelText: "Lösenord",
//                             errorText: passwordError,
//                             border: const OutlineInputBorder(),
//                           ),
//                           onSubmitted: (_) => _login(),
//                         ),
//                         const SizedBox(height: 24),
//                         ElevatedButton(
//                           onPressed: _login,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 40,
//                               vertical: 16,
//                             ),
//                             textStyle: const TextStyle(fontSize: 16),
//                           ),
//                           child: const Text("Logga In"),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/blocs/auth/auth_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class LoginFormView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginFormView({super.key, required this.onLoginSuccess});

  @override
  LoginFormViewState createState() => LoginFormViewState();
}

class LoginFormViewState extends State<LoginFormView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _focusInputField() {
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      });
    }
  }

  void _login() {
    _focusInputField();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    String errorMessage = "";

    if (email.isEmpty) errorMessage += "Fyll i Email.\n";
    if (password.isEmpty) errorMessage += "Fyll i lösenord.\n";

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage.trim())),
      );
      return;
    }

    // 🔹 Trigger login event
    BlocProvider.of<AuthBloc>(context).add(LoginRequested(
      personName: "User Name",
      email: email,
      password: password,
    ));

    // 🔹 Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logga In")),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Close any open dialogs
            Navigator.of(context).popUntil((route) => route.isFirst);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${state.email} har loggats in")),
            );

            // Navigate to home after login success
            widget.onLoginSuccess();
          } else if (state is AuthError) {
            // Close any loading dialogs
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            // Show error message in Snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Lösenord",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text("Logga In"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
