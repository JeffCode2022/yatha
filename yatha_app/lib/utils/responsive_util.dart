import 'package:flutter/material.dart';

/// Utilidad para manejar dimensiones responsivas en la aplicación
class ResponsiveUtil {
  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static double _blockSizeHorizontal = 0;
  static double _blockSizeVertical = 0;
  
  static double textScaleFactor = 1.0;
  
  // Inicializar con el contexto actual
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
    
    // Ajustar escala de texto basado en el tamaño de la pantalla
    textScaleFactor = _screenWidth < 360 ? 0.8 : 
                      _screenWidth < 600 ? 1.0 : 
                      _screenWidth < 900 ? 1.1 : 1.2;
  }
  
  // Obtener ancho basado en porcentaje de pantalla
  static double w(double percentage) {
    return _blockSizeHorizontal * percentage;
  }
  
  // Obtener alto basado en porcentaje de pantalla
  static double h(double percentage) {
    return _blockSizeVertical * percentage;
  }
  
  // Obtener tamaño adaptativo (el menor entre ancho y alto)
  static double sp(double percentage) {
    return percentage * (_blockSizeHorizontal < _blockSizeVertical ? 
                         _blockSizeHorizontal : _blockSizeVertical);
  }
  
  // Verificar si es un dispositivo pequeño
  static bool isSmallDevice() {
    return _screenWidth < 360;
  }
  
  // Verificar si es una tablet
  static bool isTablet() {
    return _screenWidth >= 600;
  }
  
  // Verificar si es un dispositivo grande (tablet grande o desktop)
  static bool isLargeDevice() {
    return _screenWidth >= 900;
  }
  
  // Obtener padding adaptativo basado en el tamaño del dispositivo
  static EdgeInsets getScaledPadding(EdgeInsets basePadding) {
    double factor = isSmallDevice() ? 0.8 : 
                    isTablet() ? 1.2 : 
                    isLargeDevice() ? 1.5 : 1.0;
    
    return EdgeInsets.fromLTRB(
      basePadding.left * factor,
      basePadding.top * factor,
      basePadding.right * factor,
      basePadding.bottom * factor
    );
  }
  
  // Obtener tamaño de fuente adaptativo
  static double fontSize(double size) {
    return size * textScaleFactor;
  }
}

// Extensión para facilitar el uso de ResponsiveUtil
extension ResponsiveExtension on BuildContext {
  // Inicializar ResponsiveUtil con este contexto
  void initResponsive() {
    ResponsiveUtil.init(this);
  }
  
  // Obtener ancho basado en porcentaje
  double w(double percentage) {
    return ResponsiveUtil.w(percentage);
  }
  
  // Obtener alto basado en porcentaje
  double h(double percentage) {
    return ResponsiveUtil.h(percentage);
  }
  
  // Obtener tamaño adaptativo
  double sp(double percentage) {
    return ResponsiveUtil.sp(percentage);
  }
  
  // Verificar si es un dispositivo pequeño
  bool isSmallDevice() {
    return ResponsiveUtil.isSmallDevice();
  }
  
  // Verificar si es una tablet
  bool isTablet() {
    return ResponsiveUtil.isTablet();
  }
  
  // Verificar si es un dispositivo grande
  bool isLargeDevice() {
    return ResponsiveUtil.isLargeDevice();
  }
  
  // Obtener padding adaptativo
  EdgeInsets getScaledPadding(EdgeInsets basePadding) {
    return ResponsiveUtil.getScaledPadding(basePadding);
  }
  
  // Obtener tamaño de fuente adaptativo
  double fontSize(double size) {
    return ResponsiveUtil.fontSize(size);
  }
}
