import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:parkingapp_admin/blocs/vehicle/vehicle_bloc.dart';

class ManageVehiclesView extends StatefulWidget {
  const ManageVehiclesView({super.key});

  @override
  _ManageVehiclesViewState createState() => _ManageVehiclesViewState();
}

class _ManageVehiclesViewState extends State<ManageVehiclesView> {
  @override
  void initState() {
    super.initState();
    // Fetch vehicles when the view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleBloc>().add(const LoadVehicles());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hantera fordon"),
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VehicleError) {
            return Center(
              child: Text(
                'Fel vid hämtning av data: ${state.message}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (state is VehicleLoaded) {
            final vehiclesList = state.vehicles;

            if (vehiclesList.isEmpty) {
              return const Center(
                child: Text(
                  'Inga fordon tillgängliga.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: vehiclesList.length,
              itemBuilder: (context, index) {
                final vehicle = vehiclesList[index];
                return ListTile(
                  title: Text(
                    'Fordon ID: ${vehicle.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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
                          'Ägare: ${vehicle.owner?.name}, Personnummer: ${vehicle.owner?.personNumber}, Email: ${vehicle.owner?.email}',
                          style: const TextStyle(fontSize: 14),
                        )
                      else
                        const Text(
                          'Ingen ägare',
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
                          _showEditVehicleDialog(context, vehicle);
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
          } else {
            return const SizedBox.shrink();
          }
        },
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
    Person? selectedOwner;

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
                      decoration: const InputDecoration(
                        labelText: 'Registreringsnummer',
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
                    FutureBuilder<List<Person>>(
                      future: PersonRepository.instance.getAllPersons(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                              'Fel vid hämtning av personer: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('Inga personer tillgängliga.');
                        }

                        final personer = snapshot.data!;
                        return DropdownButtonFormField<Person>(
                          decoration:
                              const InputDecoration(labelText: 'Välj ägare'),
                          items: personer.map((person) {
                            return DropdownMenuItem<Person>(
                              value: person,
                              child: Text(person.name),
                            );
                          }).toList(),
                          onChanged: (person) {
                            selectedOwner = person;
                          },
                        );
                      },
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
                  onPressed: () {
                    final regNumber = regNumberController.text;

                    if (!_isValidRegNumber(regNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Fordons registreringsnumret ska följa detta format: ABC123"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }

                    final newVehicle = Vehicle(
                      regNumber: regNumber,
                      vehicleType: selectedVehicleType,
                      owner: selectedOwner ??
                          Person(
                              name: "Ingen ägare",
                              personNumber: '',
                              email: '',
                              authId: ''),
                    );

                    context.read<VehicleBloc>().add(AddVehicle(newVehicle));
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

  void _showEditVehicleDialog(BuildContext context, Vehicle vehicle) {
    final TextEditingController regNumberController =
        TextEditingController(text: vehicle.regNumber);
    String selectedVehicleType = vehicle.vehicleType;
    Person? selectedOwner = vehicle.owner;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Redigera fordon"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: regNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registreringsnummer',
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
                    FutureBuilder<List<Person>>(
                      future: PersonRepository.instance.getAllPersons(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                              'Fel vid hämtning av personer: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('Inga personer tillgängliga.');
                        }

                        final personer = snapshot.data!;
                        return DropdownButtonFormField<Person>(
                          decoration:
                              const InputDecoration(labelText: 'Välj ägare'),
                          items: personer.map((person) {
                            return DropdownMenuItem<Person>(
                              value: person,
                              child: Text(person.name),
                            );
                          }).toList(),
                          onChanged: (person) {
                            selectedOwner = person;
                          },
                        );
                      },
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
                  onPressed: () {
                    final regNumber = regNumberController.text;

                    if (!_isValidRegNumber(regNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Fordons registreringsnumret ska följa detta format: ABC123"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }

                    final updatedVehicle = Vehicle(
                      id: vehicle.id,
                      regNumber: regNumber,
                      vehicleType: selectedVehicleType,
                      owner: selectedOwner ??
                          Person(
                              name: "Ingen ägare",
                              personNumber: '',
                              email: '',
                              authId: ''),
                    );

                    context
                        .read<VehicleBloc>()
                        .add(UpdateVehicle(updatedVehicle));
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

  void _showDeleteConfirmationDialog(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bekräfta borttagning"),
          content: Text(
            "Är du säker på att du vill ta bort fordonet med ID ${vehicle.id}?",
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
                context.read<VehicleBloc>().add(DeleteVehicle((vehicle.id)));
                Navigator.of(context).pop();
              },
              child: const Text("Ta bort"),
            ),
          ],
        );
      },
    );
  }

  bool _isValidRegNumber(String regNumber) {
    final regExp = RegExp(r'^[A-Z]{3}[0-9]{3}$');
    return regExp.hasMatch(regNumber);
  }
}
