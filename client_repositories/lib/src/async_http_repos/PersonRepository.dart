import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared/shared.dart';
import 'dart:io';
//import 'VehicleRepository.dart';

class PersonRepository {
  static final PersonRepository _instance = PersonRepository._internal();
  static PersonRepository get instance => _instance;
  PersonRepository._internal();

  String host = Platform.isAndroid ? 'http://10.0.2.2' : 'http://localhost';
  String port = '8080';
  String resource = 'persons';

  Future<Person> createPerson(Person person) async {
    // final uri = Uri.parse("http://localhost:8080/persons");
    final uri = Uri.parse('$host:$port/$resource');
    //final personData = person.toJson();
    //personData.remove('id'); // Remove the 'id' field if it exists

    Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(person.toJson()));

    final json = jsonDecode(response.body);

    return Person.fromJson(json);
  }

  Future<Person> getPersonById(String id) async {
    //final uri = Uri.parse("http://localhost:8080/persons/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return Person.fromJson(json);
  }

  Future<List<Person>> getAllPersons() async {
    // final uri = Uri.parse("http://localhost:8080/persons");
    final uri = Uri.parse('$host:$port/$resource');
    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return (json as List).map((person) => Person.fromJson(person)).toList();
  }

  Future<Person> deletePerson(String id) async {
    // final uri = Uri.parse("http://localhost:8080/persons/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return Person.fromJson(json);
  }

  Future<Person> updatePerson(String id, Person person) async {
    //final uri = Uri.parse("http://localhost:8080/persons/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.put(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(person.toJson()));

    if (response.statusCode != 200) {
      throw Exception('Failed to update person');
    }

    final json = jsonDecode(response.body);

    return Person.fromJson(json);
  }
}
