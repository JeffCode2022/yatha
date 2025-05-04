import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/kpi_provider.dart';

import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Paleta de colores
  final Color colorGreen = const Color(0xFF00C853); // Verde brillante
  final Color colorWhite = Colors.white;
  final Color colorBackground = const Color(0xFFE0F2E9); // Fondo verde claro
  final Color colorDarkText = const Color(0xFF333333);
  final Color colorLightText = const Color(0xFF757575);
  final Color colorError = const Color(0xFFE53935); // Rojo para errores

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Método para mostrar el modal de recuperación de contraseña
  void _showPasswordRecoveryModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Iconsax.key, // Iconsax para recuperación de contraseña
                color: colorGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Recuperación de contraseña',
                style: TextStyle(
                  color: colorGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Para recuperar la contraseña contacte con el área de soporte.',
            style: TextStyle(
              color: colorDarkText,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Iconsax.tick_circle, // Iconsax para aceptar
                size: 16,
                color: colorGreen,
              ),
              label: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: colorGreen,
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Método para mostrar alerta de error de inicio de sesión
  void _showLoginErrorAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Iconsax.danger, // Iconsax para error
                color: colorError,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Error de inicio de sesión',
                style: TextStyle(
                  color: colorDarkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Las credenciales ingresadas son incorrectas. Por favor, verifica tu correo y contraseña e intenta nuevamente.',
            style: TextStyle(
              color: colorDarkText,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Iconsax.tick_circle, // Iconsax para aceptar
                size: 16,
                color: colorGreen,
              ),
              label: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: colorGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);

    kpiProvider.changeUser(null);

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await kpiProvider.fetchDailyKPIs(authProvider.user!.uid.toString(), date);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      setState(() {
        _errorMessage = "Correo o contraseña incorrectos.";
      });
      
      // Mostrar alerta de error
      _showLoginErrorAlert();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Área del encabezado con logo
              Container(
                padding: const EdgeInsets.only(top: 40, bottom: 30),
                child: Column(
                  children: [
                    // Logo en círculo blanco
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/yatha_logo.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    // Texto YATHA FINANCIERA
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(
                          "YATHA",
                          style: TextStyle(
                            color: colorWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "FINANCIERA",
                          style: TextStyle(
                            color: colorWhite.withOpacity(0.9),
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tarjeta de login
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorWhite,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título de Iniciar Sesión alineado a la izquierda con línea verde
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.login, // Iconsax para login
                                      color: colorDarkText,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Iniciar Sesión",
                                      style: TextStyle(
                                        color: colorDarkText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 140, // Ancho de la línea verde
                                  height: 3,
                                  color: colorGreen,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Campo de email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.sms, // Iconsax para email
                                      color: colorDarkText,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Email",
                                      style: TextStyle(
                                        color: colorDarkText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    color: colorDarkText,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "nombre@yatha.com",
                                    hintStyle: TextStyle(
                                      color: colorLightText.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Iconsax.user, // Iconsax para usuario
                                      color: colorLightText,
                                      size: 18,
                                    ),
                                    errorStyle: TextStyle(
                                      color: colorError,
                                      fontSize: 12,
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Ingresa tu correo'
                                      : null,
                                ),
                                if (_usernameController.text.isEmpty &&
                                    _errorMessage.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6, left: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.info_circle, // Iconsax para información
                                          color: colorError,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Ingresa tu correo",
                                          style: TextStyle(
                                            color: colorError,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Campo de contraseña
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.password_check, // Iconsax para contraseña
                                      color: colorDarkText,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Password",
                                      style: TextStyle(
                                        color: colorDarkText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    color: colorDarkText,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "••••••••••",
                                    hintStyle: TextStyle(
                                      color: colorLightText.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Iconsax.lock, // Iconsax para candado
                                      color: colorLightText,
                                      size: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Iconsax.eye_slash // Iconsax para ocultar contraseña
                                            : Iconsax.eye, // Iconsax para mostrar contraseña
                                        color: colorLightText,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                    errorStyle: TextStyle(
                                      color: colorError,
                                      fontSize: 12,
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Ingresa tu contraseña'
                                      : null,
                                ),
                                if (_passwordController.text.isEmpty &&
                                    _errorMessage.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6, left: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.info_circle, // Iconsax para información
                                          color: colorError,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Ingresa tu contraseña",
                                          style: TextStyle(
                                            color: colorError,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // Olvidó su contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _showPasswordRecoveryModal,
                                icon: Icon(
                                  Iconsax.key, // Iconsax para llave/contraseña
                                  size: 14,
                                  color: colorGreen,
                                ),
                                label: Text(
                                  "¿Olvidó su contraseña?",
                                  style: TextStyle(
                                    color: colorGreen,
                                    fontSize: 13,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: colorGreen,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Botón de INGRESAR
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _login,
                              icon: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: colorWhite,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Iconsax.login, // Iconsax para login
                                      size: 18,
                                      color: colorWhite,
                                    ),
                              label: _isLoading
                                  ? const Text('')
                                  : const Text(
                                      'INGRESAR',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorGreen,
                                foregroundColor: colorWhite,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}