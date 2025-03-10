import 'package:shared/shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingRepository {
  static final ParkingRepository _instance = ParkingRepository._internal();
  static ParkingRepository get instance => _instance;
  ParkingRepository._internal();

  final db = FirebaseFirestore.instance; // Initialize FirebaseFirestore

  Future<Parking> createParking(Parking parking) async {
    // await Future.delayed(Duration(seconds: 2));

    if (parking.id.isEmpty) {
      throw Exception("Fel: parking.id ska inte vara tom!");
    }

    await db.collection("parkings").doc(parking.id).set(parking.toJson());

    return parking;
  }

  Future<Parking> getParkingById(String id) async {
    final snapshot = await db.collection("parkings").doc(id).get();

    final json = snapshot.data();

    if (json == null) {
      throw Exception("Parking with id $id not found");
    }

    json["id"] = snapshot.id;

    return Parking.fromJson(json);
  }

  // load parking by user id
  Future<List<Parking>> getParkingByUserEmail(String userEmail) async {
    try {
      final querySnapshot = await db
          .collection('parkings')
          .where('owner.email',
              isEqualTo: userEmail) // Match with logged-in user ID
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['email'] = doc.id;
        return Parking.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load active user parking by email: $e');
    }
  }

  Future<List<Parking>> getAllParkings() async {
    final snapshots = await db.collection("parkings").get();

    final docs = snapshots.docs;

    final jsons = docs.map((doc) {
      final json = doc.data();
      json["id"] = doc.id;

      return json;
    }).toList();

    return jsons.map((json) => Parking.fromJson(json)).toList();
  }

  Future<Parking> deleteParking(String id) async {
    final vehicle = await getParkingById(id);

    await db.collection("parkings").doc(id).delete();

    return vehicle;
  }

  Future<Parking> updateParking(String id, Parking parking) async {
    await db.collection("parkings").doc(parking.id).set(parking.toJson());

    return parking;
  }
}
