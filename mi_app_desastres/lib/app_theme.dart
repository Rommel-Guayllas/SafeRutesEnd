// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Tema claro
  static ThemeData get lightTheme {
    // Usamos Material 3 (opcional), pero le da un look más moderno
    return ThemeData(
      useMaterial3: true,

      // Definimos una paleta de colores a partir de un "seed" (Colors.indigo en este ejemplo)
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),

      // Definimos la tipografía por defecto (puedes cambiar por Roboto, Open Sans, etc.)
      fontFamily: 'Roboto',

      // Personalizamos la AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // ElevatedButton con estilo uniforme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton con estilo minimal
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo, // texto del botón
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),

      // Input (TextField) estilo minimal
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Tarjetas con bordes suaves (Card)
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
