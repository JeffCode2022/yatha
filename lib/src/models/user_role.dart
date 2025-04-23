import 'package:flutter/material.dart';

enum UserRole {
  gestor,
  supervisor,
  admin
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.gestor:
        return 'Gestor';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Administrador';
    }
  }
  
  IconData get icon {
    switch (this) {
      case UserRole.gestor:
        return Icons.person;
      case UserRole.supervisor:
        return Icons.supervisor_account;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
}
