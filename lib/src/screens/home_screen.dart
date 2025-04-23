import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/src/screens/gestor/new_kpi_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_kpi_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_map_screen.dart';
import '../../utils/widgets/bottom_nav_bar.dart';
import 'gestor/loans_screen.dart';
import 'gestor/map_screen.dart';
import 'gestor/profile_screen.dart';
import '../../utils/widgets/base_screen.dart';
import 'package:intl/intl.dart';
import '../../src/providers/kpi_provider.dart';
import '../../src/providers/auth_provider.dart';
import '../../src/providers/loan_provider.dart';
import '../../src/providers/payment_provider.dart';
import '../../src/providers/cliente_provider.dart';

class HomeScreen extends StatefulWidget {
  final int? initialIndex;
  const HomeScreen({Key? key, this.initialIndex}) : super(key: key);

  // Método estático para navegar a KPIs de manera segura
  static Future<void> navigateToKpis(BuildContext context) async {
    // Obtener los providers necesarios
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);

    // Limpiar datos existentes
    kpiProvider.changeUser(null);

    // Navegar al HomeScreen con el índice de KPIs
    await Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(initialIndex: 2),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _selectedIndex);

    // Cargar datos iniciales después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _cleanAndInitializeData();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pageController = null;
    super.dispose();
  }

  Future<void> _cleanAndInitializeData() async {
    if (!mounted) return;

    try {
      final kpiProvider = Provider.of<KpiProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final clienteProvider =
          Provider.of<ClienteProvider>(context, listen: false);

      // Limpiar datos existentes
      kpiProvider.changeUser(null);
      loanProvider.clearData();
      paymentProvider.clearData();
      clienteProvider.clearData();

      // Cargar datos nuevos si hay un usuario
      if (authProvider.user?.uid != null) {
        final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await kpiProvider.fetchDailyKPIs(
          authProvider.user!.uid.toString(),
          currentDate,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error al cargar los datos. Por favor, intente nuevamente.'),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted || _pageController == null) return;

    setState(() {
      _selectedIndex = index;
      _pageController?.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    // Recargar datos si cambiamos a la pantalla de KPIs
    if (index == 0) {
      _cleanAndInitializeData();
    }
  }

  void _handlePageChange(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });

    // Recargar datos si cambiamos a la pantalla de KPIs
    if (index == 0) {
      _cleanAndInitializeData();
    }
  }

  String _getTitle(bool isSupervisor) {
    if (isSupervisor) {
      switch (_selectedIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Gestores';
        case 2:
          return 'Mapa';
        case 3:
          return 'Perfil';
        default:
          return 'Yatha App';
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return 'Mis Préstamos';
        case 1:
          return 'Mapa de Cobros';
        case 2:
          return 'Indicadores';
        case 3:
          return 'Mi Perfil';
        default:
          return 'Yatha App';
      }
    }
  }

  List<Widget> _getScreens(bool isSupervisor) {
    if (isSupervisor) {
      return const [
        SupervisorKpiScreen(), // Dashboard con KPIs de gestores
        SupervisorKpiScreen(), // Lista de gestores
        SupervisorMapScreen(), // Mapa de gestores
        ProfileScreen(), // Perfil del supervisor
      ];
    } else {
      return const [
        LoansScreen(),
        MapScreen(),
        NewKpiScreen(),
        ProfileScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pageController == null) return const SizedBox.shrink();

    final authProvider = Provider.of<AuthProvider>(context);
    final isSupervisor = authProvider.user?.role == 'supervisor';

    return BaseScreen(
      title: _getTitle(isSupervisor),
      body: PageView(
        controller: _pageController!,
        onPageChanged: _handlePageChange,
        physics: const ClampingScrollPhysics(),
        children: _getScreens(isSupervisor),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        isGestor: !isSupervisor,
      ),
    );
  }
}
