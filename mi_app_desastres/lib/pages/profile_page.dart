import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart'; // CustomButton u otros widgets

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameCtrl = TextEditingController();
  String? displayName;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authService.user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        displayName = doc.data()!['displayName'];
        nameCtrl.text = displayName ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      // AppBar minimalista
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtítulo / indicación
            const Text(
              'Actualiza tu nombre de usuario',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // TextField para nombre
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),
            const SizedBox(height: 24),

            // Botón para Guardar cambios
            CustomButton(
              label: 'Guardar Cambios',
              onPressed: () async {
                final error =
                    await authService.updateProfile(nameCtrl.text.trim());
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
