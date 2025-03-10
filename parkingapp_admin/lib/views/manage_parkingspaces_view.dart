import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_admin/blocs/parking_space/parking_space_bloc.dart';
import 'package:shared/shared.dart';

class ManageParkingSpacesView extends StatefulWidget {
  const ManageParkingSpacesView({super.key});

  @override
  _ManageParkingSpacesViewState createState() =>
      _ManageParkingSpacesViewState();
}

class _ManageParkingSpacesViewState extends State<ManageParkingSpacesView> {
  @override
  void initState() {
    super.initState();
    // Trigger fetching persons when the view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingSpaceBloc>().add(const LoadParkingSpaces());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hantera parkeringsplatser"),
      ),
      body: BlocBuilder<ParkingSpaceBloc, ParkingSpaceState>(
        builder: (context, state) {
          if (state is ParkingSpaceLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ParkingSpaceError) {
            return Center(
              child: Text(
                'Fel vid hämtning av data: ${state.message}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (state is ParkingSpaceLoaded) {
            final parkingSpacesList = state.parkingSpaces;

            if (parkingSpacesList.isEmpty) {
              return const Center(
                child: Text(
                  'Inga parkeringsplatser tillgängliga.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: parkingSpacesList.length,
              itemBuilder: (context, index) {
                final parkingSpace = parkingSpacesList[index];
                return ListTile(
                  title: Text(
                    'Parkeringsplats ID: ${parkingSpace.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adress: ${parkingSpace.address}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Price per timme: ${parkingSpace.pricePerHour} SEK',
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
                          _showEditParkingSpaceDialog(context, parkingSpace);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteParkingSpaceDialog(context, parkingSpace);
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
          _showAddParkingSpaceDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddParkingSpaceDialog(BuildContext context) {
    final addressController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Lägga till parkeringsplats"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Pris per timme"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Avbryta"),
            ),
            ElevatedButton(
              onPressed: () {
                final newSpace = ParkingSpace(
                  address: addressController.text,
                  pricePerHour: int.tryParse(priceController.text) ?? 0,
                );
                context.read<ParkingSpaceBloc>().add(AddParkingSpace(newSpace));
                Navigator.of(context).pop();
                // context.read<ParkingSpaceBloc>().add(LoadParkingSpaces());
              },
              child: const Text("Spara"),
            ),
          ],
        );
      },
    );
  }

  void _showEditParkingSpaceDialog(
      BuildContext context, ParkingSpace parkingSpace) {
    final addressController = TextEditingController(text: parkingSpace.address);
    final priceController =
        TextEditingController(text: parkingSpace.pricePerHour.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ändra parkeringsplats"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Pris per timme"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Avbryta"),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedSpace = ParkingSpace(
                  id: parkingSpace.id,
                  address: addressController.text,
                  pricePerHour: int.tryParse(priceController.text) ??
                      parkingSpace.pricePerHour,
                );
                context
                    .read<ParkingSpaceBloc>()
                    .add(UpdateParkingSpace(updatedSpace));
                Navigator.pop(context);
              },
              child: const Text("Spara"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteParkingSpaceDialog(
      BuildContext context, ParkingSpace parkingSpace) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ta bort parkeringsplats"),
          content: Text(
              "Är du säker på att du vill ta bort parkeringsplatsen med ID: ${parkingSpace.id}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Avbryta"),
            ),
            ElevatedButton(
              onPressed: () {
                context
                    .read<ParkingSpaceBloc>()
                    .add(DeleteParkingSpace((parkingSpace.id)));
                Navigator.pop(context);
              },
              child: const Text("Ta bort"),
            ),
          ],
        );
      },
    );
  }
}
