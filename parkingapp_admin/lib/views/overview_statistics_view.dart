import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:firebase_repositories/firebase_repositories.dart';
import 'package:intl/intl.dart';
import 'parking_details_view.dart';

class OverviewStatisticsView extends StatefulWidget {
  const OverviewStatisticsView({super.key});

  @override
  State<OverviewStatisticsView> createState() => _OverviewStatisticsViewState();
}

class _OverviewStatisticsViewState extends State<OverviewStatisticsView> {
  late Future<List<Parking>> _parkingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshParkings();
  }

  void _refreshParkings() {
    setState(() {
      _parkingsFuture = ParkingRepository.instance.getAllParkings();
    });
  }

  /// Computes summarized statistics for parking data.
  Map<String, dynamic> _computeStatistics(List<Parking> parkings) {
    int activeCount = parkings.length;
    double totalIncome = parkings.fold(0, (sum, parking) {
      final duration = parking.endTime.difference(parking.startTime).inHours;
      final price = parking.parkingSpace?.pricePerHour ?? 0;
      return sum + (duration * price);
    });

    Map<String, int> popularity = {};
    for (var parking in parkings) {
      final address = parking.parkingSpace?.address ?? 'Unknown';
      popularity[address] = (popularity[address] ?? 0) + 1;
    }

    final mostPopular = (popularity.isNotEmpty)
        ? popularity.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    return {
      "activeCount": activeCount,
      "totalIncome": totalIncome,
      "mostPopular": mostPopular,
    };
  }

  /// Displays a list of active parkings.
  Widget _buildActiveParkingsList(List<Parking> parkings) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: parkings.length,
      itemBuilder: (context, index) {
        final parking = parkings[index];
        return ListTile(
          title: Text(
            'Parkerings-ID: ${parking.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
              if (parking.vehicle != null)
                Text(
                  'Reg.nummer: ${parking.vehicle!.regNumber}',
                  style: const TextStyle(fontSize: 14),
                ),
              if (parking.parkingSpace != null)
                Text(
                  'Plats: ${parking.parkingSpace!.address ?? 'Okänd'}',
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingDetailsView(parking: parking),
                ),
              );
            },
            child: const Text('Mer info'),
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
  }

  /// Displays summarized statistics.
  Widget _buildStatisticsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text('Antal aktiva parkeringar: ${stats["activeCount"]}'),
        Text('Summerad inkomst: ${stats["totalIncome"].toStringAsFixed(2)} kr'),
        Text('Populäraste parkeringsplats: ${stats["mostPopular"]}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parkering Övervakning och Statistik"),
      ),
      body: FutureBuilder<List<Parking>>(
        future: _parkingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Fel vid hämtning av data: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Inga aktiva parkeringar tillgängliga.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final parkingsList = snapshot.data!;
          final stats = _computeStatistics(parkingsList);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsSection(stats),
                const SizedBox(height: 20),
                Expanded(child: _buildActiveParkingsList(parkingsList)),
              ],
            ),
          );
        },
      ),
    );
  }
}
