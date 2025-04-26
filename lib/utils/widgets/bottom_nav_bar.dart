import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isGestor;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.isGestor = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dimensiones ultra compactas
    final containerHeight = 52.0;
    final iconSize = 18.0;
    final fontSize = 9.0;
    final itemWidth = 48.0;
    
    // Colores con efecto de gradiente
    final primaryColor = const Color(0xFF0DB774);
    final secondaryColor = const Color(0xFF09A668);
    final accentColor = Colors.white;
    
    final items = isGestor
        ? [
            _buildNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: 'Préstamos',
              index: 0,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            _buildNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Mapa',
              index: 1,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            _buildNavItem(
              icon: Icons.insert_chart_outlined_rounded,
              activeIcon: Icons.insert_chart_rounded,
              label: 'KPI',
              index: 2,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
          ]
        : [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              index: 0,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            _buildNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Mapa',
              index: 1,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              index: 2,
              iconSize: iconSize,
              fontSize: fontSize,
              itemWidth: itemWidth,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16, top: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: containerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required double iconSize,
    required double fontSize,
    required double itemWidth,
    required Color primaryColor,
    required Color accentColor,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        // Efecto de vibración sutil
        HapticFeedback.lightImpact();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor del icono con efectos
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: isSelected ? 1.0 : 0.8),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Efecto de resplandor para el icono activo
                      if (isSelected)
                        Container(
                          width: iconSize * 1.8,
                          height: iconSize * 1.8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      // Fondo del icono
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isSelected ? 6 : 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.25) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          size: iconSize,
                          color: isSelected 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 1),
            // Texto con efecto de fade
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}