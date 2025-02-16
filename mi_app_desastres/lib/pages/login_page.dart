import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'reset_password_page.dart';

// Si tu pantalla de registro se llama distinto, ajusta el import:
import '../pages/sign_up_page_with_role.dart';

// Si usas CustomButton, importa tus widgets personalizados:
import '../widgets/custom_widgets.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      // AppBar minimalista, estilo iOS
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // Evitamos overflow cuando el teclado aparece
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Título / Bienvenida
            const SizedBox(height: 16),
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa con tu cuenta para continuar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Campo: Correo electrónico
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            const SizedBox(height: 16),

            // Campo: Contraseña
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
              ),
            ),
            const SizedBox(height: 32),

            // Botón: Iniciar Sesión
            CustomButton(
              label: 'Iniciar Sesión',
              onPressed: () async {
                final error = await authService.login(
                  emailCtrl.text.trim(),
                  passCtrl.text.trim(),
                );
                if (error != null) {
                  // Error al iniciar sesión
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Link: ¿No tienes cuenta?
            TextButton(
              onPressed: () {
                // Navega a la pantalla de registro
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpPageWithRole()),
                );
              },
              child: const Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),

            // Link: ¿Olvidaste tu contraseña?
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResetPasswordPage()),
                );
              },
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
