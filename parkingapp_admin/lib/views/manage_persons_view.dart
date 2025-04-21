import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkingapp_admin/blocs/person/person_bloc.dart';
import 'package:shared/shared.dart';

class ManagePersonsView extends StatefulWidget {
  const ManagePersonsView({super.key});

  @override
  _ManagePersonsViewState createState() => _ManagePersonsViewState();
}

class _ManagePersonsViewState extends State<ManagePersonsView> {
  @override
  void initState() {
    super.initState();
    // Trigger fetching persons when the view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonBloc>().add(const FetchPersonsEvent());
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> newUserInfo(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'email': userCredential.user?.email ?? email,
        'password': password,
      };
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

//class _ManagePersonsViewState extends State<ManagePersonsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hantera personer"),
      ),
      body: BlocListener<PersonBloc, PersonState>(
        listenWhen: (previous, current) =>
            current is PersonAddedState ||
            current is PersonUpdatedState ||
            current is PersonDeletedState,
        listener: (context, state) {
          context.read<PersonBloc>().add(const FetchPersonsEvent());
        },
        child: BlocBuilder<PersonBloc, PersonState>(
          builder: (context, state) {
            if (state is PersonLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PersonErrorState) {
              return Center(
                child: Text(
                  'Fel vid hämtning av data: ${state.message}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (state is PersonLoadedState) {
              final personsList = state.persons;
              if (personsList.isEmpty) {
                return const Center(
                  child: Text(
                    "Inga personer hittades.",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: personsList.length,
                itemBuilder: (context, index) {
                  final person = personsList[index];
                  return ListTile(
                    title: Text(
                      'Person ID: ${person.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Namn: ${person.name}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Personnummer: ${person.personNumber}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Email: ${person.email}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Text(
                          'Lösenord: "Secure info, not shown. Go to Firebase Console for resetting it."',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditPersonDialog(context, person);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, person);
                          },
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(
                    thickness: 1,
                    color: Colors.black87,
                  );
                },
              );
            }
            return Container();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPersonDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _personNumberExists(String personNumber) async {
    // Access the Firestore instance
    final firestore = FirebaseFirestore.instance;

    // Query the 'persons' collection for a document with the given personNumber
    final querySnapshot = await firestore
        .collection('persons')
        .where('personNumber', isEqualTo: personNumber)
        .limit(1) // Limit to 1 document for efficiency
        .get();

    // If any documents are found, the personNumber exists
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> _emailExists(String email) async {
    // Access the Firestore instance
    final firestore = FirebaseFirestore.instance;

    // Query the 'persons' collection for a document with the given email
    final querySnapshot = await firestore
        .collection('persons')
        .where('email', isEqualTo: email)
        .limit(1) // Limit to 1 document for efficiency
        .get();

    // If any documents are found, the email exists
    return querySnapshot.docs.isNotEmpty;
  }

  void _showAddPersonDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController personNumberController =
        TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    String? nameError;
    String? personNumberError;
    String? emailError;
    String? passwordError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Lägg till person"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Namn',
                        errorText: nameError, // Show error message if exists
                      ),
                    ),
                    TextField(
                      controller: personNumberController,
                      decoration: InputDecoration(
                        labelText: 'Personnummer',
                        errorText: personNumberError,
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        errorText: emailError,
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Lösenord',
                        errorText: passwordError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Avbryt"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final personNumber = personNumberController.text.trim();
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    bool hasError = false;

                    setState(() {
                      nameError = name.isEmpty ? "Namn krävs" : null;
                      personNumberError =
                          personNumber.isEmpty ? "Personnummer krävs" : null;
                      emailError = email.isEmpty ? "Email krävs" : null;
                      passwordError =
                          password.isEmpty ? "Lösenord krävs" : null;
                    });

                    if (name.isEmpty ||
                        personNumber.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty) {
                      return;
                    }

                    if (await _personNumberExists(personNumber)) {
                      setState(() {
                        personNumberError = "Detta personnummer finns redan";
                      });
                      hasError = true;
                    }

                    if (await _emailExists(email)) {
                      setState(() {
                        emailError = "Denna e-postadress används redan";
                      });
                      hasError = true;
                    }

                    if (hasError) return; // Stop if there are errors

                    final newPerson = Person(
                      name: name,
                      personNumber: personNumber,
                      email: email,
                      authId: '',
                    );

                    // ignore: use_build_context_synchronously
                    context.read<PersonBloc>().add(AddPersonEvent(
                          name: name,
                          personNum: personNumber,
                          email: email,
                          password: password,
                        ));

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  child: const Text("Spara"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final TextEditingController nameController =
        TextEditingController(text: person.name);
    final TextEditingController personNumberController =
        TextEditingController(text: person.personNumber);
    final TextEditingController emailController =
        TextEditingController(text: person.email);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Uppdatera person"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Namn'),
                ),
                TextField(
                  controller: personNumberController,
                  decoration: const InputDecoration(labelText: 'Personnummer'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Avbryt"),
            ),
            ElevatedButton(
              onPressed: () async {
                final personNumber = personNumberController.text;
                final name = nameController.text;
                final email = emailController.text;

                if (personNumber != person.personNumber &&
                    await _personNumberExists(personNumber)) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Personen $name med detta personnummer $personNumber finns redan"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                if (email != person.email && await _emailExists(email)) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Personen $name med detta email $email finns redan"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                final updatedPerson = Person(
                  id: person.id,
                  name: name,
                  personNumber: personNumber,
                  email: person.email,
                  authId: person.authId,
                );

                // ignore: use_build_context_synchronously
                context
                    .read<PersonBloc>()
                    .add(UpdatePersonEvent(updatedPerson));
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text("Spara"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Person person) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bekräfta borttagning"),
          content: Text(
            "Är du säker på att du vill ta bort personen med ID ${person.id}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Avbryt"),
            ),
            ElevatedButton(
              onPressed: () async {
                context.read<PersonBloc>().add(DeletePersonEvent((person.id)));
                Navigator.of(context).pop();
              },
              child: const Text("Ta bort"),
            ),
          ],
        );
      },
    );
  }
}



  // void _showAddPersonDialog(BuildContext context) {
  //   final TextEditingController nameController = TextEditingController();
  //   final TextEditingController personNumberController =
  //       TextEditingController();
  //   final TextEditingController emailController = TextEditingController();
  //   final TextEditingController passwordController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Lägg till person"),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(
  //                 controller: nameController,
  //                 decoration: const InputDecoration(labelText: 'Namn'),
  //               ),
  //               TextField(
  //                 controller: personNumberController,
  //                 decoration: const InputDecoration(labelText: 'Personnummer'),
  //               ),
  //               TextField(
  //                 controller: emailController,
  //                 decoration: const InputDecoration(labelText: 'Email'),
  //               ),
  //               TextField(
  //                 controller: passwordController,
  //                 decoration: const InputDecoration(labelText: 'Lösenord'),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text("Avbryt"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final personNumber = personNumberController.text;
  //               final name = nameController.text;
  //               final email = emailController.text;
  //               final password = passwordController.text;

  //               if (await _personNumberExists(personNumber)) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text(
  //                         "Personen $name med detta personnummer $personNumber finns redan"),
  //                     duration: const Duration(seconds: 1),
  //                   ),
  //                 );
  //                 return;
  //               }

  //               if (await _emailExists(email)) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text(
  //                         "Personen $name med detta email $email finns redan"),
  //                     duration: const Duration(seconds: 1),
  //                   ),
  //                 );
  //                 return;
  //               }

  //               final newPerson = Person(
  //                 name: name,
  //                 personNumber: personNumber,
  //                 email: email, // email: '',
  //                 authId: '', // authId: '',
  //               );

  //               // ignore: use_build_context_synchronously
  //               context.read<PersonBloc>().add(AddPersonEvent(
  //                     name: name,
  //                     personNum: personNumber,
  //                     email: email,
  //                     password:
  //                         password, // Replace with actual password if available
  //                   ));
  //               // ignore: use_build_context_synchronously
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text("Spara"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
