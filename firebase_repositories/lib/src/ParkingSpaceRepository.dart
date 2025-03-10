import 'package:shared/shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSpaceRepository {
  static final ParkingSpaceRepository _instance =
      ParkingSpaceRepository._internal();
  static ParkingSpaceRepository get instance => _instance;
  ParkingSpaceRepository._internal();

  final db = FirebaseFirestore.instance; // Initialize FirebaseFirestore

  Future<ParkingSpace> createParkingSpace(ParkingSpace parkingSpace) async {
    //await Future.delayed(Duration(seconds: 2));

    await db
        .collection("parkingSpaces")
        .doc(parkingSpace.id)
        .set(parkingSpace.toJson());

    return parkingSpace;
  }

  Future<ParkingSpace> getParkingSpaceById(String id) async {
    final snapshot = await db.collection("parkingSpaces").doc(id).get();

    final json = snapshot.data();

    if (json == null) {
      throw Exception("Parking space with id $id not found");
    }

    json["id"] = snapshot.id;

    return ParkingSpace.fromJson(json);
  }

  Future<List<ParkingSpace>> getAllParkingSpaces() async {
    final snapshots = await db.collection("parkingSpaces").get();

    final docs = snapshots.docs;

    final jsons = docs.map((doc) {
      final json = doc.data();
      json["id"] = doc.id;

      return json;
    }).toList();

    return jsons.map((json) => ParkingSpace.fromJson(json)).toList();
  }

  Future<ParkingSpace> deleteParkingSpace(String id) async {
    final parkingSpace = await getParkingSpaceById(id);

    await db.collection("parkingSpaces").doc(id).delete();

    return parkingSpace;
  }

  Future<ParkingSpace> updateParkingSpace(
      String id, ParkingSpace parkingSpace) async {
    await db
        .collection("parkingSpaces")
        .doc(parkingSpace.id)
        .set(parkingSpace.toJson());

    return parkingSpace;
  }
}
