import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';
import 'package:flutter/foundation.dart';

// String host = Platform.isAndroid ? 'http://10.0.2.2' : 'http://localhost';
// String port = '8080';
// String resource = 'persons';

class PersonRepository {
  static final PersonRepository _instance = PersonRepository._internal();
  static PersonRepository get instance => _instance;
  PersonRepository._internal();

  final db = FirebaseFirestore.instance; // Initialize FirebaseFirestore

  Future<Person> createPerson(Person person) async {
    // await Future.delayed(Duration(seconds: 5));

    await db.collection("persons").doc(person.id).set(person.toJson());

    return person;
  }

  Future<Person> getPersonById(String id) async {
    final snapshot = await db.collection("persons").doc(id).get();

    final json = snapshot.data();

    if (json == null) {
      throw Exception("User with id $id not found");
    }

    json["id"] = snapshot.id;

    return Person.fromJson(json);
  }

  Future<Person?> getByAuthId(String authId) async {
    final snapshot =
        await db.collection("persons").where("authId", isEqualTo: authId).get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final json = snapshot.docs.first.data();

    return Person.fromJson(json);
  }

  Future<List<Person>> getAllPersons() async {
    final snapshots = await db.collection("persons").get();

    final docs = snapshots.docs;

    final jsons = docs.map((doc) {
      final json = doc.data();
      json["id"] = doc.id;

      return json;
    }).toList();

    return jsons.map((json) => Person.fromJson(json)).toList();
  }

  // Future<Person> deletePerson(String id) async {
  //   final person = await getPersonById(id);

  //   await db.collection("persons").doc(id).delete();

  //   return person;
  // }

  Future<Person?> deletePerson(String id) async {
    try {
      // Check if the person exists before deleting
      final personSnapshot = await db.collection("persons").doc(id).get();

      if (!personSnapshot.exists) {
        throw Exception("Person with ID $id does not exist");
      }

      // Delete person from Firestore
      await db.collection("persons").doc(id).delete();

      // Optionally, return the deleted person data or any success message
      return Person.fromJson(
          personSnapshot.data()!); // Return the person object if needed
    } catch (e) {
      debugPrint("Error deleting person: $e");
      rethrow; // Rethrow error to propagate up to the caller
    }
  }

  Future<Person> updatePerson(String id, Person person) async {
    await db.collection("persons").doc(person.id).set(person.toJson());

    return person;
  }
}
