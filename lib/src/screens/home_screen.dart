import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:yatha_app/src/screens/gestor/new_kpi_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_kpi_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_map_screen.dart';
import '../utils/widgets/bottom_nav_bar.dart';
import 'gestor/loans_screen.dart';
import 'gestor/map_screen.dart';
import 'gestor/profile_screen.dart';
import '../utils/widgets/base_screen.dart';
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

    // Usar Get.offAll para una navegación más segura
    await Get.offAll(
      () => const HomeScreen(initialIndex: 2),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  PageController? _pageController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isSupervisor = authProvider.user?.role == 'supervisor';
      final maxIndex = isSupervisor ? 2 : 3;

      // Ajustar el índice si es necesario
      if (_selectedIndex > maxIndex) {
        _selectedIndex = maxIndex;
        _pageController?.jumpToPage(_selectedIndex);
      }

      await _cleanAndInitializeData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Error',
          'Error al cargar los datos. Por favor, intente nuevamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
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
      await Future.wait([
        Future(() => kpiProvider.changeUser(null)),
        Future(() => loanProvider.clearData()),
        Future(() => paymentProvider.clearData()),
        Future(() => clienteProvider.clearData()),
      ]);

      // Cargar datos nuevos si hay un usuario
      if (authProvider.user?.uid != null) {
        final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await kpiProvider.fetchDailyKPIs(
          authProvider.user!.uid.toString(),
          currentDate,
        );
      }
    } catch (e) {
      debugPrint('Error cleaning and initializing data: $e');
      rethrow;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted || _pageController == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSupervisor = authProvider.user?.role == 'supervisor';
    final maxIndex = isSupervisor ? 2 : 3;

    if (index < 0 || index > maxIndex) return;

    setState(() {
      _selectedIndex = index;
      _pageController!.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    if (index == 0) {
      _cleanAndInitializeData();
    }
  }

  void _handlePageChange(int index) {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSupervisor = authProvider.user?.role == 'supervisor';
    final maxIndex = isSupervisor ? 2 : 3;

    // Validar el índice antes de actualizar
    if (index < 0 || index > maxIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Recargar datos si cambiamos a la pantalla principal
    if (index == 0) {
      _cleanAndInitializeData();
    }
  }

  void _handleDrawerNavigation(int index) {
    if (!mounted) return;

    // Cerrar el drawer
    Get.back();

    // Esperar a que el drawer se cierre antes de navegar
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _selectedIndex = index;
        _pageController!.jumpToPage(index);
      });

      // Recargar datos si es necesario
      if (index == 0) {
        _cleanAndInitializeData();
      }
    });
  }

  String _getTitle(bool isSupervisor) {
    if (isSupervisor) {
      switch (_selectedIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Mapa';
        case 2:
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isSupervisor = authProvider.user?.role == 'supervisor';

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
