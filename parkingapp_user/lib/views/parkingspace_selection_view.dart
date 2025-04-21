import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:flutter/material.dart';
import 'package:parkingapp_user/repository/notification_repository.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/blocs/parking_space/parking_space_bloc.dart';

class ParkingSpaceSelectionView extends StatelessWidget {
  final NotificationRepository notificationRepository;

  const ParkingSpaceSelectionView({
    super.key,
    required this.notificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ParkingSpaceBloc(
        parkingSpaceRepository: ParkingSpaceRepository.instance,
        parkingRepository: ParkingRepository.instance,
        personRepository: PersonRepository.instance,
        vehicleRepository: VehicleRepository.instance,
        notificationRepository: notificationRepository,
      )..add(const LoadParkingSpaces()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Välj en Parkeringsplats"),
        ),
        body: BlocListener<ParkingSpaceBloc, ParkingSpaceState>(
          listener: (context, state) {
            if (state is ParkingEnded) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Parkeringen avslutad'),
                  content: Text(
                    'Parkeringstid: ${state.totalMinutes} minuter\n'
                    'Total kostnad: ${state.totalPrice.toStringAsFixed(2)} SEK',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ).then((_) {
                // ignore: use_build_context_synchronously
                context.read<ParkingSpaceBloc>().add(const LoadParkingSpaces());
              });
            } else if (state is ParkingSpaceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fel: ${state.message}')),
              );
            }
          },
          child: BlocConsumer<ParkingSpaceBloc, ParkingSpaceState>(
            listener: (context, state) {
              // Additional listeners can be added here
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

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  //color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: ID and address info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parkeringsplats ID: ${parkingSpace.id}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('Address: ${parkingSpace.address}'),
                          Text(
                              'Pris per timme: ${parkingSpace.pricePerHour} SEK'),
                        ],
                      ),
                    ),

                    // Right side: Buttons at bottom right
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _SelectButton(
                          isSelected: isSelected,
                          isParkingActive: isParkingActive,
                          parkingSpace: parkingSpace,
                        ),
                        const SizedBox(height: 8),
                        if (isSelected)
                          _ToggleParkingButton(
                              isParkingActive: isParkingActive),
                      ],
                    ),
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
          //ignore: deprecated_member_use
          ? Colors.red.withOpacity(0.2)
          // ignore: deprecated_member_use
          : Colors.green.withOpacity(0.2),
      child: Text(
        isParkingActive
            ? 'Du startade parkeringen på:\nParkeringsplats ID: ${selectedSpace.id}\nAddress: ${selectedSpace.address}\nPris per timme: ${selectedSpace.pricePerHour} SEK'
            : 'Vald parkeringsplats:\nID: ${selectedSpace.id}\nAddress: ${selectedSpace.address}',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Stoppa parkeringen först"),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        final selectedVehicle = prefs.getString('selectedVehicle');
        if (selectedVehicle == null) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Välj först ett fordon "),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        // ignore: use_build_context_synchronously
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

class _ToggleParkingButton extends StatelessWidget {
  final bool isParkingActive;

  const _ToggleParkingButton({required this.isParkingActive});

  Future<int?> _showParkingTimeDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ange parkeringstid'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Parkeringstid i minuter',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Starta'),
              onPressed: () {
                final input = controller.text;
                if (input.isNotEmpty) {
                  final minutes = int.tryParse(input);
                  if (minutes != null && minutes > 0) {
                    Navigator.of(dialogContext).pop(minutes);
                    return;
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final bloc = context.read<ParkingSpaceBloc>();
        if (!isParkingActive) {
          final prefs = await SharedPreferences.getInstance();
          final selectedVehicle = prefs.getString('selectedVehicle');
          if (selectedVehicle == null) {
            //ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Välj först ett fordon innan du startar parkeringen."),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          // Add permission check first
          final allowed = await _handleNotificationPermissions(context);
          if (!allowed) return;

          //ignore: use_build_context_synchronously
          final parkingTime = await _showParkingTimeDialog(context);
          if (parkingTime != null) {
            bloc.add(StartParking(parkingTime));
          }
        } else {
          bloc.add(StopParking());
          //context.read<ParkingSpaceBloc>().add(const LoadParkingSpaces());
          bloc.add(const LoadParkingSpaces());
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isParkingActive ? Colors.red : Colors.orange,
      ),
      child: Text(isParkingActive ? "Stoppa" : "Starta"),
    );
  }

  Future<bool> _handleNotificationPermissions(BuildContext context) async {
    // Access through the public getter
    final bloc = context.read<ParkingSpaceBloc>();
    final repo = bloc.notificationRepository;

    if (await repo.hasPermission()) return true;

    await repo.requestPermissions();

    if (!await repo.hasPermission()) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notifikationer Krävs'),
          content: const Text('Aktivera notifikationer i inställningarna'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}




    // return ListTile(
              //   title: Text(
              //     'Parkeringsplats ID: ${parkingSpace.id}',
              //     style: const TextStyle(
              //         fontSize: 18, fontWeight: FontWeight.w500),
              //   ),
              //   subtitle: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text('Address: ${parkingSpace.address}'),
              //       Text('Pris per timme: ${parkingSpace.pricePerHour} SEK'),
              //     ],
              //   ),
              //   trailing: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       _SelectButton(
              //         isSelected: isSelected,
              //         isParkingActive: isParkingActive,
              //         parkingSpace: parkingSpace,
              //       ),
              //       const SizedBox(width: 10),
              //       if (isSelected)
              //         _ToggleParkingButton(isParkingActive: isParkingActive),
              //     ],
              //   ),
              // );


                // void _showExtendDialog(BuildContext context) {
  //   final controller = TextEditingController();
  //   final formKey = GlobalKey<FormState>();

  //   showDialog(
  //     context: context,
  //     builder: (context) => Form(
  //       key: formKey,
  //       child: AlertDialog(
  //         title: const Text('Förläng Parkeringstid'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text('Ange antal minuter att förlänga (15-240):'),
  //             const SizedBox(height: 16),
  //             TextFormField(
  //               controller: controller,
  //               keyboardType: TextInputType.number,
  //               autofocus: true,
  //               maxLength: 3,
  //               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Ange antal minuter';
  //                 }
  //                 final minutes = int.tryParse(value);
  //                 if (minutes == null || minutes < 15 || minutes > 240) {
  //                   return 'Minst 15, max 240 minuter';
  //                 }
  //                 return null;
  //               },
  //               decoration: const InputDecoration(
  //                 hintText: '30',
  //                 suffixText: 'minuter',
  //                 border: OutlineInputBorder(),
  //                 counterText: '',
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Avbryt'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (formKey.currentState?.validate() ?? false) {
  //                 final minutes = int.parse(controller.text);
  //                 context
  //                     .read<ParkingSpaceBloc>()
  //                     .add(ExtendParking(additionalMinutes: minutes));
  //                 context
  //                     .read<ParkingSpaceBloc>()
  //                     .add(const LoadParkingSpaces());
  //                 Navigator.pop(context);
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green[700],
  //             ),
  //             child:
  //                 const Text('Förläng', style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


    // void _showDurationDialog(BuildContext context) {
  //   final controller = TextEditingController();
  //   final formKey = GlobalKey<FormState>();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Parkeringstid'),
  //       content: Form(
  //         key: formKey,
  //         child: TextFormField(
  //           controller: controller,
  //           keyboardType: TextInputType.number,
  //           autofocus: true,
  //           validator: (value) {
  //             if (value == null || value.isEmpty) return 'Ange antal minuter';
  //             final minutes = int.tryParse(value);
  //             if (minutes == null || minutes < 15) return 'Minst 15 minuter';
  //             return null;
  //           },
  //           decoration: const InputDecoration(
  //             labelText: 'Antal minuter',
  //             suffixText: 'minuter',
  //             border: OutlineInputBorder(),
  //           ),
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Avbryt'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             if (formKey.currentState?.validate() ?? false) {
  //               final minutes = int.parse(controller.text);
  //               context.read<ParkingSpaceBloc>().add(
  //                     StartParking(parkingDurationInMinutes: minutes),
  //                   );
  //               // Dispatch a refresh event after a short delay to allow state update.
  //               Future.delayed(const Duration(milliseconds: 200), () {
  //                 // ignore: use_build_context_synchronously
  //                 context
  //                     .read<ParkingSpaceBloc>()
  //                     .add(const LoadParkingSpaces(forceRefresh: true));
  //               });
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('Parkering startad för $minutes minuter'),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );
  //               Navigator.pop(context);
  //             }
  //           },
  //           child: const Text('Starta'),
  //         ),
  //       ],
  //     ),
  //   );
  // }