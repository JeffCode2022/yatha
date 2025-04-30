import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yatha_app/src/config/environment.dart';
import 'package:yatha_app/src/utils/logger.dart';

class ApiClient {
  static String get _baseUrl => Environment.apiUrl;
  static String get _dbName => Environment.dbName;

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final mergedHeaders = {..._defaultHeaders, ...?headers};

      Logger.debug('POST Request to: $url');
      Logger.debug('Headers: $mergedHeaders');
      Logger.debug('Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: mergedHeaders,
        body: jsonEncode(body),
      );

      Logger.debug('Response Status: ${response.statusCode}');
      Logger.debug('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']['message'] ?? 'Error desconocido');
        }
        return data;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error('Error en POST request', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> executeOdooMethod({
    required int uid,
    required String password,
    required String model,
    required String method,
    required List<dynamic> args,
  }) async {
    final body = {
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [_dbName, uid, password, model, method, ...args]
      }
    };

    return post('/jsonrpc', body: body);
  }
}
