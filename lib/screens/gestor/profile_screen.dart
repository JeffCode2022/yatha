import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/providers/auth_provider.dart';
import 'package:yatha_app/theme/app_theme.dart';
import 'package:yatha_app/widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Avatar y nombre
              const CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Gestor de Préstamos',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Tarjeta de información básica
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Usuario',
                      value: 'admin',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.badge,
                      label: 'ID de Usuario',
                      value: '${authProvider.user?.uid ?? 'No disponible'}',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botón de cerrar sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Cerrar Sesión'),
                            content: const Text(
                              '¿Estás seguro que deseas cerrar sesión?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  authProvider.logout();
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Cerrar Sesión'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('CERRAR SESIÓN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
