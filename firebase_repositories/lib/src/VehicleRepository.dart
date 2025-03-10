import 'package:shared/shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleRepository {
  static final VehicleRepository _instance = VehicleRepository._internal();
  static VehicleRepository get instance => _instance;
  VehicleRepository._internal();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize FirebaseAuth

  // 🔥 Real-time Firestore listener for vehicles collection
  Stream<List<Vehicle>> vehicleStream() {
    return db.collection('vehicles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Vehicle.fromJson(doc.data())).toList();
    });
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    //await Future.delayed(Duration(seconds: 5));

    await db.collection("vehicles").doc(vehicle.id).set(vehicle.toJson());

    return vehicle;
  }

  Future<Vehicle> getVehicleById(String id) async {
    final snapshot = await db.collection("vehicles").doc(id).get();

    final json = snapshot.data();

    if (json == null) {
      throw Exception("Vehicle with id $id not found");
    }

    json["id"] = snapshot.id;

    return Vehicle.fromJson(json);
  }

  Future<List<Vehicle>> getVehiclesForUser(String userId) async {
    try {
      final querySnapshot = await db
          .collection('vehicles')
          .where('owner.authId',
              isEqualTo: userId) // Match with logged-in user ID
          .get();

      return querySnapshot.docs.map((doc) {
        return Vehicle.fromJson(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final querySnapshot = await db.collection('vehicles').get();
      return querySnapshot.docs
          .map((doc) => Vehicle.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  Future<Vehicle> deleteVehicle(String id) async {
    final vehicle = await getVehicleById(id);

    await db.collection("vehicles").doc(id).delete();

    return vehicle;
  }

  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    await db.collection("vehicles").doc(vehicle.id).set(vehicle.toJson());

    return vehicle;
  }
}
