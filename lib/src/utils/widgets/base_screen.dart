import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../../providers/auth_provider.dart';
import '../../providers/kpi_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/cliente_provider.dart';
import '../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../screens/home_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showDrawer;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final IconData? titleIcon; // Cambiado a IconData para usar Iconsax

  const BaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.showDrawer = true,
    this.actions,
    this.bottomNavigationBar,
    this.titleIcon,
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
          backgroundColor: Colors.white,
          drawer: showDrawer ? _buildDrawer(context, authProvider) : null,
          appBar: AppBar(
            title: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.colorScheme.primary,
            elevation: 0,
            actions: actions,
            iconTheme: const IconThemeData(color: Colors.white),
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
    final userName = authProvider.user?.displayName ?? 'Usuario';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      child: Column(
        children: [
          _buildDrawerHeader(authProvider, userInitial),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                if (isSupervisor) ...[
                  _buildDrawerItem(
                    context: context,
                    icon: Iconsax.chart, // Iconsax para KPIs
                    title: 'KPIs de Gestores',
                    route: AppRoutes.supervisorKpis,
                    isSelected: title == 'KPIs de Gestores',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Iconsax.location, // Iconsax para mapa
                    title: 'Mapa de Cobros',
                    route: AppRoutes.supervisorMap,
                    isSelected: title == 'Mapa de Cobros',
                  ),
                ] else ...[
                  _buildDrawerItem(
                    context: context,
                    icon: Iconsax.wallet, // Iconsax para préstamos
                    title: 'Mis Préstamos',
                    route: AppRoutes.gestorLoans,
                    isSelected: title == 'Mis Préstamos',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Iconsax.location, // Iconsax para mapa
                    title: 'Mapa de Cobros',
                    route: AppRoutes.gestorMap,
                    isSelected: title == 'Mapa de Cobros',
                  ),
                  
                ],
                const Divider(height: 32),
                _buildDrawerItem(
                  context: context,
                  icon: Iconsax.logout, // Iconsax para cerrar sesión
                  title: 'Cerrar Sesión',
                  route: AppRoutes.login,
                  isSelected: false,
                  textColor: Colors.red[700],
                  iconColor: Colors.red[700],
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider, String userInitial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.colorScheme.primary,
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        authProvider.user?.displayName ?? 'Usuario',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.card, // Iconsax para ID
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${authProvider.user?.uid ?? 'No ID'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    authProvider.user?.role == 'supervisor'
                        ? Iconsax.people // Iconsax para supervisor
                        : Iconsax.briefcase, // Iconsax para gestor
                    size: 12,
                    color: AppTheme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    authProvider.user?.role == 'supervisor'
                        ? 'Supervisor'
                        : 'Gestor',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final itemColor = isSelected
        ? AppTheme.colorScheme.primary
        : (textColor ?? Colors.grey[700]);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppTheme.colorScheme.primary
              : (iconColor ?? Colors.grey[600]),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.logout, // Iconsax para cerrar sesión
              size: 18,
              color: Colors.red[700],
            ),
            const SizedBox(width: 8),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.code, // Iconsax para versión
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            'Yatha App v1.0.0',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}