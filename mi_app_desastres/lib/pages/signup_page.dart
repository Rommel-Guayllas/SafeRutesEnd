import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart'; // Donde tengas tu CustomButton

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      // AppBar minimalista
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtítulo: un pequeño texto para guiar al usuario
            const Text(
              'Completa tus datos para continuar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Campo: Nombre
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),
            const SizedBox(height: 16),

            // Campo: Email
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16),

            // Campo: Password
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 24),

            // Botón: Registrar
            CustomButton(
              label: 'Registrar',
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final password = passCtrl.text.trim();
                final name = nameCtrl.text.trim();

                if (email.isEmpty || password.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Todos los campos son obligatorios')),
                  );
                  return;
                }

                // Registramos con rol "user"
                final error = await authService.signUp(
                  email,
                  password,
                  name,
                  'user', // Cambia a 'admin' si quieres registro de admin
                );

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  // Éxito, volvemos atrás o navega donde quieras
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
