import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://cda7-38-25-28-10.ngrok-free.app';

  // Función para obtener el token guardado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token recuperado: $token'); // Debug
    return token;
  }

  // Función para autenticar al usuario
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/roles/auth');

    final headers = {'Content-Type': 'application/json'};

    // Estructura exacta como en Postman
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {"db": "prestamovf", "login": username, "password": password},
    });

    try {
      print('URL: $url'); // Debug
      print('Headers: $headers'); // Debug
      print('Body: $body'); // Debug

      final response = await http.post(url, headers: headers, body: body);
      print('Status code: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Si hay error en la respuesta
        if (data['error'] != null) {
          return {
            'error': data['error']['message'] ?? 'Error de autenticación',
          };
        }

        // Si hay resultado exitoso
        if (data['result'] != null) {
          final result = data['result'];
          return {
            'success': true,
            'uid': result['uid'],
            'role': result['role'],
            'token': result['token'],
            'name': username.split('@')[0],
            'email': username,
          };
        }

        return {'error': 'Respuesta inválida del servidor'};
      } else {
        return {
          'error': 'Error en la conexión, código: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error en login: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener los préstamos asignados a un gestor
  Future<Map<String, dynamic>> getAssignedLoans(
    int uid,
    String paymentPeriod,
  ) async {
    final token = await _getToken();
    if (token == null) {
      return {'error': 'No hay token de autenticación'};
    }

    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Estructura exacta como en Postman
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "1234", // Password fijo como en Postman
          "loan.management",
          "search_read",
          [
            ["payment_period", "=", paymentPeriod],
            ["loan_status", "=", "pending"],
            ["partner_salesperson.id", "=", uid],
          ],
          [
            "id",
            "partner_id",
            "partner_salesperson",
            "payment_parts",
            "days_overdue",
            "create_uid",
            "write_uid",
            "name",
            "prestamo_anterior",
            "payment_period",
            "loan_status",
            "payment_frequency",
            "start_date",
            "first_payment_date",
            "due_date",
            "partner_latitude",
            "partner_longitude",
            "create_date",
            "write_date",
            "total_interest_paid",
            "loan_amount",
            "interest_rate",
            "real_interest_rate",
            "total_amount",
            "profit",
            "current_due",
            "payment_amount",
            "amount_due_today",
            "total_cash_payments",
            "total_transfer_payments",
          ],
        ],
      },
    });

    try {
      print('URL: $url'); // Debug
      print('Headers: $headers'); // Debug
      print('Body: $body'); // Debug

      final response = await http.post(url, headers: headers, body: body);
      print('Status code: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          return {
            'error': data['error']['message'] ?? 'Error al obtener préstamos',
          };
        }

        return data;
      } else {
        return {
          'error': 'Error en la conexión, código: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error al obtener préstamos: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para buscar préstamos por nombre de cliente
  Future<Map<String, dynamic>> searchLoansByClientName(
    int uid,
    String clientName,
  ) async {
    final token = await _getToken();
    if (token == null) {
      return {'error': 'No hay token de autenticación'};
    }

    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "admin",
          "loan.management",
          "search_read",
          [
            ["partner_salesperson.id", "=", uid],
            ["partner_id.name", "ilike", clientName],
          ],
          [
            "id",
            "partner_id",
            "name",
            "loan_amount",
            "payment_parts",
            "payment_period",
            "amount_due_today",
            "partner_latitude",
            "partner_longitude",
            "loan_status",
          ],
        ],
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'error': 'Error en la conexión, código: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener el detalle de las cuotas de un préstamo
  Future<Map<String, dynamic>> getLoanPayments(int uid, String loanId) async {
    final token = await _getToken();
    if (token == null) {
      return {'error': 'No hay token de autenticación'};
    }

    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Estructura exacta como en Postman
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "1234", // Password fijo como en Postman
          "loan.payment",
          "search_read",
          [
            ["loan_id", "=", loanId],
          ],
          [
            "id",
            "loan_id",
            "partner_id",
            "partner_salesperson",
            "create_uid",
            "write_uid",
            "partner_address",
            "name",
            "payment_status",
            "payment_met",
            "date_status",
            "payment_period",
            "payment_date",
            "actual_payment_date",
            "observations",
            "create_date",
            "write_date",
            "loan_amount",
            "total_amount",
            "paid_amount_total",
            "current_due",
            "payment_amount",
            "paid_amount",
            "loan_profit",
            "loan_capital",
            "interest_paid",
            "capital_paid",
            "monthly_total_due",
          ],
        ],
      },
    });

    try {
      print('URL: $url'); // Debug
      print('Headers: $headers'); // Debug
      print('Body: $body'); // Debug

      final response = await http.post(url, headers: headers, body: body);
      print('Status code: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          return {
            'error': data['error']['message'] ?? 'Error al obtener pagos',
          };
        }
        return data;
      } else {
        return {
          'error': 'Error en la conexión, código: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error al obtener pagos: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para registrar un pago
  Future<Map<String, dynamic>> registerPayment(
    int uid,
    int paymentId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'error': 'No hay token de autenticación'};
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Determinar el endpoint y estructura según el tipo de pago
      final bool isMonthly = paymentData.containsKey('interest_paid');
      final endpoint =
          isMonthly
              ? '$baseUrl/api/payment/monthly/update'
              : '$baseUrl/api/payment/daily/update';

      // Estructura exacta como en Postman
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params":
            isMonthly
                ? {
                  "id": paymentId,
                  "payment_met": paymentData['payment_met'],
                  "interest_paid": paymentData['interest_paid'],
                  "capital_paid": paymentData['capital_paid'],
                }
                : {
                  "id": paymentId,
                  "paid_amount": paymentData['paid_amount'],
                  "payment_met": paymentData['payment_met'],
                },
      });

      print('URL: $endpoint'); // Debug
      print('Headers: $headers'); // Debug
      print('Body: $body'); // Debug

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      print('Status code: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          return {
            'error': data['error']['message'] ?? 'Error al registrar pago',
          };
        }
        return data;
      } else {
        return {'error': 'Error de conexión: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error al registrar pago: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener indicadores KPI del día
  Future<Map<String, dynamic>> getDailyKPIs(int uid, String date) async {
    final token = await _getToken();
    if (token == null) {
      return {'error': 'No hay token de autenticación'};
    }

    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Primero obtenemos los pagos a tiempo
    final onTimeBody = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "admin",
          "loan.payment",
          "search_read",
          [
            ["payment_date", "=", date],
            ["payment_status", "=", "on_time"],
            ["partner_salesperson.id", "=", uid],
          ],
          ["id", "payment_amount", "paid_amount"],
        ],
      },
    });

    // Luego obtenemos los pagos atrasados
    final lateBody = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "admin",
          "loan.payment",
          "search_read",
          [
            ["payment_date", "=", date],
            ["payment_status", "=", "late"],
            ["partner_salesperson.id", "=", uid],
          ],
          ["id", "payment_amount", "paid_amount"],
        ],
      },
    });

    // También obtenemos el total de pagos planificados para el día
    final totalBody = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "admin",
          "loan.payment",
          "search_read",
          [
            ["payment_date", "=", date],
            ["partner_salesperson.id", "=", uid],
          ],
          ["id", "payment_amount"],
        ],
      },
    });

    try {
      // Ejecutamos todas las peticiones
      final onTimeResponse = await http.post(
        url,
        headers: headers,
        body: onTimeBody,
      );
      final lateResponse = await http.post(
        url,
        headers: headers,
        body: lateBody,
      );
      final totalResponse = await http.post(
        url,
        headers: headers,
        body: totalBody,
      );

      if (onTimeResponse.statusCode == 200 &&
          lateResponse.statusCode == 200 &&
          totalResponse.statusCode == 200) {
        final onTimeData = jsonDecode(onTimeResponse.body);
        final lateData = jsonDecode(lateResponse.body);
        final totalData = jsonDecode(totalResponse.body);

        return {
          'onTime': onTimeData['result'] ?? [],
          'late': lateData['result'] ?? [],
          'total': totalData['result'] ?? [],
        };
      } else {
        return {
          'error': 'Error en la conexión, código: ${onTimeResponse.statusCode}',
        };
      }
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }
}
