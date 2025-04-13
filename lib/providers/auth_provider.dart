import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

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

  // Cargar datos de autenticación guardados
  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getInt('uid');
      final savedRole = prefs.getString('role');
      final savedName = prefs.getString('username');
      final savedEmail = prefs.getString('username');

      print('AuthProvider - Cargando datos guardados:');
      print('AuthProvider - UID: $savedUid');
      print('AuthProvider - Rol: $savedRole');
      print('AuthProvider - Nombre: $savedName');
      print('AuthProvider - Email: $savedEmail');

      if (savedUid != null && savedRole != null) {
        _user = User(
          uid: savedUid,
          name: savedName ?? '',
          email: savedEmail ?? '',
          role: savedRole,
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
        name: response['name'] ?? username.split('@')[0],
        email: response['email'] ?? username,
        role: response['role'] ?? 'gestor',
      );

      _isAuthenticated = true;
      _errorMessage = null;

      // Guardar datos en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', userId);
      await prefs.setString('role', _user!.role);
      await prefs.setString('username', username);
      await prefs.setString(
          'password', '1234'); // Contraseña fija como en Postman

      print('AuthProvider - Login exitoso');
      print('AuthProvider - Usuario: ${_user?.toJson()}');
      print('AuthProvider - Datos guardados en SharedPreferences');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider - Error en el proceso de login: $e');
      _isAuthenticated = false;
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
      await prefs.remove('uid');
      await prefs.remove('role');
      await prefs.remove('username');
      await prefs.remove('password');

      print('AuthProvider - Datos eliminados de SharedPreferences');

      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('AuthProvider - Error durante el logout: $e');
    }
  }
}
