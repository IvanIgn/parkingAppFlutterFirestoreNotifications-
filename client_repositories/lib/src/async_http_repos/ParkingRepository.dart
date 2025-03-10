import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared/shared.dart';
import 'dart:io';

class ParkingRepository {
  static final ParkingRepository _instance = ParkingRepository._internal();
  static ParkingRepository get instance => _instance;
  ParkingRepository._internal();

  String host = Platform.isAndroid ? 'http://10.0.2.2' : 'http://localhost';
  String port = '8080';
  String resource = 'parkings';

  Future<Parking> createParking(Parking parking) async {
    //final uri = Uri.parse("http://localhost:8080/parkingspaces");
    final uri = Uri.parse('$host:$port/$resource');

    Response response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(parking.toJson()));

    _checkResponse(response);

    final json = jsonDecode(response.body);

    return Parking.fromJson(json);
  }

  // Future<Parking> createParking(Parking parking) async {
  //   final uri = Uri.parse('$host:$port/$resource');

  //   Response response = await http.get(
  //     uri,
  //     headers: {'Content-Type': 'application/json'},
  //   );

  //   if (response.statusCode == 201) {
  //     final responseBody = json.decode(response.body);

  //     // Ensure the response contains a valid ID
  //     if (responseBody['id'] == null || responseBody['id'] is! int) {
  //       throw FormatException('Invalid ID received from server');
  //     }

  //     return Parking.fromJson(responseBody);
  //   } else {
  //     throw Exception('Failed to create parking: ${response.body}');
  //   }
  // }

  Future<Parking> getParkingById(String id) async {
    // final uri = Uri.parse("http://localhost:8080/parkings/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return Parking.fromJson(json);
  }

  Future<List<Parking>> getAllParkings() async {
    //final uri = Uri.parse("http://localhost:8080/parkings");
    final uri = Uri.parse('$host:$port/$resource');

    Response response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return (json as List).map((parking) => Parking.fromJson(parking)).toList();
  }

  Future<Parking> deleteParking(String id) async {
    //final uri = Uri.parse("http://localhost:8080/parkings/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);

    return Parking.fromJson(json);
  }

  Future<Parking> updateParking(String id, Parking parking) async {
    //final uri = Uri.parse("http://localhost:8080/parkings/$id");
    final uri = Uri.parse('$host:$port/$resource/$id');

    Response response = await http.put(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(parking.toJson()));

    final json = jsonDecode(response.body);

    return Parking.fromJson(json);
  }

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
