// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'firebase_options.dart'; // Archivo generado por FlutterFire CLI
import 'pages/login_page.dart';
import 'pages/home_page.dart';

// 1. Importamos el tema global
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Flutter Firebase Auth CRUD',
      // 2. Usamos nuestro tema minimalista
      theme: AppTheme.lightTheme,
      home: authService.isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : authService.user == null
              ? LoginPage()
              : HomePage(),
    );
  }
}
