import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ClienteService {
  static const String _baseUrl = 'https://cda7-38-25-28-10.ngrok-free.app';

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
                ['loan_status', '=', 'pending'],
                ['partner_salesperson.id', '=', credentials['uid']]
              ],
              [
                'id',
                'partner_id',
                'partner_salesperson',
                'payment_parts',
                'days_overdue',
                'create_uid',
                'write_uid',
                'name',
                'prestamo_anterior',
                'payment_period',
                'loan_status',
                'payment_frequency',
                'start_date',
                'first_payment_date',
                'due_date',
                'partner_latitude',
                'partner_longitude',
                'create_date',
                'write_date',
                'total_interest_paid',
                'loan_amount',
                'interest_rate',
                'real_interest_rate',
                'total_amount',
                'profit',
                'current_due',
                'payment_amount',
                'amount_due_today',
                'total_cash_payments',
                'total_transfer_payments'
              ]
            ]
          }
        }),
      );

      developer.log('Respuesta de préstamos - Status: ${response.statusCode}');
      developer.log('Respuesta de préstamos - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          return List<Map<String, dynamic>>.from(data['result']);
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
