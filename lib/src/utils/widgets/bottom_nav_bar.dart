import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
    // Dimensiones ajustadas para evitar overflow
    final containerHeight = 100.0; // Aumentado para dar más espacio
    final iconSize = 22.0; // Reducido ligeramente
    final fontSize = 11.0; // Reducido ligeramente

    // Colores estilo WhatsApp
    final primaryColor = const Color(0xFF128C7E); // Verde WhatsApp
    final selectedBackgroundColor = const Color(0xFFDCF8C6)
        .withOpacity(0.5); // Fondo verde claro para seleccionado
    final backgroundColor = Colors.white;
    final unselectedItemColor = Colors.grey;
    final notificationColor =
        const Color(0xFF25D366); // Verde brillante para notificaciones

    final items = isGestor
        ? [
            _buildNavItem(
              icon: Iconsax.wallet,
              activeIcon: Iconsax.wallet,
              label: 'Préstamos',
              index: 0,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
            _buildNavItem(
              icon: Iconsax.map,
              activeIcon: Iconsax.map,
              label: 'Mapa',
              index: 1,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
            _buildNavItem(
              icon: Iconsax.chart,
              activeIcon: Iconsax.chart,
              label: 'KPI',
              index: 2,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
            _buildNavItem(
              icon: Iconsax.profile_circle,
              activeIcon: Iconsax.profile_circle,
              label: 'Perfil',
              index: 3,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
          ]
        : [
            _buildNavItem(
              icon: Iconsax.category,
              activeIcon: Iconsax.category,
              label: 'Dashboard',
              index: 0,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
            _buildNavItem(
              icon: Iconsax.map,
              activeIcon: Iconsax.map,
              label: 'Mapa',
              index: 1,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
            _buildNavItem(
              icon: Iconsax.profile_circle,
              activeIcon: Iconsax.profile_circle,
              label: 'Perfil',
              index: 2,
              iconSize: iconSize,
              fontSize: fontSize,
              primaryColor: primaryColor,
              selectedBackgroundColor: selectedBackgroundColor,
              unselectedItemColor: unselectedItemColor,
              notificationCount: 0,
              notificationColor: notificationColor,
            ),
          ];

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        // Establecemos top: false para que no añada padding adicional en la parte superior
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items,
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
    required Color primaryColor,
    required Color selectedBackgroundColor,
    required Color unselectedItemColor,
    required int notificationCount,
    required Color notificationColor,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        // Usamos SizedBox con altura fija para evitar overflow
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor para el icono y la notificación
            Stack(
              clipBehavior: Clip.none, // Permite que el badge salga del Stack
              children: [
                // Icono con fondo rectangular cuando está seleccionado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedBackgroundColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: iconSize,
                    color: isSelected ? primaryColor : unselectedItemColor,
                  ),
                ),

                // Badge de notificación (como en WhatsApp)
                if (notificationCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: notificationColor,
                        shape: BoxShape.rectangle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2), // Reducido el espacio
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.0, // Altura de línea ajustada para evitar overflow
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? primaryColor : unselectedItemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
