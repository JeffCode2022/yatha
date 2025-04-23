import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/kpi_provider.dart';
import 'src/providers/loan_provider.dart';
import 'src/providers/payment_provider.dart';
import 'src/providers/cliente_provider.dart';
import 'src/providers/supervisor_provider.dart';
import 'utils/theme/app_theme.dart';
import 'src/routes/app_routes.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/gestor/loans_screen.dart';
import 'src/screens/gestor/map_screen.dart';
import 'src/screens/gestor/new_kpi_screen.dart';
import 'src/screens/gestor/profile_screen.dart';
import 'src/screens/supervisor/supervisor_kpi_screen.dart';
import 'src/screens/supervisor/supervisor_map_screen.dart';
import 'src/screens/gestor/loan_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => KpiProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => SupervisorProvider()),
      ],
      child: MyApp(
          initialRoute:
              authProvider.isAuthenticated ? AppRoutes.home : AppRoutes.login),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final List<GetPage> routes = [
      GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    ];

    if (authProvider.isAuthenticated) {
      if (authProvider.isSupervisor) {
        // Rutas específicas para supervisor
        routes.addAll([
          GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
          GetPage(
              name: AppRoutes.supervisorKpis,
              page: () => const SupervisorKpiScreen()),
          GetPage(
              name: AppRoutes.supervisorMap,
              page: () => const SupervisorMapScreen()),
          GetPage(
              name: AppRoutes.gestorProfile, page: () => const ProfileScreen()),
        ]);
      } else if (authProvider.isGestor) {
        // Rutas específicas para gestor
        routes.addAll([
          GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
          GetPage(name: AppRoutes.gestorLoans, page: () => const LoansScreen()),
          GetPage(name: AppRoutes.gestorMap, page: () => const MapScreen()),
          GetPage(name: AppRoutes.gestorKpis, page: () => const NewKpiScreen()),
          GetPage(
              name: AppRoutes.gestorProfile, page: () => const ProfileScreen()),
          GetPage(
              name: AppRoutes.loanDetail, page: () => const LoanDetailScreen()),
        ]);
      }
    }

    return GetMaterialApp(
      title: 'Yatha App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: routes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
    );
  }
}
