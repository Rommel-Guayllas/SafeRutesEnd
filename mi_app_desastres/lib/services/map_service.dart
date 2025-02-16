import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    as gpa;

class MapService {
  static const String orsToken =
      '5b3ce3597851110001cf624855a2030980b346859dd95b3cc9eba073';

  /// Retorna una lista de [LatLng] que representan la ruta desde [start] hasta [end].
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car',
    );

    final body = json.encode({
      "coordinates": [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ]
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': orsToken,
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener ruta: ${response.body}');
    }

    final data = json.decode(response.body);
    final routes = data['routes'];
    final geometry = routes[0]['geometry'] as String?;

    final List<List<num>> decoded = gpa.decodePolyline(
      geometry!,
      accuracyExponent: 6,
    );

    return decoded
        .map((pair) => LatLng(pair[0].toDouble(), pair[1].toDouble()))
        .toList();
  }
}
