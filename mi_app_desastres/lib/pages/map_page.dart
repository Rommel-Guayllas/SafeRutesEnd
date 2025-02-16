import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Esta pantalla muestra el mapa, la ruta hacia el punto seguro y escucha los cambios de ubicación.
/// Cuando se detecta que se ha llegado al destino (menos de 50 metros), se muestra la encuesta.
class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationService = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _nearestSafePoint;
  List<LatLng> _route = [];
  List<Marker> _safePointMarkers = [];
  bool _surveyShown = false; // Bandera para mostrar la encuesta solo una vez
  bool _userSelectedDestination =
      false; // Nueva variable para saber si el usuario eligió manualmente un destino

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadSafePoints();
  }

  /// Cargar la lista de puntos seguros desde Firestore
  Future<void> _loadSafePoints() async {
    try {
      final snapshot = await _firestore.collection('safe_points').get();
      print("Obtenidos ${snapshot.size} documentos de safe_points.");

      final markers = snapshot.docs.map((doc) {
        final data = doc.data();
        final lat = data['latitude'] as double;
        final lon = data['longitude'] as double;
        final name = data['name'] as String? ?? "Sin nombre";

        print("Marcador: lat=$lat, lon=$lon, name=$name");

        return Marker(
          width: 40,
          height: 40,
          point: LatLng(lat, lon),
          child: GestureDetector(
            onTap: () {
              _onSafePointTapped(LatLng(lat, lon));
            },
            child: Tooltip(
              message: name,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ),
        );
      }).toList();

      setState(() {
        _safePointMarkers = markers;
      });

      // Si la ubicación ya está disponible, traza la ruta automáticamente
      // Solo se recalcula si el usuario no ha seleccionado un destino manualmente
      if (_currentLocation != null &&
          _safePointMarkers.isNotEmpty &&
          !_userSelectedDestination) {
        _findNearestSafePoint();
      }
    } catch (e) {
      print("Error al cargar puntos seguros: $e");
      _showError('Error al cargar puntos seguros: $e');
    }
  }

  /// Se invoca cuando se toca un punto seguro: se actualiza el destino y se calcula la nueva ruta.
  Future<void> _onSafePointTapped(LatLng point) async {
    setState(() {
      _nearestSafePoint = point;
      _userSelectedDestination =
          true; // Marcamos que el destino fue elegido por el usuario
    });
    print("Punto seguro seleccionado por el usuario: $point");
    await _fetchRoute(point);
  }

  /// Buscar el punto seguro más cercano y trazar la ruta (solo si el usuario no eligió un destino manualmente)
  Future<void> _findNearestSafePoint() async {
    // Si el usuario ya eligió manualmente un destino, no se actualiza
    if (_userSelectedDestination) {
      print(
          "Destino seleccionado manualmente, se omite el cálculo del punto más cercano.");
      return;
    }

    if (_currentLocation == null || _safePointMarkers.isEmpty) {
      print("No se puede buscar punto cercano: ubicación o marcadores vacíos.");
      return;
    }

    LatLng? nearest;
    double minDistance = double.infinity;

    for (var marker in _safePointMarkers) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        _currentLocation!,
        marker.point,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = marker.point;
      }
    }

    if (nearest != null) {
      setState(() {
        _nearestSafePoint = nearest;
      });
      print("Punto seguro más cercano: $nearest, dist=$minDistance km");
      await _fetchRoute(_nearestSafePoint!);
    }
  }

  /// Inicializar la ubicación y escuchar cambios
  Future<void> _initializeLocation() async {
    if (!await _checkAndRequestPermissions()) return;

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() {
          _currentLocation = latLng;
          _isLoading = false;
        });
        print("Ubicación actual: $latLng");

        // Si el usuario no eligió un destino manual, actualiza el destino automáticamente
        if (_safePointMarkers.isNotEmpty && !_userSelectedDestination) {
          _findNearestSafePoint();
        }

        // Verificar si se ha llegado al destino (umbral de 50 metros)
        if (_currentLocation != null &&
            _nearestSafePoint != null &&
            !_surveyShown) {
          final distance = const Distance()
              .as(LengthUnit.Meter, _currentLocation!, _nearestSafePoint!);
          print("Distancia al destino: ${distance.toStringAsFixed(2)} metros");
          if (distance < 50) {
            _surveyShown = true;
            _showSurvey();
          }
        }
      }
    });
  }

  /// Pedir permisos de ubicación
  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  /// Calcular ruta usando OSRM (modo "walking")
  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/walking/'
      '${_currentLocation!.longitude},${_currentLocation!.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            (data['routes'][0]['geometry']['coordinates'] as List)
                .map((point) => LatLng(point[1] as double, point[0] as double))
                .toList();

        print('Ruta calculada con ${coordinates.length} puntos');
        setState(() {
          _route = coordinates;
        });
      } else {
        print('OSRM error. Body: ${response.body}');
      }
    } catch (e) {
      print('Error en _fetchRoute: $e');
      _showError('Error al calcular la ruta: $e');
    }
  }

  /// Muestra la encuesta (navega a la pantalla SurveyPage)
  void _showSurvey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SurveyPage()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Puntos Seguros"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(0, 0),
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 18,
                keepAlive: true,
                onMapReady: () {
                  // Al tener el mapa listo, si ya hay ubicación y marcadores, busca el punto seguro
                  // Solo se actualiza si el usuario no eligió un destino manualmente
                  if (_currentLocation != null &&
                      _safePointMarkers.isNotEmpty &&
                      !_userSelectedDestination) {
                    _findNearestSafePoint();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                CurrentLocationLayer(
                  alignPositionOnUpdate: AlignOnUpdate.always,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(
                        Icons.navigation,
                        color: Colors.white,
                      ),
                    ),
                    markerSize: Size(40, 40),
                    markerDirection: MarkerDirection.heading,
                  ),
                ),
                // Marcadores de puntos seguros
                MarkerLayer(markers: _safePointMarkers),
                // Polilínea de la ruta
                if (_route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        strokeWidth: 3.0,
                        color: Colors.red.withOpacity(0.7),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// -------------------------------------------------------------------------
/// NUEVA PANTALLA: Encuesta
/// -------------------------------------------------------------------------
class SurveyPage extends StatefulWidget {
  const SurveyPage({Key? key}) : super(key: key);

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  int? _rating;
  String _comment = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encuesta"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Por favor, califica tu experiencia en el punto seguro:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Calificación (1-5)",
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) => index + 1)
                    .map(
                      (rating) => DropdownMenuItem(
                        value: rating,
                        child: Text(rating.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Por favor, selecciona una calificación.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Comentarios (opcional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  _comment = value;
                },
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitSurvey,
                      child: const Text("Enviar"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Envía la encuesta a Firestore en la colección 'survey_responses'
  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });

    // Se obtiene el usuario actual (asegúrate de que esté autenticado)
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "desconocido";

    final surveyData = {
      'uid': uid,
      'rating': _rating,
      'comment': _comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('survey_responses')
          .add(surveyData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Encuesta enviada, ¡gracias!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar la encuesta: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
