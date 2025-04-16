import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class ParkingSpace extends Equatable {
  final String id;
  final String address;
  final int pricePerHour;
  final bool isOccupied;

  ParkingSpace({
    String? id,
    required this.address,
    required this.pricePerHour,
    this.isOccupied = false,
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

  ParkingSpace copyWith({
    String? id,
    String? address,
    int? pricePerHour,
    bool? isOccupied,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      address: address ?? this.address,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }

  @override
  List<Object?> get props => [id, address, pricePerHour];
}
