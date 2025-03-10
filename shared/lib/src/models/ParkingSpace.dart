// import 'package:equatable/equatable.dart';
// import 'package:uuid/uuid.dart';

// class ParkingSpace extends Equatable {
//   final String id;
//   final String address;
//   final int pricePerHour;

//   ParkingSpace({
//     String? id,
//     required this.address,
//     required this.pricePerHour,
//   }) : id = id ?? const Uuid().v4();

//   // Factory constructor to create a ParkingSpace from JSON
//   factory ParkingSpace.fromJson(Map<String, dynamic> json) {
//     return ParkingSpace(
//       id: json['id'] ?? '', // Default to -1 if id is missing
//       address: json['address'] ??
//           '', // Default to empty string if address is missing
//       pricePerHour:
//           json['pricePerHour'] ?? 0, // Default to 0 if pricePerHour is missing
//     );
//   }

//   // Convert a ParkingSpace object to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'address': address,
//       'pricePerHour': pricePerHour,
//     };
//   }

//   @override
//   List<Object?> get props => [id, address, pricePerHour];
// }

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class ParkingSpace extends Equatable {
  final String id;
  final String address;
  final int pricePerHour;

  ParkingSpace({
    String? id,
    required this.address,
    required this.pricePerHour,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor to create a ParkingSpace from JSON
  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    return ParkingSpace(
      id: json['id'] ?? const Uuid().v4(), // Auto-generate ID if missing
      address: json['address'] ?? '', // Default to empty string
      pricePerHour: json['pricePerHour'] ?? 0, // Default to 0 if missing
    );
  }

  // Convert a ParkingSpace object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'pricePerHour': pricePerHour,
    };
  }

  @override
  List<Object?> get props => [id, address, pricePerHour];
}
