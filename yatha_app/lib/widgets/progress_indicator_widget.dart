import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showAnimation;

  const ProgressIndicatorWidget({
    Key? key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 10.0,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          // Fondo con patrón retro
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.grey[200],
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: CustomPaint(
                painter: GridPatternPainter(
                  color: Colors.grey[300]!,
                  lineWidth: 1,
                  spacing: 5,
                ),
              ),
            ),
          ),
          
          // Barra de progreso con animación
          AnimatedContainer(
            duration: showAnimation 
                ? const Duration(milliseconds: 800) 
                : Duration.zero,
            curve: Curves.easeInOut,
            width: value * MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color ?? AppTheme.primaryColor,
                  color?.withOpacity(0.8) ?? AppTheme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (value > 0.05)
                  Container(
                    width: height * 0.8,
                    height: height * 0.8,
                    margin: EdgeInsets.only(right: height * 0.1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double spacing;

  GridPatternPainter({
    required this.color,
    required this.lineWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;

    // Dibujar líneas diagonales
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(0, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

