import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkingapp_user/blocs/vehicle/vehicle_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VehicleManagementView extends StatefulWidget {
  const VehicleManagementView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VehicleManagementViewState createState() => _VehicleManagementViewState();
}

class _VehicleManagementViewState extends State<VehicleManagementView> {
  String? loggedInName;
  String? loggedInPersonNum;
  String? loggedInPersonId;
  String? loggedInPersonEmail;
  String? loggedInPersonAuthId;
  Vehicle? _selectedVehicle;
  final VehicleRepository repository = VehicleRepository.instance;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    _loadSelectedVehicle();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInPerson = prefs.getString('loggedInPerson');

    if (loggedInPerson == null) {
      print('❌ No logged-in user found in SharedPreferences');
      return;
    }

    try {
      final loggedInPersonData =
          json.decode(loggedInPerson) as Map<String, dynamic>;

      setState(() {
        loggedInName = loggedInPersonData['name'] ?? 'Unknown';
        loggedInPersonNum = loggedInPersonData['personNumber'] ?? '';
        loggedInPersonEmail = loggedInPersonData['email'] ?? '';
        loggedInPersonAuthId = loggedInPersonData['authId'] ?? '';
        loggedInPersonId = loggedInPersonData['id'] ?? '';
      });

      if (loggedInPersonAuthId == null || loggedInPersonAuthId!.isEmpty) {
        print('❌ Logged-in user authId is missing');
        return;
      }

      // Dispatch the LoadVehiclesByPerson event with the logged-in user's ID
      BlocProvider.of<VehicleBloc>(context).add(LoadVehiclesByPerson(
        Person(
          name: loggedInName ?? 'Unknown',
          personNumber: loggedInPersonNum ?? '',
          email: loggedInPersonEmail ?? '',
          authId: loggedInPersonAuthId!,
        ),
        loggedInPersonAuthId!,
      ));
    } catch (e) {
      print('❌ Failed to decode logged-in user data: $e');
    }
  }

  Future<void> _loadSelectedVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedVehicleJson = prefs.getString('selectedVehicle');

    if (selectedVehicleJson != null) {
      final Map<String, dynamic> vehicleData = json.decode(selectedVehicleJson);
      final Vehicle selectedVehicle = Vehicle.fromJson(vehicleData);

      // Check if the vehicle exists in the repository
      final exists = await _regNumberExists(selectedVehicle.regNumber);
      if (exists) {
        setState(() {
          _selectedVehicle = selectedVehicle;
        });
      } else {
        // Remove the vehicle from SharedPreferences if it doesn't exist
        await prefs.remove('selectedVehicle');
        setState(() {
          _selectedVehicle = null;
        });
      }
    }
  }

  Future<void> _saveSelectedVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final vehicleJson = json.encode(vehicle.toJson());

    await prefs.setString('selectedVehicle', vehicleJson);
    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  // void _refreshVehicles() {
  //   BlocProvider.of<VehicleBloc>(context).add(LoadVehicles());
  // }

  Future<void> _selectVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final isParkingActive = prefs.getBool('isParkingActive') ?? false;

    if (isParkingActive) {
      // If parking is active, prevent vehicle unselection
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Stoppa parkeringen först"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    _saveSelectedVehicle(vehicle); // Save selected vehicle

    // Listen for real-time updates on the selected vehicle
    FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedVehicle = Vehicle.fromJson(snapshot.data()!);
        setState(() {
          _selectedVehicle = updatedVehicle;
        });
      } else {
        setState(() {
          _selectedVehicle = null;
        });
      }
    });
  }

  Future<bool> _regNumberExists(String regNumber) async {
    final vehicles = await VehicleRepository.instance.getAllVehicles();
    return vehicles.any((vehicle) => vehicle.regNumber == regNumber);
  }

  bool _isValidRegNumber(String regNumber) {
    final regExp = RegExp(r'^[A-Z]{3}[0-9]{3}$');
    return regExp.hasMatch(regNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hantera dina fordon"),
      ),
      body: Column(
        children: [
          if (loggedInName != null && loggedInPersonNum != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Inloggad som: $loggedInName (Personnummer: $loggedInPersonNum, E-post: $loggedInPersonEmail)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          if (_selectedVehicle != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.green.withOpacity(0.2),
              child: Text(
                'Valt Fordon:\n'
                'ID: ${_selectedVehicle!.id}\n'
                'Reg.nummer: ${_selectedVehicle!.regNumber}\n'
                'Typ: ${_selectedVehicle!.vehicleType}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehiclesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VehiclesError) {
                  return Center(
                    child: Text(
                      'Fel vid hämtning av data: ${state.message}',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                } else if (state is VehiclesLoaded) {
                  final vehiclesList = state.vehicles;

                  if (vehiclesList.isEmpty) {
                    return const Center(
                      child: Text(
                        'Inga fordon tillhör denna användare.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: vehiclesList.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehiclesList[index];
                      final isSelected = _selectedVehicle?.id == vehicle.id;
                      return ListTile(
                        title: Text(
                          'Fordon ID: ${vehicle.id}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reg.nummer: ${vehicle.regNumber}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Fordonstyp: ${vehicle.vehicleType}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (vehicle.owner != null)
                              Text(
                                'Ägare: ${vehicle.owner!.name}',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (isSelected) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final isParkingActive =
                                      prefs.getBool('isParkingActive') ?? false;

                                  if (isParkingActive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Stoppa parkeringen först")),
                                    );
                                    return;
                                  }

                                  await prefs.remove('selectedVehicle');
                                  setState(() {
                                    _selectedVehicle = null;
                                  });
                                } else {
                                  _selectVehicle(vehicle);
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  isSelected ? Colors.green : Colors.grey,
                                ),
                              ),
                              child: Text(isSelected ? "Valt" : "Välj"),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showUpdateVehicleDialog(context, vehicle);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, vehicle);
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

                return const Center(
                  child: Text(
                    'Inga fordon tillgängliga.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVehicleDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final TextEditingController regNumberController = TextEditingController();
    String selectedVehicleType = 'Bil';
    String errorMessage = ''; // Local error message to store validation errors

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Skapa nytt fordon"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: regNumberController,
                      decoration: InputDecoration(
                        labelText: 'Reg.nummer',
                        errorText: errorMessage.isEmpty ? null : errorMessage,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      items: <String>[
                        'Bil',
                        'Lastbil',
                        'Motorcykel',
                        'Moped',
                        'Annat'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedVehicleType = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Fordonstyp',
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
                    final regNumber = regNumberController.text;

                    // Check for valid registration number format
                    if (!_isValidRegNumber(regNumber)) {
                      setState(() {
                        errorMessage =
                            "Fordons registreringsnummmer måste vara av formatet XXX999.";
                      });
                      return;
                    }

                    // final allVehicles = await VehicleRepository.instance.getAllVehicles();
                    final allVehicles = await repository.getAllVehicles();
                    final vehicleExists = allVehicles
                        .any((vehicle) => vehicle.regNumber == regNumber);

                    if (vehicleExists) {
                      setState(() {
                        errorMessage =
                            'Fordon med detta reg.nummer finns redan';
                      });
                      return;
                    }

                    // No errors, create the new vehicle
                    final newVehicle = Vehicle(
                      regNumber: regNumber,
                      vehicleType: selectedVehicleType,
                      owner: Person(
                        name: loggedInName!,
                        personNumber: loggedInPersonNum!,
                        email: loggedInPersonEmail!,
                        authId: loggedInPersonAuthId!,
                      ),
                    );

                    // Add new vehicle using VehicleBloc
                    // ignore: use_build_context_synchronously
                    BlocProvider.of<VehicleBloc>(context)
                        .add(CreateVehicle(newVehicle));

                    // Close the dialog
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

  void _showUpdateVehicleDialog(BuildContext context, Vehicle vehicle) {
    final TextEditingController regNumberController =
        TextEditingController(text: vehicle.regNumber);
    String selectedVehicleType = vehicle.vehicleType;
    String errorMessage = ''; // Local error message to store validation errors

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Uppdatera fordon"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: regNumberController,
                      decoration: InputDecoration(
                        labelText: 'Reg.nummer',
                        errorText: errorMessage.isEmpty ? null : errorMessage,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      items: <String>[
                        'Bil',
                        'Lastbil',
                        'Motorcykel',
                        'Moped',
                        'Annat'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedVehicleType = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Fordonstyp',
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
                    final regNumber = regNumberController.text;

                    if (!_isValidRegNumber(regNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Fordons registreringsnummmer måste vara av formatet XXX999."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    // final allVehicles = await VehicleRepository.instance.getAllVehicles();
                    final allVehicles = await repository.getAllVehicles();
                    final vehicleExists = allVehicles
                        .any((vehicle) => vehicle.regNumber == regNumber);

                    if (vehicleExists) {
                      setState(() {
                        errorMessage =
                            'Fordon med detta reg.nummer finns redan';
                      });
                      return;
                    }

                    final updatedVehicle = Vehicle(
                      id: vehicle.id,
                      regNumber: regNumber,
                      vehicleType: selectedVehicleType,
                      owner: vehicle.owner,
                    );

                    // Update vehicle using VehicleBloc
                    // ignore: use_build_context_synchronously
                    BlocProvider.of<VehicleBloc>(context)
                        .add(UpdateVehicle(updatedVehicle));

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop(); // Close the dialog
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

  void _showDeleteConfirmationDialog(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bekräfta borttagning"),
          content: Text(
            "Vill du verkligen ta bort fordonet med registreringsnummer ${vehicle.regNumber}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Avbryt"),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete vehicle using VehicleBloc
                BlocProvider.of<VehicleBloc>(context)
                    .add(DeleteVehicle(vehicle));

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Ta bort"),
            ),
          ],
        );
      },
    );
  }
}
