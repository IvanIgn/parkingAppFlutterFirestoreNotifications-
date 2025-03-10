import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared/shared.dart';
import 'dart:io';

class VehicleRepository {
  static final VehicleRepository _instance = VehicleRepository._internal();
  static VehicleRepository get instance => _instance;
  VehicleRepository._internal();

  String host = Platform.isAndroid ? 'http://10.0.2.2' : 'http://localhost';
  String port = '8080';
  String resource = 'vehicles';

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    // final uri = Uri.parse("http://localhost:8080/vehicles");
    final uri = Uri.parse('$host:$port/$resource');

    // Create a copy of vehicle without the ID for creation
    //final vehicleData = vehicle.toJson();
    //vehicleData.remove('id'); // Remove the 'id' field if it exists

    Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()));

    final json = jsonDecode(response.body);

    return Vehicle.fromJson(json);
  }

  Future<Vehicle> getVehicleById(String id) async {
    // final uri = Uri.parse("http://localhost:8080/vehicles/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return Vehicle.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<List<Vehicle>> getAllVehicles() async {
    // final uri = Uri.parse("http://localhost:8080/vehicles");
    final uri = Uri.parse('$host:$port/$resource');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return (json as List)
          .map((vehicle) => Vehicle.fromJson(vehicle))
          .toList();
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<Vehicle> deleteVehicle(String id) async {
    //final uri = Uri.parse("http://localhost:8080/vehicles/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return Vehicle.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse response: ${response.body}, error: $e');
    }
  }

  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    // final uri = Uri.parse("http://localhost:8080/vehicles/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(vehicle.toJson()),
    );

    _checkResponse(response);

    try {
      final json = jsonDecode(response.body);
      return Vehicle.fromJson(json);
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
