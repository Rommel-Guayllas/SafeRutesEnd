import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class AddSafePointPage extends StatefulWidget {
  const AddSafePointPage({super.key});

  @override
  _AddSafePointPageState createState() => _AddSafePointPageState();
}

class _AddSafePointPageState extends State<AddSafePointPage> {
  final TextEditingController nameCtrl = TextEditingController();
  LatLng? selectedPoint;
  LatLng? currentLocation;
  bool isLoading = true;
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Inicializa la ubicación y obtiene la posición actual
  Future<void> _initializeLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        setState(() => isLoading = false);
        return;
      }
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() => isLoading = false);
        return;
      }
    }

    final locationData = await _locationService.getLocation();
    setState(() {
      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      isLoading = false;
    });
  }

  /// Muestra un diálogo para ingresar el nombre del refugio
  Future<void> _showNameDialog(LatLng point) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nombre del Refugio'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Ingresa el nombre del refugio',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPoint = point;
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Guarda el punto seguro en Firestore
  Future<void> _saveSafePoint() async {
    final name = nameCtrl.text.trim();

    if (name.isEmpty || selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor ingresa un nombre y selecciona un punto en el mapa')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('safe_points').add({
        'name': name,
        'latitude': selectedPoint!.latitude,
        'longitude': selectedPoint!.longitude,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto seguro guardado con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Agregar Punto Seguro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: currentLocation ?? LatLng(0, 0),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag
                            .doubleTapZoom, // Desactiva el zoom con doble clic
                      ),
                      onTap: (tapPosition, point) {
                        _showNameDialog(
                            point); // Usa onTap en lugar de onDoubleTap
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (selectedPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40,
                              height: 40,
                              point: selectedPoint!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _saveSafePoint,
                    child: const Text('Guardar Punto Seguro'),
                  ),
                ),
              ],
            ),
    );
  }
}
