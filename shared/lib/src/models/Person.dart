import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Person extends Equatable {
  String id;
  String name;
  String personNumber;
  String email;
  String authId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Person &&
        other.email == email &&
        other.id == id &&
        other.authId == authId;
  }

  @override
  int get hashCode => email.hashCode ^ id.hashCode ^ authId.hashCode;

  Person({
    String? id,
    required this.name,
    required this.personNumber,
    required this.email,
    required this.authId,
  }) : id = id ?? const Uuid().v4(); // Use a UUID if no ID is provided

  // Factory constructor to create a Person from JSON
  factory Person.fromJson(Map<String, dynamic> json) {
    // Use UUID if id is not provided in the JSON
    final id = json['id'] ?? const Uuid().v4();

    // Throw error if name or personNumber is missing (or empty)
    if (json['name'] == null || json['name'].isEmpty) {
      throw ArgumentError('Name is required');
    }
    if (json['personNumber'] == null || json['personNumber'].isEmpty) {
      throw ArgumentError('Person number is required');
    }
    if (json['email'] == null || json['email'].isEmpty) {
      throw ArgumentError('Email is required');
    }

    return Person(
      id: id,
      name: json['name'],
      personNumber: json['personNumber'],
      email: json['email'],
      authId: json['authId'],
    );
  }

  // Convert a Person object to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      //"userName": userName,
      "personNumber": personNumber,
      "email": email,
      "authId": authId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'personNumber': personNumber,
      'email': email,
      'authId': authId,
    };
  }

  Person copyWith({
    String? id,
    String? name,
    String? personNumber,
    String? email,
    String? authId,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      personNumber: personNumber ?? this.personNumber,
      email: email ?? this.email,
      authId: authId ?? this.authId,
    );
  }

  @override
  List<Object?> get props => [id, name, personNumber, email, authId];
}
