import 'package:flutter/material.dart';
import 'vehicle_management_view.dart';
import 'parkingspace_selection_view.dart';
import 'overview_view.dart';
import 'settings_view.dart';
import 'login_view.dart';
import 'package:parkingapp_user/repository/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkingapp_user/blocs/auth/auth_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      const VehicleManagementView(),
      // Retrieve NotificationRepository from context
      ParkingSpaceSelectionView(
        notificationRepository: context.read<NotificationRepository>(),
      ),
      const OverviewView(),
      const SettingsView(),
    ];

    // Check authentication status on initialization
    context.read<AuthBloc>().add(CheckAuthStatus());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      debugPrint('User is logged in: ${authState.name}');
    } else if (authState is AuthLoggedOut) {
      debugPrint('User is logged out');
    } else {
      debugPrint('User status unknown');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showLogoutDialog() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bekräfta utloggning"),
          content: const Text("Vill du logga ut?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Avbryt"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logga ut"),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // ignore: use_build_context_synchronously
      context.read<AuthBloc>().add(LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AuthLoggedOut) {
          return LoginView(
            onLoginSuccess: () =>
                context.read<AuthBloc>().add(CheckAuthStatus()),
          );
        }

        if (state is AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                  "Välkommen, ${state.name.isNotEmpty ? state.name : 'Användare'}!"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _showLogoutDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: _views[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car),
                  label: 'Fordon',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_parking),
                  label: 'Parkeringsplats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Översikt',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Inställningar',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: const Color.fromARGB(255, 64, 63, 63),
              onTap: _onItemTapped,
            ),
          );
        }

        return const Center(
          child: Text('Something went wrong.'),
        );
      },
    );
  }
}
