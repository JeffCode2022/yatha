import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/gestor/gestor_dashboard.dart';
import 'screens/gestor/loan_detail_screen.dart';
import 'screens/supervisor/supervisor_dashboard.dart';
import 'screens/supervisor/gestor_detail_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const YathaApp());
}

class YathaApp extends StatelessWidget {
  const YathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yatha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppTheme.colorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppTheme.colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.colorScheme.surface,
          foregroundColor: AppTheme.colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.colorScheme.onSurface,
          ),
          iconTheme: IconThemeData(color: AppTheme.colorScheme.primary),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: AppTheme.colorScheme.shadow.withAlpha(77),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.colorScheme.outline.withAlpha(128),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.colorScheme.error, width: 2),
          ),
          labelStyle: TextStyle(color: AppTheme.colorScheme.onSurfaceVariant),
          hintStyle: TextStyle(
            color: AppTheme.colorScheme.onSurfaceVariant.withAlpha(153),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colorScheme.primary,
            foregroundColor: AppTheme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.colorScheme.primary,
            side: BorderSide(color: AppTheme.colorScheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: AppTheme.colorScheme.primary,
          unselectedLabelColor: AppTheme.colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.colorScheme.primary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/gestor/dashboard': (context) => const GestorDashboard(),
        '/gestor/loan-detail': (context) => const LoanDetailScreen(),
        '/supervisor/dashboard': (context) => const SupervisorDashboard(),
        '/supervisor/gestor-detail': (context) => const GestorDetailScreen(),
      },
    );
  }
}
