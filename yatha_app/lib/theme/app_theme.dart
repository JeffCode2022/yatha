import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores retro para una aplicación de cobranza y préstamos
  static const Color primaryColor = Color(0xFF1F6E5C); // Verde oscuro
  static const Color secondaryColor = Color(0xFFE9B44C); // Dorado/Amarillo
  static const Color tertiaryColor = Color(0xFFAD343E); // Rojo oscuro para alertas
  static const Color neutralColor = Color(0xFF2C363F); // Gris oscuro
  static const Color backgroundColor = Color(0xFFF5F5F5); // Fondo claro
  static const Color surfaceColor = Color(0xFFFFFFFF); // Superficie blanca
  static const Color errorColor = Color(0xFFB00020); // Rojo error

  static const ColorScheme colorScheme = ColorScheme(
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFB8E5D9),
    onPrimaryContainer: Color(0xFF0A3D31),
    secondary: secondaryColor,
    onSecondary: Color(0xFF3C2E00),
    secondaryContainer: Color(0xFFF7E8C3),
    onSecondaryContainer: Color(0xFF553F00),
    tertiary: tertiaryColor,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDAD9),
    onTertiaryContainer: Color(0xFF410008),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: backgroundColor,
    onBackground: neutralColor,
    surface: surfaceColor,
    onSurface: neutralColor,
    surfaceVariant: Color(0xFFEAE1D9),
    onSurfaceVariant: Color(0xFF4D4639),
    outline: Color(0xFF7C736A),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Color(0xFFEFEFEF),
    inversePrimary: Color(0xFF8CD1C3),
    brightness: Brightness.light,
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

