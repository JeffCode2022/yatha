import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../src/providers/auth_provider.dart';
import '../../src/providers/kpi_provider.dart';
import '../../src/providers/loan_provider.dart';
import '../../src/providers/payment_provider.dart';
import '../../src/providers/cliente_provider.dart';
import '../theme/app_theme.dart';
import '../../src/routes/app_routes.dart';
import '../../src/screens/home_screen.dart';

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

  Future<void> _handleLogout(BuildContext context) async {
    // Limpiar datos de todos los providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final clienteProvider =
        Provider.of<ClienteProvider>(context, listen: false);

    // Limpiar datos de cada provider
    kpiProvider.changeUser(null);
    loanProvider.clearData();
    paymentProvider.clearData();
    clienteProvider.clearData();

    // Cerrar sesión en AuthProvider
    await authProvider.logout();

    // Navegar a la pantalla de login y eliminar todas las rutas anteriores
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isSupervisor = authProvider.user?.role == 'supervisor';
        return Scaffold(
          drawer: showDrawer ? _buildDrawer(context, authProvider) : null,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Color(0xFF0DB774).withOpacity(1),
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
    final isSupervisor = authProvider.user?.role == 'supervisor';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0DB774).withOpacity(1)),
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
                  authProvider.user?.name ?? 'Usuario',
                  style: const TextStyle(
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
          if (isSupervisor) ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.analytics,
              title: 'KPIs de Gestores',
              route: AppRoutes.supervisorKpis,
              isSelected: title == 'KPIs de Gestores',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.map,
              title: 'Mapa de Cobros',
              route: AppRoutes.supervisorMap,
              isSelected: title == 'Mapa de Cobros',
            ),
          ] else ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.account_balance_wallet,
              title: 'Mis Préstamos',
              route: AppRoutes.gestorLoans,
              isSelected: title == 'Mis Préstamos',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.map,
              title: 'Mapa de Cobros',
              route: AppRoutes.gestorMap,
              isSelected: title == 'Mapa de Cobros',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.analytics,
              title: 'Mis KPIs',
              route: AppRoutes.gestorKpis,
              isSelected: title == 'Indicadores',
            ),
          ],
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            route: AppRoutes.login,
            isSelected: false,
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cerrar Sesión'),
                content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
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
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap ??
          () {
            Get.back(); // Cerrar el drawer

            // Navegar según la ruta
            if (route == AppRoutes.gestorKpis) {
              Get.offAll(
                () => const HomeScreen(initialIndex: 2),
                transition: Transition.fade,
              );
            } else if (route == AppRoutes.gestorLoans) {
              Get.offAll(
                () => const HomeScreen(initialIndex: 0),
                transition: Transition.fade,
              );
            } else if (route == AppRoutes.gestorMap) {
              Get.offAll(
                () => const HomeScreen(initialIndex: 1),
                transition: Transition.fade,
              );
            } else if (route == AppRoutes.supervisorKpis) {
              Get.offAll(
                () => const HomeScreen(initialIndex: 0),
                transition: Transition.fade,
              );
            } else if (route == AppRoutes.supervisorMap) {
              Get.offAll(
                () => const HomeScreen(initialIndex: 1),
                transition: Transition.fade,
              );
            } else {
              Get.offAllNamed(route);
            }
          },
    );
  }
}
