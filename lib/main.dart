import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/kpi_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/supervisor_provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gestor/loans_screen.dart';
import 'screens/gestor/map_screen.dart';
import 'screens/gestor/new_kpi_screen.dart';
import 'screens/gestor/profile_screen.dart';
import 'screens/supervisor/supervisor_kpi_screen.dart';
import 'screens/supervisor/supervisor_map_screen.dart';
import 'screens/gestor/loan_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KpiProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => SupervisorProvider()),
      ],
      child: GetMaterialApp(
        title: 'Yatha App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
          GetPage(name: AppRoutes.gestorLoans, page: () => const LoansScreen()),
          GetPage(name: AppRoutes.gestorMap, page: () => const MapScreen()),
          GetPage(name: AppRoutes.gestorKpis, page: () => const NewKpiScreen()),
          GetPage(
              name: AppRoutes.gestorProfile, page: () => const ProfileScreen()),
          GetPage(
              name: AppRoutes.supervisorKpis,
              page: () => const SupervisorKpiScreen()),
          GetPage(
              name: AppRoutes.supervisorMap,
              page: () => const SupervisorMapScreen()),
          GetPage(
            name: AppRoutes.loanDetail,
            page: () => const LoanDetailScreen(),
          ),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
      ),
    );
  }
}
