import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_admin/blocs/parking/parking_bloc.dart';

class MonitorParkingsView extends StatefulWidget {
  const MonitorParkingsView({super.key});

  @override
  _ManageMonitorParkingViewState createState() =>
      _ManageMonitorParkingViewState();
}

class _ManageMonitorParkingViewState extends State<MonitorParkingsView> {
  @override
  void initState() {
    super.initState();
    // Trigger fetching persons when the view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingsBloc>().add(LoadParkingsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aktiva Parkeringar"),
      ),
      body: BlocBuilder<ParkingsBloc, MonitorParkingsState>(
        builder: (context, state) {
          if (state is MonitorParkingsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MonitorParkingsErrorState) {
            return Center(
              child: Text(
                'Fel vid hämtning av data: ${state.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (state is MonitorParkingsLoadedState) {
            final parkingsList = state.parkings;

            if (parkingsList.isEmpty) {
              return const Center(
                child: Text(
                  'Inga parkeringar tillgängliga.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: parkingsList.length,
              itemBuilder: (context, index) {
                final parking = parkingsList[index];
                return ListTile(
                  title: Text(
                    'Parkerings-ID: ${parking.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starttid: ${DateFormat('yyyy-MM-dd HH:mm').format(parking.startTime)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Sluttid: ${DateFormat('yyyy-MM-dd HH:mm').format(parking.endTime)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Reg.nummer: ${parking.vehicle!.regNumber}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Address: ${parking.parkingSpace?.address}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditParkingDialog(context, parking);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, parking);
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
          _showAddParkingDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _showAddParkingDialog(BuildContext context) {
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  Vehicle? selectedVehicle;
  ParkingSpace? selectedParkingSpace;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Lägg till parkering"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Starttid (HH:mm)',
                    // 'Starttid (yyyy-MM-dd HH:mm)',
                  ),
                ),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Sluttid (HH:mm)',
                    //'Sluttid (yyyy-MM-dd HH:mm)',
                  ),
                ),
                FutureBuilder<List<Vehicle>>(
                  future: VehicleRepository.instance.getAllVehicles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                          'Fel vid hämtning av fordon: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Inga fordon tillgängliga.');
                    }

                    final vehicles = snapshot.data!;
                    return DropdownButtonFormField<Vehicle>(
                      decoration:
                          const InputDecoration(labelText: 'Välj fordon'),
                      items: vehicles.map((vehicle) {
                        return DropdownMenuItem<Vehicle>(
                          value: vehicle,
                          child: Text(vehicle.regNumber),
                        );
                      }).toList(),
                      onChanged: (vehicle) {
                        selectedVehicle = vehicle;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<ParkingSpace>>(
                  future: ParkingSpaceRepository.instance.getAllParkingSpaces(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                          'Fel vid hämtning av parkeringsplatser: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Inga parkeringsplatser tillgängliga.');
                    }

                    final parkingSpaces = snapshot.data!;
                    return DropdownButtonFormField<ParkingSpace>(
                      decoration: const InputDecoration(
                          labelText: 'Välj parkeringsplats'),
                      items: parkingSpaces.map((parkingSpace) {
                        return DropdownMenuItem<ParkingSpace>(
                          value: parkingSpace,
                          child: Text(parkingSpace.address),
                        );
                      }).toList(),
                      onChanged: (parkingSpace) {
                        selectedParkingSpace = parkingSpace;
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
              onPressed: () async {
                if (selectedVehicle == null || selectedParkingSpace == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Välj ett fordon och en parkeringsplats"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final newParking = Parking(
                  // id: Uuid().v4(), // Assign ID in the repository
                  startTime: DateTime.parse(
                      _getCorrectDate(startTimeController.text.trim())),
                  //DateTime.parse(startTimeController.text.trim()),
                  endTime: DateTime.parse(
                      _getCorrectDate(endTimeController.text.trim())),
                  //DateTime.parse(endTimeController.text.trim()),
                  vehicle: selectedVehicle!,
                  parkingSpace: selectedParkingSpace!,
                );

                context.read<ParkingsBloc>().add(AddParkingEvent(newParking));

                Navigator.of(context).pop();
              },
              child: const Text("Spara"),
            ),
          ],
        );
      });
    },
  );
}

String _getCorrectDate(String time) {
  DateTime dateToday = DateTime.now();
  String date = dateToday.toString().substring(0, 10);
  return '$date $time';
}

void _showEditParkingDialog(BuildContext context, Parking parking) {
  final TextEditingController startTimeController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm').format(parking.startTime));
  final TextEditingController endTimeController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm').format(parking.endTime));
  Vehicle? selectedVehicle;
  ParkingSpace? selectedParkingSpace;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Redigera parkering"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Starttid (yyyy-MM-dd HH:mm)',
                    ),
                  ),
                  TextField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Sluttid (yyyy-MM-dd HH:mm)',
                    ),
                  ),
                  FutureBuilder<List<Vehicle>>(
                    future: VehicleRepository.instance.getAllVehicles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                            'Fel vid hämtning av fordon: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('Inga fordon tillgängliga.');
                      }

                      final vehicles = snapshot.data!;
                      return DropdownButtonFormField<Vehicle>(
                        decoration:
                            const InputDecoration(labelText: 'Välj fordon'),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem<Vehicle>(
                            value: vehicle,
                            child: Text(vehicle.regNumber),
                          );
                        }).toList(),
                        onChanged: (vehicle) {
                          selectedVehicle = vehicle;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ParkingSpace>>(
                    future:
                        ParkingSpaceRepository.instance.getAllParkingSpaces(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                            'Fel vid hämtning av parkeringsplatser: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                            'Inga parkeringsplatser tillgängliga.');
                      }

                      final parkingSpaces = snapshot.data!;
                      return DropdownButtonFormField<ParkingSpace>(
                        decoration: const InputDecoration(
                            labelText: 'Välj parkeringsplats'),
                        items: parkingSpaces.map((parkingSpace) {
                          return DropdownMenuItem<ParkingSpace>(
                            value: parkingSpace,
                            child: Text(parkingSpace.address),
                          );
                        }).toList(),
                        onChanged: (parkingSpace) {
                          selectedParkingSpace = parkingSpace;
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
                onPressed: () async {
                  final updatedParking = Parking(
                    id: parking.id,
                    startTime: DateTime.parse(startTimeController.text),
                    endTime: DateTime.parse(endTimeController.text),
                    vehicle: selectedVehicle!,
                    parkingSpace: selectedParkingSpace!,
                  );

                  context.read<ParkingsBloc>().add(EditParkingEvent(
                      parkingId: (parking.id), parking: updatedParking));

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

void _showDeleteConfirmationDialog(BuildContext context, Parking parking) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Bekräfta borttagning"),
        content: Text(
          "Är du säker på att du vill ta bort parkeringen med ID ${parking.id}?",
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
              context
                  .read<ParkingsBloc>()
                  .add(DeleteParkingEvent((parking.id)));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Parkering borttagen."),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Ta bort"),
          ),
        ],
      );
    },
  );
}
