import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'package:parkingapp_user/blocs/auth/auth_bloc.dart';
import 'package:parkingapp_user/blocs/person/person_bloc.dart';
import 'package:parkingapp_user/blocs/vehicle/vehicle_bloc.dart';
import 'package:parkingapp_user/blocs/parking/parking_bloc.dart';
import 'package:parkingapp_user/blocs/registration/registration_bloc.dart';
import 'package:parkingapp_user/blocs/parking_space/parking_space_bloc.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkingapp_user/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parkingapp_user/repository/notification_repository.dart';
import 'package:parkingapp_user/blocs/notifications/notification_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) return;
  tz.initializeTimeZones();
  if (Platform.isWindows) return;
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> initializeNotifications(
    FlutterLocalNotificationsPlugin plugin) async {
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = const DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await plugin.initialize(initializationSettings);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NotificationRepository before runApp
  final notificationRepository = await NotificationRepository.instance;

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize hydrated storage
  final storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;

  // Configure time zone
  await _configureLocalTimeZone();

  // Initialize FlutterLocalNotificationsPlugin (used internally by NotificationRepository)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await initializeNotifications(flutterLocalNotificationsPlugin);

  HydratedBloc.storage = storage;

  runApp(
    // Wrap your app in a RepositoryProvider for NotificationRepository
    RepositoryProvider<NotificationRepository>.value(
      value: notificationRepository,
      child: ParkingApp(
          prefs: prefs, notificationRepository: notificationRepository),
    ),
  );
}

class ParkingApp extends StatelessWidget {
  final SharedPreferences prefs;
  final NotificationRepository notificationRepository;

  const ParkingApp({
    super.key,
    required this.prefs,
    required this.notificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide NotificationBloc first so others can use it.
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(notificationRepository),
        ),
        BlocProvider<PersonBloc>(
          create: (context) => PersonBloc(repository: PersonRepository.instance)
            ..add(LoadPersons()),
        ),
        BlocProvider<VehicleBloc>(
          create: (context) =>
              VehicleBloc(VehicleRepository.instance)..add(LoadVehicles()),
        ),
        BlocProvider<ParkingBloc>(
          create: (context) => ParkingBloc(
            parkingRepository: ParkingRepository.instance,
            sharedPreferences: prefs,
            // Use the existing NotificationBloc from the widget tree:
            notificationBloc: context.read<NotificationBloc>(),
          )..add(LoadActiveParkings()),
        ),
        BlocProvider<ParkingSpaceBloc>(
          create: (context) => ParkingSpaceBloc(
            parkingSpaceRepository: ParkingSpaceRepository.instance,
            parkingRepository: ParkingRepository.instance,
            personRepository: PersonRepository.instance,
            vehicleRepository: VehicleRepository.instance,
            notificationRepository: notificationRepository,
          )..add(const LoadParkingSpaces()),
        ),
        BlocProvider<RegistrationBloc>(
          create: (context) =>
              RegistrationBloc(personRepository: PersonRepository.instance),
        ),
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(personRepository: PersonRepository.instance)
                ..add(CheckAuthStatus()),
        ),
      ],
      child: const MaterialAppWidget(),
    );
  }
}

class MaterialAppWidget extends StatelessWidget {
  const MaterialAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ParkeringsApp',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return const HomeView();
              } else if (authState is AuthLoggedOut) {
                return LoginView(
                  onLoginSuccess: () {
                    BlocProvider.of<AuthBloc>(context).add(CheckAuthStatus());
                  },
                );
              } else if (authState is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return const Center(child: Text('Unexpected state'));
              }
            },
          ),
        );
      },
    );
  }
}

void clearPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.clear();
}
