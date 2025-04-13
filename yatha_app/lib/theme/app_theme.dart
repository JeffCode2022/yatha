import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1565C0);
  static const secondaryColor = Color(0xFF2E7D32);
  static const tertiaryColor = Color(0xFFD32F2F);
  
  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    error: Color(0xFFB00020),
    onError: Colors.white,
    background: Color(0xFFF5F5F5),
    onBackground: Color(0xFF121212),
    surface: Colors.white,
    onSurface: Color(0xFF121212),
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondaryContainer: Color(0xFFC8E6C9),
    onSecondaryContainer: Color(0xFF1B5E20),
    shadow: Colors.black,
  );

  // Estilos para efectos de blur
  static BoxDecoration blurCardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
    border: Border.all(
      color: Colors.white.withOpacity(0.5),
      width: 1.5,
    ),
  );

  // Estilos para tarjetas con efecto de vidrio
  static BoxDecoration glassCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.5),
        Colors.white.withOpacity(0.3),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
    border: Border.all(
      color: Colors.white.withOpacity(0.5),
      width: 1.5,
    ),
  );

  // Estilos para botones con efecto de presión
  static BoxDecoration pressedButtonDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 8,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Estilos para tarjetas de estado
  static BoxDecoration statusCardDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.5),
        width: 1,
      ),
    );
  }
}
