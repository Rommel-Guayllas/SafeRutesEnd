import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Si estás usando tu CustomButton:
import '../widgets/custom_widgets.dart';

class SignUpPageWithRole extends StatefulWidget {
  const SignUpPageWithRole({super.key});

  @override
  _SignUpPageWithRoleState createState() => _SignUpPageWithRoleState();
}

class _SignUpPageWithRoleState extends State<SignUpPageWithRole> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  // Por defecto, el rol será 'user'
  String selectedRole = 'user';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      // AppBar minimalista, estilo iOS
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sign up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtítulo
            const Text(
              'Crea una cuenta para Iniciar',
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
                labelText: 'Correo',
              ),
            ),
            const SizedBox(height: 16),

            // Campo: Password
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
              ),
            ),
            const SizedBox(height: 16),

            // Campo: Confirm Password
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
              ),
            ),
            const SizedBox(height: 24),

            // Selector de rol
            const Text(
              'Selecciona tu rol:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'user',
                  groupValue: selectedRole,
                  onChanged: (val) {
                    setState(() => selectedRole = val!);
                  },
                ),
                const Text('usuario'),
                const SizedBox(width: 20),
                Radio<String>(
                  value: 'admin',
                  groupValue: selectedRole,
                  onChanged: (val) {
                    setState(() => selectedRole = val!);
                  },
                ),
                const Text('Administrator'),
              ],
            ),
            const SizedBox(height: 32),

            // Botón: Sign up
            CustomButton(
              label: 'Inicia Sesion',
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();
                final confirmPass = confirmPassCtrl.text.trim();

                if (name.isEmpty ||
                    email.isEmpty ||
                    pass.isEmpty ||
                    confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Todos los campos son requeridos')),
                  );
                  return;
                }

                if (pass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseñas no concuerdan')),
                  );
                  return;
                }

                final error =
                    await authService.signUp(email, pass, name, selectedRole);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  // Éxito, regresa a la pantalla anterior o navega al login
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 20),

            // Link para volver a Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tienen una cuenta? '),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
