// import 'dart:convert';
// import 'package:shared/src/models/Person.dart';
// import 'package:equatable/equatable.dart';
// import 'package:uuid/uuid.dart';

// class Vehicle extends Equatable {
//   final String id;
//   final String regNumber;
//   final String vehicleType;

//   Person? owner;

//   Vehicle({
//     String? id,
//     required this.regNumber,
//     required this.vehicleType,
//     this.owner,
//   }) : id = id ?? const Uuid().v4();

//   // Getter to encode `owner` as a JSON string for database storage
//   String? get ownerInDb {
//     return owner == null ? null : jsonEncode(owner!.toJson());
//   }

//   // Setter to decode a JSON string to assign the `owner` property
//   set ownerInDb(String? json) {
//     if (json == null) {
//       owner = null;
//     } else {
//       try {
//         owner = Person.fromJson(jsonDecode(json));
//       } catch (e) {
//         owner = null; // Handle decoding errors by setting `owner` to null
//       }
//     }
//   }

//   // Factory constructor to create a Vehicle from JSON
//   factory Vehicle.fromJson(Map<String, dynamic> json) {
//     return Vehicle(
//       id: json['id'] ?? '', // Default to -1 if id is missing
//       regNumber: json['regNumber'] ?? '', // Default to empty string
//       vehicleType: json['vehicleType'] ?? '', // Default to empty string
//       owner: json['owner'] != null ? Person.fromJson(json['owner']) : null,
//     );
//   }

//   // Convert a Vehicle object to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'regNumber': regNumber,
//       'vehicleType': vehicleType,
//       'owner': owner?.toJson(), // Null check for owner
//     };
//   }

//   // `copyWith` method to allow modification of specific fields
//   Vehicle copyWith({
//     String? id,
//     String? regNumber,
//     String? vehicleType,
//     Person? owner,
//   }) {
//     return Vehicle(
//       id: id ?? this.id,
//       regNumber: regNumber ?? this.regNumber,
//       vehicleType: vehicleType ?? this.vehicleType,
//       owner: owner ?? this.owner,
//     );
//   }

//   @override
//   List<Object?> get props => [id, regNumber, vehicleType, owner];
// }

import 'dart:convert';
import 'package:shared/src/models/Person.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Vehicle extends Equatable {
  final String id;
  final String regNumber;
  final String vehicleType;

  Person? owner;

  Vehicle({
    String? id,
    required this.regNumber,
    required this.vehicleType,
    this.owner,
  }) : id = id ?? const Uuid().v4();

  // Getter to encode `owner` as a JSON string for database storage
  String? get ownerInDb {
    return owner == null ? null : jsonEncode(owner!.toJson());
  }

  // Setter to decode a JSON string to assign the `owner` property
  set ownerInDb(String? json) {
    if (json == null) {
      owner = null;
    } else {
      try {
        owner = Person.fromJson(jsonDecode(json));
      } catch (e) {
        print("Error decoding owner: $e");
        owner = null; // Handle decoding errors by setting `owner` to null
      }
    }
  }

  // Factory constructor to create a Vehicle from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? const Uuid().v4(), // Auto-generate ID if missing
      regNumber: json['regNumber'] ?? '', // Default to empty string
      vehicleType: json['vehicleType'] ?? '', // Default to empty string
      owner: json['owner'] != null ? Person.fromJson(json['owner']) : null,
    );
  }

  // Convert a Vehicle object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regNumber': regNumber,
      'vehicleType': vehicleType,
      'owner': owner?.toJson(), // Null check for owner
    };
  }

  // `copyWith` method to allow modification of specific fields
  Vehicle copyWith({
    String? id,
    String? regNumber,
    String? vehicleType,
    Person? owner,
  }) {
    return Vehicle(
      id: id ?? this.id,
      regNumber: regNumber ?? this.regNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      owner: owner ?? this.owner,
    );
  }

  @override
  List<Object?> get props => [id, regNumber, vehicleType, owner];
}
