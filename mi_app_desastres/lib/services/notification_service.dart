import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _serverKey =
      'BJqvMGK2fhuBbgX-AhOXxoxu8gQyW479hI0-EaxbpStQZkHoEL-e1v8DRBto-j0efy0LKf3pBCMxiOsz2kZAa_U'; // Reemplaza con tu server key de Firebase

  /// Envía una notificación a todos los usuarios registrados en Firestore
  Future<void> sendNotificationToAll(
      {required String title, required String body}) async {
    // Obtener todos los tokens de dispositivos registrados
    final snapshot = await _firestore.collection('user_tokens').get();
    final tokens = snapshot.docs.map((doc) => doc['token'] as String).toList();

    // Enviar notificación a cada token
    for (var token in tokens) {
      await _sendNotification(token, title, body);
    }
  }

  /// Envía una notificación a un token específico usando la API HTTP de FCM
  Future<void> _sendNotification(
      String token, String title, String body) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_serverKey',
    };

    final bodyData = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        'type': 'alert',
        'route': '/map', // Redirigir al mapa al hacer clic en la notificación
      },
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      print('Notificación enviada correctamente');
    } else {
      print('Error al enviar notificación: ${response.body}');
    }
  }

  /// Guarda el token del dispositivo en Firestore
  Future<void> saveToken(String userId, String token) async {
    await _firestore.collection('user_tokens').doc(userId).set({
      'token': token,
    });
  }
}
