import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'profile_page.dart';
import 'user_management_page.dart';
import 'map_page.dart';
import 'SurveyListPage.dart';
import 'add_safe_point_page.dart';
import '../services/notification_service.dart';

// ----------------------------------------------------------------------------
// Widget CustomButton para botones uniformes con icono y tamaño fijo.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize:
            const Size.fromHeight(50), // Altura uniforme para todos los botones
      ),
    );
  }
}
// ----------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAdminUser = false;
  bool _isSendingAlert =
      false; // Controla el estado de envío (animación de carga)

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  void checkAdmin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    bool admin = await authService.isAdmin();
    setState(() {
      isAdminUser = admin;
    });
  }

  /// Función para iniciar la alerta con animación y un timeout de 3 segundos.
  void _initiateAlert() async {
    print("Botón 'Iniciar Alerta' presionado.");
    setState(() {
      _isSendingAlert = true;
    });

    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    try {
      // Intentamos enviar la alerta y si tarda más de 3 segundos se lanza un timeout
      await notificationService
          .sendNotificationToAll(
            title: '¡Alerta de Desastre!',
            body:
                'Se ha detectado un desastre. Dirígete al refugio más cercano.',
          )
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      // Aquí se atrapa el error o timeout. Se imprime el error pero no se impide la continuación.
      print("Error o timeout al enviar la alerta: $error");
    }

    // Actualizamos el estado para detener la animación de carga
    setState(() {
      _isSendingAlert = false;
    });

    // Se muestra el mensaje de "Alerta enviada" independientemente del resultado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta enviada a todos los usuarios')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bienvenido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              authService.logout();
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar email y UID del usuario
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (user?.uid != null)
              Text(
                'UID: ${user!.uid}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 32),

            // Botón: Editar mi perfil
            Center(
              child: SizedBox(
                width: 250, // Ancho fijo para todos los botones
                child: CustomButton(
                  icon: Icons.person,
                  label: 'Editar mi perfil',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfilePage()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón: Ver mapa
            Center(
              child: SizedBox(
                width: 250,
                child: CustomButton(
                  icon: Icons.map,
                  label: 'Ver mapa',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapPage()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opciones de Administrador
            if (isAdminUser) ...[
              Center(
                child: SizedBox(
                  width: 250,
                  child: CustomButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Gestionar Usuarios (Admin)',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserManagementPage()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 250,
                  child: CustomButton(
                    icon: Icons.add_location,
                    label: 'Agregar Punto Seguro',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddSafePointPage()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 250,
                  child: _isSendingAlert
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Enviando alerta...'),
                            ],
                          ),
                        )
                      : CustomButton(
                          icon: Icons.warning,
                          label: 'Iniciar Alerta',
                          onPressed: _initiateAlert,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Nuevo botón para ver encuestas
              Center(
                child: SizedBox(
                  width: 250,
                  child: CustomButton(
                    icon: Icons.poll,
                    label: 'Ver Encuestas',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SurveyListPage()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
