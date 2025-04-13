import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/gestor/kpi_screen.dart';
import '../screens/gestor/loans_screen.dart';
import 'gestor/map_screen.dart';
import '../screens/gestor/profile_screen.dart';
import '../widgets/base_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  String _getTitle() {
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

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: _getTitle(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          LoansScreen(),
          MapScreen(),
          KpiScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
