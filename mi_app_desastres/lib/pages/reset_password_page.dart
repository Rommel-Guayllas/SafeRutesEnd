import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart'; // Donde tienes CustomButton

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      // AppBar minimalista
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtítulo o explicación
            const Text(
              'Ingresa tu correo para resetear la contraseña',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Campo: Email
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 24),

            // Botón Recuperar
            CustomButton(
              label: 'Recuperar',
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingrese un correo válido')),
                  );
                  return;
                }

                await authService.resetPassword(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revisa tu correo')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
