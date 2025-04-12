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
          body: body,
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
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/gestor/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Pagos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/gestor/payments');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/gestor/clients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('KPIs'),
            selected: title == 'KPIs',
            selectedTileColor: AppTheme.colorScheme.primary.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/gestor/kpis');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
