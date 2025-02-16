// lib/widgets/custom_widgets.dart

import 'package:flutter/material.dart';

/// Un botón personalizado basado en ElevatedButton, pero con estilo y bordes uniformes.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Podemos usar el ElevatedButtonTheme del AppTheme o sobrescribir colores si es necesario.
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}

/// Una tarjeta con bordes redondeados, sombra suave y relleno.
class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const RoundedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos CardTheme del AppTheme (borde de 16, etc.)
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
