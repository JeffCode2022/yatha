import 'dart:convert';
import 'package:http/http.dart' as http;

class ClienteService {
  static const String _baseUrl = 'http://10.0.2.2:8090/api/clients';

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          return List<Map<String, dynamic>>.from(data['result']);
        } else if (data['error'] != null) {
          throw Exception(
            data['error']['message'] ?? 'Error al obtener clientes',
          );
        }
        return [];
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta: $e');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
