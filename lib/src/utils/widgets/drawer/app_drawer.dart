import 'package:flutter/material.dart';
import 'package:yatha_app/src/models/user_role.dart';
import 'package:yatha_app/src/utils/theme/app_theme.dart';
import 'package:get/get.dart';

class AppDrawer extends StatefulWidget {
  final UserRole userRole;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AppDrawer({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMenuItems(),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: widget.userAvatar != null
                ? NetworkImage(widget.userAvatar!)
                : null,
            child: widget.userAvatar == null
                ? Text(
                    widget.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.userRole == UserRole.supervisor ? 'Supervisor' : 'Gestor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userEmail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final List<DrawerItem> items = widget.userRole == UserRole.supervisor
        ? [
            DrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              index: 0,
            ),
            DrawerItem(
              icon: Icons.map_outlined,
              title: 'Mapa',
              index: 1,
            ),
            DrawerItem(
              icon: Icons.people_outlined,
              title: 'Gestores',
              index: 2,
            ),
            DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Préstamos por Cobrar',
              index: 3,
            ),
            DrawerItem(
              icon: Icons.account_balance_outlined,
              title: 'Caja',
              index: 4,
            ),
          ]
        : [
            DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Mis Préstamos',
              index: 0,
            ),
            DrawerItem(
              icon: Icons.map_outlined,
              title: 'Mapa de Cobros',
              index: 1,
            ),
            DrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Indicadores',
              index: 2,
            ),
            DrawerItem(
              icon: Icons.person_outlined,
              title: 'Mi Perfil',
              index: 3,
            ),
          ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = widget.selectedIndex == item.index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? AppTheme.colorScheme.primary
                  : AppTheme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              item.title,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.colorScheme.primary
                    : AppTheme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () {
              // Usar Get.back() para cerrar el drawer de manera segura
              Get.back();

              // Esperar a que el drawer se cierre antes de navegar
              Future.delayed(const Duration(milliseconds: 300), () {
                try {
                  widget.onItemSelected(item.index);
                } catch (e) {
                  print('Error al navegar: $e');
                  Get.snackbar(
                    'Error',
                    'Error al navegar. Por favor intente nuevamente.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                }
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: AppTheme.tertiaryColor,
        ),
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: AppTheme.tertiaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          // Usar Get.back() para cerrar el drawer de manera segura
          Get.back();

          // Esperar a que el drawer se cierre antes de hacer logout
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              widget.onLogout();
            } catch (e) {
              print('Error al cerrar sesión: $e');
              Get.snackbar(
                'Error',
                'Error al cerrar sesión. Por favor intente nuevamente.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          });
        },
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final int index;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}
