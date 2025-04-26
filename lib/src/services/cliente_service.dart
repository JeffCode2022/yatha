import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatha_app/config/environment.dart';
import 'dart:developer' as developer;

class ClienteService {
  static const String _baseUrl = Environment.apiUrl;

  Future<Map<String, dynamic>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid');

    developer.log('Obteniendo credenciales - UID: $uid');

    if (uid == null) {
      throw Exception('No hay credenciales almacenadas');
    }

    return {
      'uid': uid,
      'password': '1234', // Contraseña fija como en Postman
    };
  }

  // Primero obtenemos los préstamos para la fecha específica
  Future<List<String>> obtenerPrestamosPorFecha(DateTime fecha) async {
    try {
      final credentials = await _getCredentials();

      developer.log(
          'Obteniendo préstamos para la fecha: ${fecha.toIso8601String()}');

      final requestBody = {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            "prestamovf",
            credentials['uid'],
            credentials['password'],
            "loan.payment",
            "search_read",
            [
              ["loan_id", "!=", false],
              ["loan_id.partner_salesperson", "=", credentials['uid']],
              ["payment_date", "=", fecha.toIso8601String().split('T')[0]],
              ["payment_status", "=", "pending"]
            ],
            [
              "id",
              "name",
              "payment_date",
              "actual_payment_date",
              "payment_status",
              "payment_amount",
              "paid_amount",
              "partner_id",
              "loan_id",
              "payment_met"
            ]
          ]
        }
      };

      developer.log('Request para préstamos: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/jsonrpc'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      developer.log('Respuesta de préstamos - Status: ${response.statusCode}');
      developer.log('Respuesta de préstamos - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final prestamos = List<Map<String, dynamic>>.from(data['result']);
          final loanIds = prestamos
              .map((prestamo) => prestamo['loan_id'][1].toString())
              .toList();
          developer.log('Préstamos encontrados: ${loanIds.length}');
          return loanIds;
        }
      }
      return [];
    } catch (e) {
      developer.log('Error en obtenerPrestamosPorFecha: $e');
      rethrow;
    }
  }

  // Luego obtenemos las coordenadas para esos préstamos
  Future<List<Map<String, dynamic>>> obtenerCoordenadas(
      List<String> prestamos) async {
    try {
      if (prestamos.isEmpty) {
        return [];
      }

      final credentials = await _getCredentials();
      developer.log('Obteniendo coordenadas para préstamos: $prestamos');

      final requestBody = {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            "prestamovf",
            credentials['uid'],
            credentials['password'],
            "loan.management",
            "search_read",
            [
              ["loan_status", "=", "pending"],
              ["partner_salesperson.id", "=", credentials['uid']],
              ["name", "in", prestamos]
            ],
            [
              "id",
              "name",
              "partner_id",
              "partner_latitude",
              "partner_longitude"
            ]
          ]
        }
      };

      developer.log('Request para coordenadas: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/jsonrpc'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      developer
          .log('Respuesta de coordenadas - Status: ${response.statusCode}');
      developer.log('Respuesta de coordenadas - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
      }
      return [];
    } catch (e) {
      developer.log('Error en obtenerCoordenadas: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerClientes({DateTime? fecha}) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      developer.log(
          'Iniciando consulta para fecha: ${fechaConsulta.toIso8601String()}');

      final prestamos = await obtenerPrestamosPorFecha(fechaConsulta);
      if (prestamos.isEmpty) {
        developer.log('No se encontraron préstamos para la fecha');
        return [];
      }

      final coordenadas = await obtenerCoordenadas(prestamos);
      developer.log('Coordenadas obtenidas: ${coordenadas.length}');
      return coordenadas;
    } catch (e) {
      developer.log('Error en obtenerClientes: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPrestamos(
      String uid, String date) async {
    try {
      final credentials = await _getCredentials();
      developer.log('Obteniendo préstamos para fecha: $date');

      final response = await http.post(
        Uri.parse('$_baseUrl/jsonrpc'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'service': 'object',
            'method': 'execute',
            'args': [
              'prestamovf',
              credentials['uid'],
              credentials['password'],
              'loan.management',
              'search_read',
              [
                ['partner_salesperson', '=', int.parse(uid)],
                ['loan_status', '=', 'pending']
              ],
              [
                'id',
                'name',
                'partner_id',
                'loan_amount',
                'payment_period',
                'payment_parts',
                'amount_due_today',
                'partner_latitude',
                'partner_longitude',
                'loan_status',
                'total_amount',
                'current_due'
              ]
            ]
          }
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final loans = List<Map<String, dynamic>>.from(data['result'])
              .map((loan) {
                try {
                  // Asegurarse de que todos los campos necesarios estén presentes y obtener el teléfono y dirección del partner_id
                  final partnerInfo = loan['partner_id'] ?? [0, 'Sin nombre'];
                  return {
                    'id': loan['id'] ?? 0,
                    'name': loan['name'] ?? '',
                    'partner_id': partnerInfo,
                    'loan_amount': loan['loan_amount'] ?? 0.0,
                    'payment_period': loan['payment_period'] ?? 'monthly',
                    'payment_parts': loan['payment_parts'] ?? 0,
                    'amount_due_today':
                        loan['amount_due_today'] ?? loan['current_due'] ?? 0.0,
                    'partner_latitude': loan['partner_latitude'] ?? 0.0,
                    'partner_longitude': loan['partner_longitude'] ?? 0.0,
                    'loan_status': loan['loan_status'] ?? 'pending',
                    'total_amount': loan['total_amount'] ?? 0.0
                  };
                } catch (e) {
                  developer.log('Error procesando préstamo: $e');
                  return null;
                }
              })
              .where((loan) => loan != null)
              .cast<Map<String, dynamic>>()
              .toList();

          developer.log('Préstamos procesados: ${loans.length}');
          return loans;
        }
        throw Exception('No se encontraron préstamos');
      } else {
        throw Exception('Error al obtener préstamos: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error en obtenerPrestamos: $e');
      rethrow;
    }
  }
}
