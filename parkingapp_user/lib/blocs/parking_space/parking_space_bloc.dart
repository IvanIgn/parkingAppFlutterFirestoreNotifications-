import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:parkingapp_user/main.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:parkingapp_user/repository/notification_repository.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'parking_space_event.dart';
part 'parking_space_state.dart';

class ParkingSpaceBloc extends Bloc<ParkingSpaceEvent, ParkingSpaceState> {
  NotificationRepository get notificationRepository => _notificationRepo;
  static const _notificationIds = [100, 101, 102];
  final ParkingSpaceRepository _parkingSpaceRepo;
  final PersonRepository _personRepo;
  final ParkingRepository _parkingRepo;
  final VehicleRepository _vehicleRepo;
  final NotificationRepository _notificationRepo;
  Timer? _parkingTimer;
  DateTime? _calculatedEndTime;
  final bool _extensionDialogShown = false;

  ParkingSpaceBloc({
    required ParkingSpaceRepository parkingSpaceRepository,
    required ParkingRepository parkingRepository,
    required PersonRepository personRepository,
    required VehicleRepository vehicleRepository,
    required NotificationRepository notificationRepository,
  })  : _parkingSpaceRepo = parkingSpaceRepository,
        _personRepo = personRepository,
        _parkingRepo = parkingRepository,
        _vehicleRepo = vehicleRepository,
        _notificationRepo = notificationRepository,
        super(ParkingSpaceInitial()) {
    tz.initializeTimeZones();

    on<LoadParkingSpaces>(_onLoadParkingSpaces);
    on<SelectParkingSpace>(_onSelectParkingSpace);
    on<StartParking>(_onStartParking);
    on<StopParking>(_onStopParking);
    on<DeselectParkingSpace>(_onDeselectParkingSpace);
    on<ExtendParking>(_onExtendParking);
    on<RefreshParkingSpaces>(_onRefreshParkingSpaces);
  }

  @override
  Future<void> close() {
    _parkingTimer?.cancel();
    for (final id in _notificationIds) {
      _notificationRepo.cancelScheduledNotification(id);
    }
    return super.close();
  }

  Future<void> _onRefreshParkingSpaces(
    RefreshParkingSpaces event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    if (state is ParkingSpaceLoaded) {
      final currentState = state as ParkingSpaceLoaded;
      emit(currentState.copyWith(refreshTrigger: !currentState.refreshTrigger));
    }
  }

  Future<void> _onExtendParking(
    ExtendParking event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parkingJson = prefs.getString('parking');

      if (parkingJson != null) {
        final parking = Parking.fromJson(jsonDecode(parkingJson));
        final newEndTime =
            parking.endTime.add(Duration(minutes: event.additionalMinutes));

        // Update parking record
        final updatedParking = parking.copyWith(endTime: newEndTime);
        await _parkingRepo.updateParking(updatedParking.id, updatedParking);
        await prefs.setString('parking', jsonEncode(updatedParking.toJson()));

        // Update state
        _updateParkingState(emit, newEndTime);
        add(const LoadParkingSpaces());

        // Notifications
        await _handleParkingNotifications(newEndTime);
      }
    } catch (e, stackTrace) {
      _handleError(emit, 'Extension Error', e, stackTrace);
    }
  }

  Future<ParkingSpace?> _getSelectedParkingSpace(
      SharedPreferences prefs) async {
    try {
      final parkingSpaceJson = prefs.getString('selectedParkingSpace');
      if (parkingSpaceJson == null) return null;
      return ParkingSpace.fromJson(jsonDecode(parkingSpaceJson));
    } catch (e) {
      debugPrint('Error loading selected parking space: $e');
      return null;
    }
  }

  Future<Vehicle> _getSelectedVehicle(SharedPreferences prefs) async {
    try {
      final vehicleJson = prefs.getString('selectedVehicle');
      if (vehicleJson == null) {
        throw Exception('Inget valt fordon hittades');
      }
      return Vehicle.fromJson(jsonDecode(vehicleJson));
    } catch (e) {
      debugPrint('Get Selected Vehicle Error: $e');
      throw Exception('Fel vid hämtning av fordonsdata');
    }
  }

  Future<Person> _getLoggedInPerson(SharedPreferences prefs) async {
    try {
      final personJson = prefs.getString('loggedInPerson');
      if (personJson == null) {
        throw Exception('Ingen inloggad användare hittades');
      }
      return Person.fromJson(jsonDecode(personJson));
    } catch (e) {
      debugPrint('Get Logged In Person Error: $e');
      throw Exception('Fel vid hämtning av användardata');
    }
  }

  Future<ParkingSpace?> _loadSelectedParkingSpace(
      SharedPreferences prefs) async {
    try {
      final json = prefs.getString('selectedParkingSpace');
      return json != null ? ParkingSpace.fromJson(jsonDecode(json)) : null;
    } catch (e) {
      debugPrint('Error loading selected parking space: $e');
      return null;
    }
  }

  Future<DateTime?> _loadParkingEndTime(SharedPreferences prefs) async {
    try {
      final parkingJson = prefs.getString('parking');
      if (parkingJson == null) return null;
      return Parking.fromJson(jsonDecode(parkingJson)).endTime;
    } catch (e) {
      debugPrint('Error loading parking end time: $e');
      return null;
    }
  }

  Future<void> _onLoadParkingSpaces(
    LoadParkingSpaces event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    emit(ParkingSpaceLoading());
    try {
      final parkingSpaces = await _parkingSpaceRepo.getAllParkingSpaces();
      final prefs = await SharedPreferences.getInstance();

      final selectedSpace = await _loadSelectedParkingSpace(prefs);
      final isActive = prefs.getBool('isParkingActive') ?? false;
      _calculatedEndTime = await _loadParkingEndTime(prefs);

      emit(ParkingSpaceLoaded(
        parkingSpaces: parkingSpaces,
        selectedParkingSpace: selectedSpace,
        isParkingActive: isActive,
        endTime: _calculatedEndTime,
      ));

      if (isActive && _calculatedEndTime != null) {
        if (DateTime.now().isAfter(_calculatedEndTime!)) {
          add(StopParking());
        } else {
          _startAutoStopTimer();
        }
      }
    } catch (e, stackTrace) {
      _handleError(emit, 'Load Error', e, stackTrace);
    }
  }

  Future<void> _onStartParking(
    StartParking event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      // Request notification permissions first
      final notificationAllowed = await _handleNotificationPermissions();
      if (!notificationAllowed) {
        emit(const ParkingSpaceError(
            'Notification permissions required to start parking'));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final person = await _getLoggedInPerson(prefs);
      final vehicle = await _getSelectedVehicle(prefs);
      final parkingSpace = await _getSelectedParkingSpace(prefs);

      if (parkingSpace == null) {
        emit(const ParkingSpaceError('No parking space selected'));
        return;
      }
      // Use timezone-aware datetime

      final startTime = tz.TZDateTime.now(tz.local);
      _calculatedEndTime =
          startTime.add(Duration(minutes: event.parkingDurationInMinutes));

      debugPrint('''
===== PARKING STARTED =====
Local Start Time: ${startTime.toLocal()}
Local End Time:   ${_calculatedEndTime!.toLocal()}
Timezone:         ${tz.local.name}
UTC Offset:       ${startTime.timeZoneOffset.inHours} hours
=======================
''');

      // startTime = tz.TZDateTime.from(DateTime.now(), tz.local);
      // _calculatedEndTime =
      //     startTime.add(Duration(minutes: event.parkingDurationInMinutes));

      // Validate parking duration
      if (event.parkingDurationInMinutes < 1) {
        emit(const ParkingSpaceError('Minimum parking duration is 1 minute'));
        return;
      }

      final parking = Parking(
        vehicle: vehicle.copyWith(owner: person),
        parkingSpace: parkingSpace,
        startTime: startTime,
        endTime: _calculatedEndTime!,
      );

      // Update parking space status
      await _parkingSpaceRepo.updateParkingSpace(
        parkingSpace.id,
        parkingSpace.copyWith(isOccupied: true),
      );

      // Persist parking data
      await _parkingRepo.createParking(parking);
      await prefs.setBool('isParkingActive', true);
      await prefs.setString('parking', jsonEncode(parking.toJson()));

      // Update state
      final parkingSpaces = await _parkingSpaceRepo.getAllParkingSpaces();
      emit(ParkingSpaceLoaded(
        parkingSpaces: parkingSpaces,
        selectedParkingSpace: parkingSpace,
        isParkingActive: true,
        endTime: _calculatedEndTime,
        updateTime: DateTime.now().millisecondsSinceEpoch,
      ));

      // Schedule notifications first
      await _handleParkingNotifications(_calculatedEndTime!);

      // Start monitoring timer after notifications are scheduled
      _startAutoStopTimer();

      // Show instant confirmation notification
      await _notificationRepo.showInstantNotification(
          'Parking started at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}');

      debugPrint('''
    ===== PARKING STARTED =====
    Start Time:   $startTime
    End Time:     $_calculatedEndTime
    Duration:     ${event.parkingDurationInMinutes} minutes
    Vehicle:      ${vehicle.regNumber}
    Space:        ${parkingSpace.id}
    ===========================
    ''');
    } catch (e, stackTrace) {
      _handleError(emit, 'Start Error', e, stackTrace);
    }
  }

  Future<bool> _handleNotificationPermissions() async {
    try {
      if (await _notificationRepo.hasPermission()) return true;

      await _notificationRepo.requestPermissions();

      if (await _notificationRepo.hasPermission()) return true;

      if (Platform.isIOS) {
        // Use a navigator key from your app's root
        final context = navigatorKey.currentContext;
        if (context != null) {
          await showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Notifications Required'),
              content: const Text(
                  'Please enable notifications in Settings > Notifications'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
      return false;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<void> _onStopParking(
    StopParking event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      _parkingTimer?.cancel();
      _calculatedEndTime = null;
      final prefs = await SharedPreferences.getInstance();
      final parkingJson = prefs.getString('parking');

      if (parkingJson != null) {
        final parking = Parking.fromJson(jsonDecode(parkingJson));
        final actualEndTime = DateTime.now();

        // Update parking space status
        await _parkingSpaceRepo.updateParkingSpace(
          parking.parkingSpace!.id,
          parking.parkingSpace!.copyWith(isOccupied: false),
        );

        // Calculate costs
        final duration = actualEndTime.difference(parking.startTime);
        final totalPrice =
            (duration.inMinutes / 60) * parking.parkingSpace!.pricePerHour;

        // Update parking record
        final updatedParking = parking.copyWith(endTime: actualEndTime);
        await _parkingRepo.updateParking(updatedParking.id, updatedParking);
        await _parkingRepo.deleteParking(parking.id);

        // Clear local data
        await prefs.remove('isParkingActive');
        await prefs.remove('parking');

        // Emit final state
        emit(ParkingEnded(
          totalMinutes: duration.inMinutes,
          totalPrice: totalPrice,
          parking: updatedParking,
        ));

        // Force full refresh
        add(const LoadParkingSpaces());

        // Handle notifications
        for (final id in _notificationIds) {
          await _notificationRepo.cancelScheduledNotification(id);
        }
        await _notificationRepo.scheduleNotification(
          title: "Parkeringsavslut",
          content: "Din parkering har avslutats",
          deliveryTime: actualEndTime,
          id: 0,
        );
      }
    } catch (e, stackTrace) {
      _handleError(emit, 'Stop Error', e, stackTrace);
    }
  }

  // Helper methods

  void _updateParkingState(
      Emitter<ParkingSpaceState> emit, DateTime newEndTime) {
    _calculatedEndTime = newEndTime;
    if (state is ParkingSpaceLoaded) {
      final currentState = state as ParkingSpaceLoaded;
      emit(currentState.copyWith(endTime: newEndTime));
    }
  }

  Future<void> _handleParkingNotifications(DateTime endTime) async {
    try {
      // Clear existing notifications first
      for (final id in _notificationIds) {
        await _notificationRepo.cancelScheduledNotification(id);
        debugPrint('Cancelled notification $id');
      }

      // Schedule new reminders with proper timezone handling
      final reminders = [
        _NotificationConfig(1, "1 minute remaining"),
        _NotificationConfig(5, "5 minutes remaining"),
        _NotificationConfig(10, "10 minutes remaining"),
      ];

      final now = DateTime.now();

      for (final reminder in reminders) {
        final notifyTime =
            endTime.subtract(Duration(minutes: reminder.minutes));

        // Only schedule if in the future and parking hasn't ended
        if (notifyTime.isAfter(now) && endTime.isAfter(now)) {
          await _notificationRepo.scheduleNotification(
            title: "Parking Reminder",
            content: reminder.message,
            deliveryTime: notifyTime,
            id: _notificationIds[reminders.indexOf(reminder)],
          );
          debugPrint(
              '» Scheduled ${reminder.minutes}m reminder for $notifyTime');
        }
      }
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
    }
  }

  Future<void> _onSelectParkingSpace(
    SelectParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      if (state is! ParkingSpaceLoaded) return;
      final currentState = state as ParkingSpaceLoaded;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'selectedParkingSpace',
        jsonEncode(event.parkingSpace.toJson()),
      );

      emit(currentState.copyWith(
        selectedParkingSpace: event.parkingSpace,
      ));
    } catch (e, stackTrace) {
      debugPrint('Select Parking Space Error: $e\n$stackTrace');
      emit(const ParkingSpaceError('Kunde inte välja parkeringsplats'));
    }
  }

  Future<void> _onDeselectParkingSpace(
    DeselectParkingSpace event,
    Emitter<ParkingSpaceState> emit,
  ) async {
    try {
      if (state is! ParkingSpaceLoaded) return;
      final currentState = state as ParkingSpaceLoaded;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selectedParkingSpace');

      emit(currentState.copyWith(
        selectedParkingSpace: null,
      ));
    } catch (e, stackTrace) {
      debugPrint('Deselect Parking Space Error: $e\n$stackTrace');
      emit(const ParkingSpaceError('Kunde inte avmarkera parkeringsplats'));
    }
  }

  void _startAutoStopTimer() {
    _parkingTimer?.cancel();
    _parkingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_calculatedEndTime == null ||
          DateTime.now().isAfter(_calculatedEndTime!)) {
        timer.cancel();
        add(StopParking());

        // Refresh notifications when parking ends
        if (state is ParkingSpaceLoaded) {
          await _handleParkingNotifications(DateTime.now());
        }
      }
    });
  }

  void _handleError(Emitter<ParkingSpaceState> emit, String context,
      dynamic error, StackTrace stackTrace) {
    debugPrint('$context: $error\n$stackTrace');
    emit(ParkingSpaceError('Operation failed: ${error.toString()}'));
    add(const LoadParkingSpaces());
  }
}

class _NotificationConfig {
  final int minutes;
  final String message;

  _NotificationConfig(this.minutes, this.message);
}



  // Future<bool> _handleNotificationPermissions(BuildContext context) async {
  //   try {
  //     // First check current status
  //     if (await _notificationRepo.hasPermission()) return true;

  //     // Request if not granted
  //     await _notificationRepo.requestPermissions();

  //     // Check again after requesting
  //     if (await _notificationRepo.hasPermission()) return true;

  //     // Show guidance if permanently denied
  //     if (Platform.isIOS) {
  //       await showDialog(
  //         // ignore: use_build_context_synchronously
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: const Text('Notifications Required'),
  //           content: const Text(
  //               'Please enable notifications in Settings > Notifications'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('Permission check error: $e');
  //     return false;
  //   }
  // }


 // Future<void> _onStartParking(
  //   StartParking event,
  //   Emitter<ParkingSpaceState> emit,
  // ) async {
  //   try {
  //     // Remove or comment out this line if you don't want a loading spinner:
  //     // emit(ParkingSpaceLoading());

  //     final prefs = await SharedPreferences.getInstance();
  //     final person = await _getLoggedInPerson(prefs);
  //     final vehicle = await _getSelectedVehicle(prefs);
  //     final parkingSpace = await _getSelectedParkingSpace(prefs);
  //     if (parkingSpace == null) {
  //       throw Exception('Ingen parkeringsplats vald');
  //     }

  //     final startTime = DateTime.now();
  //     _calculatedEndTime =
  //         startTime.add(Duration(minutes: event.parkingDurationInMinutes));
  //     final parking = Parking(
  //       vehicle: vehicle.copyWith(owner: person),
  //       parkingSpace: parkingSpace,
  //       startTime: startTime,
  //       endTime: _calculatedEndTime!,
  //     );

  //     // Update parking space status.
  //     await _parkingSpaceRepo.updateParkingSpace(
  //       parkingSpace.id,
  //       parkingSpace.copyWith(isOccupied: true),
  //     );

  //     // Save the parking data.
  //     await _parkingRepo.createParking(parking);
  //     await prefs.setBool('isParkingActive', true);
  //     await prefs.setString('parking', jsonEncode(parking.toJson()));
  //     final parkingSpaces = await _parkingSpaceRepo.getAllParkingSpaces();

  //     // Force a new state by including an updated timestamp.
  //     emit(ParkingSpaceLoaded(
  //       parkingSpaces: parkingSpaces,
  //       selectedParkingSpace: parkingSpace,
  //       isParkingActive: true,
  //       endTime: _calculatedEndTime,
  //       updateTime: DateTime.now().millisecondsSinceEpoch,
  //     ));

  //     // Start auto-stop timer and handle notifications.
  //     _startAutoStopTimer();
  //     // refresh notifications when time is extended

  //     if (_calculatedEndTime != null) {
  //       await _handleParkingNotifications(_calculatedEndTime!, false);
  //       await _notificationRepo.requestPermissions();
  //       await _notificationRepo.scheduleNotification(
  //         title: "Parkeringspåminnelse",
  //         content: "Din parkering har startat",
  //         deliveryTime: startTime,
  //         id: 0,
  //       );
  //     } else {
  //       debugPrint('Calculated end time is null');
  //       (await NotificationRepository.instance).cancelScheduledNotification(0);
  //     }
  //   } catch (e, stackTrace) {
  //     _handleError(emit, 'Start Error', e, stackTrace);
  //   }
  // }


    // Future<void> _onStartParking(
  //   StartParking event,
  //   Emitter<ParkingSpaceState> emit,
  // ) async {
  //   try {
  //     // Request notification permissions first
  //     final notificationAllowed = await _handleNotificationPermissions();
  //     if (!notificationAllowed) {
  //       emit(const ParkingSpaceError(
  //           'Notification permissions required to start parking'));
  //       return;
  //     }

  //     final prefs = await SharedPreferences.getInstance();
  //     final person = await _getLoggedInPerson(prefs);
  //     final vehicle = await _getSelectedVehicle(prefs);
  //     final parkingSpace = await _getSelectedParkingSpace(prefs);

  //     if (parkingSpace == null) {
  //       emit(const ParkingSpaceError('No parking space selected'));
  //       return;
  //     }

  //     final startTime = DateTime.now();
  //     _calculatedEndTime =
  //         startTime.add(Duration(minutes: event.parkingDurationInMinutes));

  //     final parking = Parking(
  //       vehicle: vehicle.copyWith(owner: person),
  //       parkingSpace: parkingSpace,
  //       startTime: startTime,
  //       endTime: _calculatedEndTime!,
  //     );

  //     // Update parking space status
  //     await _parkingSpaceRepo.updateParkingSpace(
  //       parkingSpace.id,
  //       parkingSpace.copyWith(isOccupied: true),
  //     );

  //     // Persist parking data
  //     await _parkingRepo.createParking(parking);
  //     await prefs.setBool('isParkingActive', true);
  //     await prefs.setString('parking', jsonEncode(parking.toJson()));

  //     // Update state
  //     final parkingSpaces = await _parkingSpaceRepo.getAllParkingSpaces();
  //     emit(ParkingSpaceLoaded(
  //       parkingSpaces: parkingSpaces,
  //       selectedParkingSpace: parkingSpace,
  //       isParkingActive: true,
  //       endTime: _calculatedEndTime,
  //       updateTime: DateTime.now().millisecondsSinceEpoch,
  //     ));

  //     // Start monitoring and notifications
  //     _startAutoStopTimer();
  //     await _handleParkingNotifications(_calculatedEndTime!);

  //     // Show instant confirmation notification
  //     await _notificationRepo.showInstantNotification(
  //         'Parking started at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}');
  //   } catch (e, stackTrace) {
  //     _handleError(emit, 'Start Error', e, stackTrace);
  //   }
  // }



// void _startAutoStopTimer() {
  //   _parkingTimer?.cancel();
  //   _parkingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_calculatedEndTime == null ||
  //         DateTime.now().isAfter(_calculatedEndTime!)) {
  //       timer.cancel();
  //       add(StopParking());
  //     }
  //   });
  // }