import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatha_app/src/services/api_client.dart';
import 'package:yatha_app/src/utils/logger.dart';

abstract class BaseService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid');
      final password = prefs.getString('password');

      if (uid == null || password == null) {
        Logger.warning('No hay credenciales guardadas');
        return {};
      }

      return {
        'uid': uid,
        'password': password,
      };
    } catch (e) {
      Logger.error('Error al obtener credenciales', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> executeOdooMethod({
    required String model,
    required String method,
    required List<dynamic> args,
  }) async {
    final credentials = await getCredentials();
    if (credentials.isEmpty) {
      throw Exception('No hay credenciales disponibles');
    }

    return _apiClient.executeOdooMethod(
      uid: credentials['uid'],
      password: credentials['password'],
      model: model,
      method: method,
      args: args,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    return _apiClient.post(
      endpoint,
      body: body,
      headers: headers,
    );
  }
}
