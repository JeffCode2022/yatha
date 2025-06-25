import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatha_app/src/models/user.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSupervisor => _user?.role == 'supervisor';
  bool get isGestor => _user?.role == 'gestor';

  AuthProvider() {
    _loadSavedAuth();
  }

  // Método para inicializar la autenticación
  Future<void> initializeAuth() async {
    await _loadSavedAuth();
  }

  // Cargar datos de autenticación guardados
  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getInt('uid');
      final savedRole = prefs.getString('role');
      final savedName = prefs.getString('name');
      final savedEmail = prefs.getString('username');
      final savedPartnerId = prefs.getString('partner_id');

      print('AuthProvider - Cargando datos guardados:');
      print('AuthProvider - UID: $savedUid');
      print('AuthProvider - Rol: $savedRole');
      print('AuthProvider - Nombre: $savedName');
      print('AuthProvider - Email: $savedEmail');
      print('AuthProvider - Partner ID: $savedPartnerId');

      if (savedUid != null && savedRole != null) {
        List<dynamic>? partnerId;
        if (savedPartnerId != null) {
          try {
            partnerId = json.decode(savedPartnerId) as List<dynamic>;
          } catch (e) {
            print('Error decodificando partner_id: $e');
          }
        }

        _user = User(
          uid: savedUid,
          name: savedName ?? '',
          email: savedEmail ?? '',
          role: savedRole,
          partnerId: partnerId,
        );
        _isAuthenticated = true;
        print('AuthProvider - Usuario autenticado: ${_user?.toJson()}');
        notifyListeners();
      } else {
        print('AuthProvider - No hay datos de autenticación guardados');
        _isAuthenticated = false;
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider - Error al cargar datos guardados: $e');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  // Función para autenticar al usuario
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('AuthProvider - Iniciando login para usuario: $username');
      final response = await ApiService().login(username, password);
      print('AuthProvider - Respuesta del login: $response');

      if (response.containsKey('error')) {
        _isAuthenticated = false;
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!response.containsKey('uid') || response['uid'] == null) {
        _errorMessage = 'No se recibió el ID de usuario';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Convertir el uid a entero de forma segura
      int? userId;
      try {
        if (response['uid'] is int) {
          userId = response['uid'];
        } else {
          userId = int.tryParse(response['uid'].toString());
        }

        if (userId == null) {
          throw Exception('ID de usuario inválido');
        }
      } catch (e) {
        print('AuthProvider - Error al procesar uid: $e');
        _errorMessage = 'Error al procesar el ID de usuario: $e';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Crear objeto User con los datos recibidos
      _user = User(
        uid: userId,
        name: response['name'] ?? '',
        email: response['email'] ?? username,
        role: response['role'] ?? 'gestor',
        partnerId: response['partner_id'] as List<dynamic>?,
      );

      _isAuthenticated = true;
      _errorMessage = null;

      // Guardar datos en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', userId);
      await prefs.setString('role', _user!.role);
      await prefs.setString('username', username);
      await prefs.setString('name', response['name'] ?? '');
      await prefs.setString('password', '1234');
      if (response['partner_id'] != null) {
        await prefs.setString(
            'partner_id', json.encode(response['partner_id']));
      }

      print('AuthProvider - Login exitoso');
      print('AuthProvider - Usuario: ${_user?.toJson()}');
      print('AuthProvider - Datos guardados en SharedPreferences');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider - Error en login: $e');
      _errorMessage = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Función para cerrar sesión
  Future<void> logout() async {
    try {
      print('AuthProvider - Iniciando logout');

      // Eliminar datos guardados
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Limpia todas las preferencias

      // Reiniciar estado del AuthProvider
      _user = null;
      _errorMessage = null;
      _isAuthenticated = false;

      notifyListeners();
    } catch (e) {
      print('AuthProvider - Error durante el logout: $e');
    }
  }

  // Función para verificar si la sesión sigue siendo válida
  Future<bool> isSessionValid() async {
    if (!_isAuthenticated || _user == null) {
      return false;
    }

    try {
      // Verificar si tenemos credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      return username != null && password != null;
    } catch (e) {
      print('AuthProvider - Error verificando sesión: $e');
      return false;
    }
  }

  // Función para renovar la sesión automáticamente
  Future<bool> refreshSession() async {
    if (!_isAuthenticated || _user == null) {
      return false;
    }

    try {
      print('AuthProvider - Intentando renovar sesión');

      // Obtener credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      if (username == null || password == null) {
        print(
            'AuthProvider - No hay credenciales guardadas para renovar sesión');
        return false;
      }

      // Intentar hacer login nuevamente
      final success = await login(username, password);
      if (success) {
        print('AuthProvider - Sesión renovada exitosamente');
        return true;
      } else {
        print('AuthProvider - No se pudo renovar la sesión');
        return false;
      }
    } catch (e) {
      print('AuthProvider - Error renovando sesión: $e');
      return false;
    }
  }
}
