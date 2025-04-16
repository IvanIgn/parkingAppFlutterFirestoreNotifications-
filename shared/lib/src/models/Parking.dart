// import 'dart:convert';
// import 'package:shared/src/models/ParkingSpace.dart';
// import 'package:shared/src/models/Vehicle.dart';
// import 'package:equatable/equatable.dart';
// import 'package:uuid/uuid.dart';

// class Parking extends Equatable {
//   final String id;
//   Vehicle? vehicle;
//   ParkingSpace? parkingSpace; // Nullable parkingSpace
//   final DateTime startTime;
//   final DateTime endTime;

//   Parking({
//     String? id,
//     this.vehicle,
//     this.parkingSpace,
//     required this.startTime,
//     required this.endTime,
//   }) : id = id ?? const Uuid().v4();

//   // Convert vehicle to a JSON string for database storage
//   String? get vehicleInDb =>
//       vehicle == null ? null : jsonEncode(vehicle!.toJson());

//   set vehicleInDb(String? json) {
//     vehicle = json == null ? null : Vehicle.fromJson(jsonDecode(json));
//   }

//   // Convert parkingSpace to a JSON string for database storage
//   String? get parkingSpaceInDb =>
//       parkingSpace == null ? null : jsonEncode(parkingSpace!.toJson());

//   set parkingSpaceInDb(String? json) {
//     parkingSpace =
//         json == null ? null : ParkingSpace.fromJson(jsonDecode(json));
//   }

//   // Factory constructor to create a Parking instance from JSON
//   factory Parking.fromJson(Map<String, dynamic> json) {
//     return Parking(
//       id: json['id'] ?? '',
//       vehicle:
//           json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
//       parkingSpace: json['parkingSpace'] != null
//           ? ParkingSpace.fromJson(json['parkingSpace'])
//           : null,
//       startTime: DateTime.parse(json['startTime']),
//       endTime: DateTime.parse(json['endTime']),
//     );
//   }

//   // Convert a Parking instance to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'vehicle': vehicle?.toJson(),
//       'parkingSpace': parkingSpace?.toJson(),
//       'startTime': startTime.toIso8601String(),
//       'endTime': endTime.toIso8601String(),
//     };
//   }

//   @override
//   List<Object?> get props => [id, vehicle, parkingSpace, startTime, endTime];
// }

import 'dart:convert';
import 'package:shared/src/models/ParkingSpace.dart';
import 'package:shared/src/models/Vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Parking extends Equatable {
  final String id;
  Vehicle? vehicle;
  ParkingSpace? parkingSpace; // Nullable parkingSpace
  final DateTime startTime;
  final DateTime endTime;

  Parking({
    String? id,
    this.vehicle,
    this.parkingSpace,
    required this.startTime,
    required this.endTime,
  }) : id = id ?? const Uuid().v4(); // Ensure id is generated if not provided

  // Convert vehicle to a JSON string for database storage
  String? get vehicleInDb =>
      vehicle == null ? null : jsonEncode(vehicle!.toJson());

  set vehicleInDb(String? json) {
    vehicle = json == null ? null : Vehicle.fromJson(jsonDecode(json));
  }

  // Convert parkingSpace to a JSON string for database storage
  String? get parkingSpaceInDb =>
      parkingSpace == null ? null : jsonEncode(parkingSpace!.toJson());

  set parkingSpaceInDb(String? json) {
    parkingSpace =
        json == null ? null : ParkingSpace.fromJson(jsonDecode(json));
  }

  // Factory constructor to create a Parking instance from JSON
  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] ?? const Uuid().v4(), // Ensure the id is not empty
      vehicle:
          json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      parkingSpace: json['parkingSpace'] != null
          ? ParkingSpace.fromJson(json['parkingSpace'])
          : null,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }

  // Convert a Parking instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle': vehicle?.toJson(),
      'parkingSpace': parkingSpace?.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  Parking copyWith({
    String? id,
    Vehicle? vehicle,
    ParkingSpace? parkingSpace,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Parking(
      id: id ?? this.id,
      vehicle: vehicle ?? this.vehicle,
      parkingSpace: parkingSpace ?? this.parkingSpace,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, vehicle, parkingSpace, startTime, endTime];
}
