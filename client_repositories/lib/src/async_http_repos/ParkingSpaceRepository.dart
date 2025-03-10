import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared/shared.dart';
import 'dart:io';

class ParkingSpaceRepository {
  static final ParkingSpaceRepository _instance =
      ParkingSpaceRepository._internal();
  static ParkingSpaceRepository get instance => _instance;
  ParkingSpaceRepository._internal();

  String host = Platform.isAndroid ? 'http://10.0.2.2' : 'http://localhost';
  String port = '8080';
  String resource = 'parkingspaces';

  Future<ParkingSpace> createParkingSpace(ParkingSpace parkingspace) async {
    //final uri = Uri.parse("http://localhost:8080/parkingspaces");
    final uri = Uri.parse('$host:$port/$resource');

    // Create a copy of parkingspace without the ID for creation
    //final parkingSpaceData = parkingspace.toJson();
    // parkingSpaceData.remove('id'); // Remove the 'id' field if it exists

    // Response response = await http.post(
    //   uri,
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(parkingSpaceData),
    // );
    Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(parkingspace.toJson()));

    _checkResponse(response);

    final json = jsonDecode(response.body);

    return ParkingSpace.fromJson(json);
  }

  Future<ParkingSpace> getParkingSpaceById(String id) async {
    //final uri = Uri.parse("http://localhost:8080/parkingspaces/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return ParkingSpace.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<List<ParkingSpace>> getAllParkingSpaces() async {
    //final uri = Uri.parse("http://localhost:8080/parkingspaces");
    final uri = Uri.parse('$host:$port/$resource');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    if (response.body.isEmpty) {
      return [];
    }

    try {
      final json = jsonDecode(response.body);
      return (json as List)
          .map((parkingspace) => ParkingSpace.fromJson(parkingspace))
          .toList();
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<ParkingSpace> deleteParkingSpace(String id) async {
    // final uri = Uri.parse("http://localhost:8080/parkingspaces/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return ParkingSpace.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<ParkingSpace> updateParkingSpace(
      String id, ParkingSpace parkingspace) async {
    // final uri = Uri.parse("http://localhost:8080/parkingspaces/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(parkingspace.toJson()),
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return ParkingSpace.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  /// Helper method to check the response status code
  void _checkResponse(Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Request failed with status: ${response.statusCode}, body: ${response.body}');
    }

    if (response.body.isEmpty) {
      throw Exception('Server returned an empty response.');
    }
  }
}
