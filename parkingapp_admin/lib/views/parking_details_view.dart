import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:intl/intl.dart';

class ParkingDetailsView extends StatelessWidget {
  final Parking parking;

  const ParkingDetailsView({super.key, required this.parking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mer information"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionTitle(context, 'Parkeringsinformation:'),
            const SizedBox(height: 8),
            buildKeyValue('Parkerings ID', parking.id.toString()),
            buildKeyValue('Starttid',
                DateFormat('yyyy-MM-dd HH:mm').format(parking.startTime)),
            buildKeyValue('Sluttid',
                DateFormat('yyyy-MM-dd HH:mm').format(parking.endTime)),
            const SizedBox(height: 16),
            buildSectionTitle(context, 'Fordonsinformation:'),
            const SizedBox(height: 8),
            buildKeyValue('Fordons ID', parking.vehicle!.id.toString()),
            buildKeyValue('Reg.nummer', parking.vehicle!.regNumber),
            buildKeyValue('Fordonstyp', parking.vehicle!.vehicleType),
            const SizedBox(height: 16),
            buildSectionTitle(context, 'Ägareinformation:'),
            const SizedBox(height: 8),
            if (parking.vehicle!.owner != null) ...[
              buildKeyValue(
                  'Ägarens ID', parking.vehicle!.owner!.authId.toString()),
              buildKeyValue('Ägarensnamn', parking.vehicle!.owner!.name),
              buildKeyValue('Ägarens Email', parking.vehicle!.owner!.email),
              buildKeyValue(
                  'Ägarens personnummer', parking.vehicle!.owner!.personNumber),
            ] else
              const Text('Ägarens informaion är inte tillgänglig.'),
            const SizedBox(height: 16),
            buildSectionTitle(context, 'Parkeringsplatsinformation:'),
            const SizedBox(height: 8),
            buildKeyValue(
                'Parkeringsplats ID', parking.parkingSpace!.id.toString()),
            buildKeyValue('Address', parking.parkingSpace!.address),
            buildKeyValue(
                'Pris per timme', '${parking.parkingSpace!.pricePerHour} kr'),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget buildKeyValue(String key, String value) {
    return Text('$key: $value');
  }
}
