import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/blocs/parking_space/parking_space_bloc.dart'; // Import your Bloc files

class ParkingSpaceSelectionScreen extends StatelessWidget {
  const ParkingSpaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ParkingSpaceBloc(
        parkingSpaceRepository: ParkingSpaceRepository.instance,
        parkingRepository: ParkingRepository.instance,
        personRepository: PersonRepository.instance,
        vehicleRepository: VehicleRepository.instance,
      )..add(LoadParkingSpaces()), // Adjusted event name
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Välj en Parkeringsplats"),
        ),
        body: BlocConsumer<ParkingSpaceBloc, ParkingSpaceState>(
          listener: (context, state) {
            if (state is ParkingSpaceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fel: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is ParkingSpaceLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ParkingSpaceLoaded) {
              return _ParkingSpaceListView(
                parkingSpaces: state.parkingSpaces,
                selectedSpace: state.selectedParkingSpace,
                isParkingActive: state.isParkingActive,
              );
            }
            return const Center(
              child: Text(
                'Inga parkeringsplatser tillgängliga.',
                style: TextStyle(fontSize: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParkingSpaceListView extends StatelessWidget {
  final List<ParkingSpace> parkingSpaces;
  final ParkingSpace? selectedSpace;
  final bool isParkingActive;

  const _ParkingSpaceListView({
    required this.parkingSpaces,
    required this.selectedSpace,
    required this.isParkingActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selectedSpace != null)
          _SelectedSpaceInfo(
            selectedSpace: selectedSpace!,
            isParkingActive: isParkingActive,
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: parkingSpaces.length,
            itemBuilder: (context, index) {
              final parkingSpace = parkingSpaces[index];
              final isSelected = selectedSpace?.id == parkingSpace.id;

              return ListTile(
                title: Text(
                  'Parkeringsplats ID: ${parkingSpace.id}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address: ${parkingSpace.address}'),
                    Text('Pris per timme: ${parkingSpace.pricePerHour} SEK'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SelectButton(
                      isSelected: isSelected,
                      isParkingActive: isParkingActive,
                      parkingSpace: parkingSpace,
                    ),
                    const SizedBox(width: 10),
                    if (isSelected)
                      _ToggleParkingButton(isParkingActive: isParkingActive),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(
              thickness: 1,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedSpaceInfo extends StatelessWidget {
  final ParkingSpace selectedSpace;
  final bool isParkingActive;

  const _SelectedSpaceInfo({
    required this.selectedSpace,
    required this.isParkingActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: isParkingActive
          // ignore: deprecated_member_use
          ? Colors.red.withOpacity(0.2)
          // ignore: deprecated_member_use
          : Colors.green.withOpacity(0.2),
      child: Text(
        isParkingActive
            ? 'Du startade parkeringen på:\n'
                'Parkeringsplats ID: ${selectedSpace.id}\n'
                'Address: ${selectedSpace.address}\n'
                'Pris per timme: ${selectedSpace.pricePerHour} SEK'
            : 'Vald parkeringsplats:\n'
                'ID: ${selectedSpace.id}\n'
                'Address: ${selectedSpace.address}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isSelected;
  final bool isParkingActive;
  final ParkingSpace parkingSpace;

  const _SelectButton({
    required this.isSelected,
    required this.isParkingActive,
    required this.parkingSpace,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (isParkingActive && !isSelected) {
          // Parking is active, display a Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Stoppa parkeringen först"),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }

        // Check for selected vehicle
        final prefs = await SharedPreferences.getInstance();
        final selectedVehicle = prefs.getString('selectedVehicle');
        if (selectedVehicle == null) {
          // No vehicle selected, display a Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Välj först ett fordon "),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }

        // Dispatch the appropriate event
        final bloc = context.read<ParkingSpaceBloc>();
        if (isSelected) {
          bloc.add(DeselectParkingSpace());
        } else {
          bloc.add(SelectParkingSpace(parkingSpace));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[800],
      ),
      child: Text(isSelected ? "Valt" : "Välj"),
    );
  }
}

// class _ToggleParkingButton extends StatelessWidget {
//   final bool isParkingActive;

//   const _ToggleParkingButton({required this.isParkingActive});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () {
//         final bloc = context.read<ParkingSpaceBloc>();
//         if (isParkingActive) {
//           bloc.add(StopParking());
//         } else {
//           bloc.add(StartParking());
//         }
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isParkingActive ? Colors.red : Colors.orange,
//       ),
//       child: Text(isParkingActive ? "Stoppa Parkering" : "Starta Parkering"),
//     );
//   }
// }

class _ToggleParkingButton extends StatelessWidget {
  final bool isParkingActive;

  const _ToggleParkingButton({required this.isParkingActive});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (!isParkingActive) {
          // Check for selected vehicle before starting parking
          final prefs = await SharedPreferences.getInstance();
          final selectedVehicle = prefs.getString('selectedVehicle');

          if (selectedVehicle == null) {
            // No vehicle selected, show Snackbar error
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Välj först ett fordon innan du startar parkeringen."),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }

        // Dispatch the appropriate event
        final bloc = context.read<ParkingSpaceBloc>();
        if (isParkingActive) {
          bloc.add(StopParking());
        } else {
          bloc.add(StartParking());
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isParkingActive ? Colors.red : Colors.orange,
      ),
      child: Text(isParkingActive ? "Stoppa Parkering" : "Starta Parkering"),
    );
  }
}
