import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showDrawer;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.showDrawer = true,
    this.actions,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          drawer: showDrawer ? _buildDrawer(context, authProvider) : null,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppTheme.colorScheme.primary,
            actions: actions,
          ),
          body: SafeArea(
            child: body,
          ),
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: AppTheme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gestor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${authProvider.user?.uid ?? 'No ID'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/gestor/home',
            isSelected: title == 'Dashboard',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.payment,
            title: 'Pagos',
            route: '/gestor/payments',
            isSelected: title == 'Pagos',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.people,
            title: 'Clientes',
            route: '/gestor/clients',
            isSelected: title == 'Clientes',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.analytics,
            title: 'KPIs',
            route: '/gestor/kpis',
            isSelected: title == 'KPIs',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            route: '/login',
            isSelected: false,
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: AppTheme.colorScheme.primary.withOpacity(0.1),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            if (route == '/login') {
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                (route) => false,
              );
            } else {
              Navigator.pushReplacementNamed(context, route);
            }
          },
    );
  }
}
