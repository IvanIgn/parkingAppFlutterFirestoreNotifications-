import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/blocs/registration/registration_bloc.dart';
import 'package:flutter/services.dart';

class RegistrationView extends StatelessWidget {
  const RegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final personNumController = TextEditingController();
    final confirmPersonNumController = TextEditingController();
    final emailController = TextEditingController();
    final confirmEmailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Using ValueNotifier to manage error messages
    final nameErrorNotifier = ValueNotifier<String?>(null);
    final personNumErrorNotifier = ValueNotifier<String?>(null);
    final emailErrorNotifier = ValueNotifier<String?>(null);
    final passwordErrorNotifier = ValueNotifier<String?>(null);

    void submitForm() {
      final name = nameController.text.trim();
      final personNum = personNumController.text.trim();
      final confirmPersonNum = confirmPersonNumController.text.trim();
      final email = emailController.text.trim();
      final confirmEmail = confirmEmailController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      // Reset error messages
      nameErrorNotifier.value = null;
      personNumErrorNotifier.value = null;
      emailErrorNotifier.value = null;
      passwordErrorNotifier.value = null;

      // Validate fields
      if (name.isEmpty) {
        nameErrorNotifier.value = "Namn är obligatoriskt.";
        return;
      }
      if (!isName(name)) {
        nameErrorNotifier.value = "Namn får endast innehålla bokstäver.";
        return;
      }
      if (personNum.isEmpty) {
        personNumErrorNotifier.value = "Personnummer är obligatoriskt.";
        return;
      }
      if (!isPersonNum(personNum)) {
        personNumErrorNotifier.value = "Personnummer måste vara 12 siffror.";
        return;
      }

      if (personNum != confirmPersonNum) {
        personNumErrorNotifier.value = "Personnummer matchar inte.";
        return;
      }

      if (email.isEmpty) {
        emailErrorNotifier.value = "Email är obligatoriskt.";
        return;
      }
      if (!isEmail(email)) {
        emailErrorNotifier.value = "Ogiltig email.";
        return;
      }
      if (email != confirmEmail) {
        emailErrorNotifier.value = "Email matchar inte.";
        return;
      }

      if (password.isEmpty) {
        passwordErrorNotifier.value = "Lösenord är obligatoriskt.";
        return;
      }
      if (password != confirmPassword) {
        passwordErrorNotifier.value = "Lösenord matchar inte.";
        return;
      }

      // Dispatch registration event if validation passes
      context.read<RegistrationBloc>().add(
            RegistrationSubmitted(
              name: name,
              personNum: personNum,
              confirmPersonNum: confirmPersonNum,
              email: email,
              confirmEmail: confirmEmail,
              password: password,
              confirmPassword: confirmPassword,
            ),
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Registrera Dig")),
      body: SingleChildScrollView(
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
                  // ignore: deprecated_member_use
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      // ignore: deprecated_member_use
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        submitForm();
                      }
                    },
                    child: BlocConsumer<RegistrationBloc, RegistrationState>(
                      listener: (context, state) {
                        if (state is RegistrationSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.successMessage)),
                          );
                          Navigator.of(context).pop(); // Navigate back
                        } else if (state is RegistrationError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.errorMessage)),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is RegistrationLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTextField(
                              controller: nameController,
                              label: "Namn",
                              errorNotifier: nameErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: personNumController,
                              label: "Personnummer",
                              errorNotifier: personNumErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: confirmPersonNumController,
                              label: "Bekräfta personnummer",
                              errorNotifier: personNumErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: emailController,
                              label: "Email",
                              errorNotifier: emailErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: confirmEmailController,
                              label: "Bekräfta Email",
                              errorNotifier: emailErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: passwordController,
                              label: "Lösenord",
                              errorNotifier: passwordErrorNotifier,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: confirmPasswordController,
                              label: "Bekräfta Lösenord",
                              errorNotifier: passwordErrorNotifier,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              child: const Text("Registrera"),
                            ),
                          ],
                        );
                      },
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ValueNotifier<String?> errorNotifier,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, error, _) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  bool isPersonNum(String personNum) {
    // Strict 12-digit format (YYYYMMDDXXXX)
    final personNumRegex = RegExp(r'^(19|20)?\d{6}\d{4}$');
    return personNumRegex.hasMatch(personNum);
  }

  bool isEmail(String email) {
    final emailRegex = RegExp(r'^[\w.-]+@[a-zA-Z\d.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool isName(String name) {
    final nameRegex =
        RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:[-\s][A-Za-zÀ-ÖØ-öø-ÿ]+)*$');
    return nameRegex.hasMatch(name);
  }
}
