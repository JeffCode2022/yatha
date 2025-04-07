import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  final String? userAvatar;
  final List<DrawerMenuItem> menuItems;
  final VoidCallback onLogout;

  const ProfileDrawer({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    this.userAvatar,
    required this.menuItems,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            Container(
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
                    backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                    child: userAvatar == null
                        ? Text(
                            userName.substring(0, 1).toUpperCase(),
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
                    userName,
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
                      userRole,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: item.isSelected
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: item.isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: item.isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.colorScheme.onSurface,
                          fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: item.onTap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
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
              onTap: onLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  DrawerMenuItem({
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });
}

