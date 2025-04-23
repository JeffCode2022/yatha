import 'package:flutter/material.dart';
import 'package:yatha_app/src/screens/auth/login_screen.dart';
import 'package:yatha_app/src/screens/gestor/loans_screen.dart';
import 'package:yatha_app/src/screens/gestor/map_screen.dart';
import 'package:yatha_app/src/screens/gestor/new_kpi_screen.dart';
import 'package:yatha_app/src/screens/gestor/profile_screen.dart';
import 'package:yatha_app/src/screens/home_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_kpi_screen.dart';
import 'package:yatha_app/src/screens/supervisor/supervisor_map_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String gestorHome = '/gestor/home';
  static const String supervisorHome = '/supervisor/home';
  static const String gestorLoans = '/gestor/loans';
  static const String gestorMap = '/gestor/map';
  static const String gestorKpis = '/gestor/kpis';
  static const String gestorProfile = '/gestor/profile';
  static const String supervisorKpis = '/supervisor/kpis';
  static const String supervisorMap = '/supervisor/map';
  static const String loanDetail = '/loan-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        final initialIndex = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(initialIndex: initialIndex),
        );
      case gestorLoans:
        return MaterialPageRoute(builder: (_) => const LoansScreen());
      case gestorMap:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case gestorKpis:
        return MaterialPageRoute(builder: (_) => const NewKpiScreen());
      case gestorProfile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case supervisorKpis:
        return MaterialPageRoute(builder: (_) => const SupervisorKpiScreen());
      case supervisorMap:
        return MaterialPageRoute(builder: (_) => const SupervisorMapScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
