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

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

void main() async {
  // Ensure Flutter bindings are initialized before running any code
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize SharedPreferences before `runApp()`
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;

  // Wrap the app with HydratedBlocOverrides in the same zone
  // HydratedBlocOverrides.runZoned(
  //   () {
  //     runApp(ParkingApp(prefs: prefs));
  //   },
  //   storage: storage,
  // );

  HydratedBloc.storage = storage;

  runApp(ParkingApp(prefs: prefs));
}

class ParkingApp extends StatelessWidget {
  final SharedPreferences prefs;

  const ParkingApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
          )..add(LoadActiveParkings()),
        ),
        BlocProvider<ParkingSpaceBloc>(
          create: (context) => ParkingSpaceBloc(
            parkingSpaceRepository: ParkingSpaceRepository.instance,
            parkingRepository: ParkingRepository.instance,
            personRepository: PersonRepository.instance,
            vehicleRepository: VehicleRepository.instance,
          )..add(LoadParkingSpaces()),
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
          darkTheme: ThemeData(
            brightness: Brightness.dark,
          ),
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
