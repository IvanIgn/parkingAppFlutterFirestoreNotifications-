import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/home_view.dart';
import 'package:parkingapp_admin/blocs/person/person_bloc.dart';
import 'package:parkingapp_admin/blocs/vehicle/vehicle_bloc.dart';
import 'package:parkingapp_admin/blocs/parking/parking_bloc.dart';
import 'package:parkingapp_admin/blocs/parking_space/parking_space_bloc.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:provider/single_child_widget.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkingapp_admin/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// Define the repositories as final constants
final vehicleRepository = VehicleRepository.instance;
final parkingSpaceRepository = ParkingSpaceRepository.instance;
final parkingRepository = ParkingRepository.instance;
final personRepository = PersonRepository.instance;

// Global ValueNotifier for dark mode
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Continue app startup only if Firebase initialized
  if (Firebase.apps.isNotEmpty) {
    final storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorage.webStorageDirectory
          : await getApplicationDocumentsDirectory(),
    );

    await _initializeAppSettings();

    HydratedBlocOverrides.runZoned(
      () => runApp(const ParkingAdminApp()),
      storage: storage,
    );
  } else {
    debugPrint("Firebase did not initialize, app will not run.");
  }
}

Future<void> _initializeAppSettings() async {
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
}

Future<void> _updateDarkMode(bool isDarkMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
  isDarkModeNotifier.value = isDarkMode;
}

class ParkingAdminApp extends StatelessWidget {
  const ParkingAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MultiProvider(
          providers: _getProviders(context),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Parking Admin App',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          ),
        );
      },
    );
  }

  // Extracted method to provide a list of all necessary providers
  List<SingleChildWidget> _getProviders(BuildContext context) {
    return [
      RepositoryProvider<VehicleRepository>.value(value: vehicleRepository),
      RepositoryProvider<ParkingSpaceRepository>.value(
          value: parkingSpaceRepository),
      RepositoryProvider<ParkingRepository>.value(value: parkingRepository),
      RepositoryProvider<PersonRepository>.value(value: personRepository),
      BlocProvider<PersonBloc>(
        create: (context) => PersonBloc(repository: personRepository)
          ..add(const FetchPersonsEvent()),
      ),
      BlocProvider<VehicleBloc>(
        create: (context) =>
            VehicleBloc(vehicleRepository)..add(const LoadVehicles()),
      ),
      BlocProvider<ParkingsBloc>(
        create: (context) => ParkingsBloc(parkingRepository: parkingRepository)
          ..add(LoadParkingsEvent()),
      ),
      BlocProvider<ParkingSpaceBloc>(
        create: (context) => ParkingSpaceBloc(parkingSpaceRepository)
          ..add(const LoadParkingSpaces()),
      ),
    ];
  }
}
