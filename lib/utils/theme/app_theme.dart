import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E3147),
    primary: const Color(0xFF0A8D5B),
    secondary: const Color(0xFF4A90E2),
    background: const Color(0xFFF5F6FA),

  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static const primaryColor = Color(0xFF1565C0);
  static const secondaryColor = Color(0xFF0A8D5B);
  static const tertiaryColor = Color(0xFFD32F2F);

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
