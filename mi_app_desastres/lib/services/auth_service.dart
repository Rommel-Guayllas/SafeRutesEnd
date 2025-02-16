import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? user;
  bool isLoading = true;

  AuthService() {
    _checkLogin();
  }

  /// Escucha los cambios de autenticación y actualiza el usuario y el estado de carga.
  void _checkLogin() {
    _auth.authStateChanges().listen((User? u) async {
      user = u;
      isLoading = false;
      notifyListeners();
    });
  }

  /// Registra un usuario nuevo con un rol específico ('user' o 'admin').
  /// - [email], [password], [displayName] y [role] son requeridos.
  /// - Almacena todos estos datos en la colección 'users' de Firestore.
  Future<String?> signUp(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    try {
      // Crea el usuario en FirebaseAuth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = cred.user;

      // Guarda la información en Firestore
      await _db.collection('users').doc(user!.uid).set({
        'uid': user!.uid,
        'email': email,
        'displayName': displayName,
        'role': role,
      });

      notifyListeners();
      return null; // Éxito, sin error
    } catch (e) {
      return e.toString(); // Devuelve el mensaje de error
    }
  }

  /// Inicia sesión con email y password.
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Cierra sesión.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Envía correo para resetear la contraseña.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Actualiza el displayName del usuario (en Firestore).
  Future<String?> updateProfile(String displayName) async {
    try {
      if (user == null) return 'No hay usuario autenticado';
      await _db
          .collection('users')
          .doc(user!.uid)
          .update({'displayName': displayName});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Esta función la puedes usar para saber si el usuario es admin
  Future<bool> isAdmin() async {
    if (user == null) return false;
    final doc = await _db.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final role = doc.data()!['role'] as String;
      return role == 'admin';
    }
    return false;
  }

  /// Elimina un usuario (documento) de Firestore.
  /// No elimina su cuenta en FirebaseAuth (para eso se requiere admin SDK o Cloud Functions).
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  /// Actualiza el 'displayName' de otro usuario (para uso de un admin).
  Future<void> updateOtherUser(String uid, String displayName) async {
    await _db.collection('users').doc(uid).update({'displayName': displayName});
  }
}
