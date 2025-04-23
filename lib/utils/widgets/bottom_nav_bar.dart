import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    final items = isGestor
        ? [
            _buildNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: 'Préstamos',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Mapa',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.insert_chart_outlined_rounded,
              activeIcon: Icons.insert_chart_rounded,
              label: 'KPI',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
            ),
          ]
        : [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.groups_outlined,
              activeIcon: Icons.groups_rounded,
              label: 'Gestores',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Mapa',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24, top: 8),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0DB774).withOpacity(0.7),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
