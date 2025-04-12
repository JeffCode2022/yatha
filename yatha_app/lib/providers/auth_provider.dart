import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isSupervisor => _user?.role == 'supervisor';
  bool get isGestor => _user?.role == 'gestor';

  AuthProvider() {
    _loadSavedAuth();
  }

  // Cargar datos de autenticación guardados
  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getInt('uid');
    final savedToken = prefs.getString('token');
    final savedRole = prefs.getString('role');
    final savedName = prefs.getString('name');
    final savedEmail = prefs.getString('email');

    if (savedUid != null && savedToken != null && savedRole != null) {
      _user = User(
        uid: savedUid,
        name: savedName ?? '',
        email: savedEmail ?? '',
        role: savedRole,
      );
      _token = savedToken;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Función para autenticar al usuario
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().login(username, password);
      print('Respuesta completa del login: $response'); // Debug

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
        print('Error al procesar uid: $e'); // Debug
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
        token: response['token'],
      );

      _token = response['token'];
      _isAuthenticated = true;
      _errorMessage = null;

      // Guardar datos en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', userId);
      await prefs.setString('token', _token ?? '');
      await prefs.setString('role', _user!.role);
      await prefs.setString('name', _user!.name);
      await prefs.setString('email', _user!.email);

      print('Login exitoso. Usuario: ${_user?.toJson()}'); // Debug

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error en el proceso de login: $e'); // Debug
      _isAuthenticated = false;
      _errorMessage = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Función para cerrar sesión
  Future<void> logout() async {
    _user = null;
    _token = null;
    _isAuthenticated = false;

    // Eliminar datos guardados
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('email');

    notifyListeners();
  }
}
