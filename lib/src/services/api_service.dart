import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yatha_app/src/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/logger.dart';

class ApiService extends BaseService {
  String get baseUrl => Environment.apiUrl;

  // Función para obtener las credenciales guardadas
  Future<Map<String, dynamic>> _getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid');
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      print('ApiService - Obteniendo credenciales:');
      print('ApiService - UID: $uid');
      print('ApiService - Username: $username');
      print('ApiService - Password: ${password != null ? '****' : 'null'}');

      if (uid == null || username == null || password == null) {
        print('ApiService - No hay credenciales guardadas');
        return {};
      }

      return {
        'uid': uid,
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('ApiService - Error al obtener credenciales: $e');
      return {};
    }
  }

  // Función para autenticar al usuario
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final body = {
        "jsonrpc": "2.0",
        "params": {
          "db": Environment.dbName,
          "login": username,
          "password": password
        }
      };

      final response = await post(Environment.authEndpoint, body: body);

      if (response['result'] != null) {
        final result = response['result'];

        // Determinar el rol basado en el email
        String role = 'gestor';
        if (username.toLowerCase().contains('supervisor')) {
          role = 'supervisor';
        }

        // Guardar datos de sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('uid', result['uid']);
        await prefs.setString('role', role);
        await prefs.setString('username', username);
        await prefs.setString('password', '1234');
        await prefs.setString('auth_token', result['token'] ?? '');

        return {
          'success': true,
          'uid': result['uid'],
          'role': role,
          'name': username.split('@')[0],
          'email': username,
        };
      }

      if (response['error'] != null) {
        return {
          'error': response['error']['message'] ?? 'Error de autenticación',
        };
      }

      return {'error': 'Respuesta inválida del servidor'};
    } catch (e) {
      Logger.error('Error en login', e);
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener los préstamos asignados a un gestor
  Future<Map<String, dynamic>> getAssignedLoans(
    int uid,
    String paymentPeriod,
  ) async {
    final body = {
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "1234",
          "loan.management",
          "search_read",
          [
            ["payment_period", "=", paymentPeriod],
            ["loan_status", "=", "pending"],
            ["partner_salesperson.id", "=", uid]
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
            "total_transfer_payments"
          ]
        ]
      }
    };

    try {
      final response = await post('/jsonrpc', body: body);
      if (response['error'] != null) {
        return {
          'error': response['error']['message'] ?? 'Error al obtener préstamos',
        };
      }
      if (response['result'] == null) {
        return {'result': []};
      }
      return response;
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  List<String> _getLoanFields() {
    return [
      "id",
      "partner_id",
      "name",
      "loan_amount",
      "payment_parts",
      "payment_period",
      "loan_status",
      "payment_frequency",
      "start_date",
      "first_payment_date",
      "due_date",
      "partner_latitude",
      "partner_longitude",
      "amount_due_today",
      "total_cash_payments",
      "total_transfer_payments",
      "current_due"
    ];
  }

  // Función para obtener los préstamos asignados a un gestor
  Future<Map<String, dynamic>> getAssignedLoansOld(
    int uid,
    String paymentPeriod,
  ) async {
    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {'Content-Type': 'application/json'};

    // Estructura exacta como en Postman para préstamos mensuales/diarios
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute",
        "args": [
          "prestamovf",
          uid,
          "1234",
          "loan.management",
          "search_read",
          [
            ["payment_period", "=", paymentPeriod],
            ["loan_status", "=", "pending"],
            ["partner_salesperson.id", "=", uid]
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
            "total_transfer_payments"
          ]
        ]
      }
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
          print('Error en la respuesta: ${data['error']}');
          return {
            'error': data['error']['message'] ?? 'Error al obtener préstamos',
          };
        }

        // Asegurarnos de que result sea una lista
        if (data['result'] == null) {
          print('No hay préstamos en la respuesta');
          return {'result': []};
        }

        print('Préstamos obtenidos: ${data['result'].length}');
        return data;
      } else {
        print('Error de conexión: ${response.statusCode}');
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
    try {
      final queryFilters = [
        ["partner_salesperson.id", "=", uid],
        ["partner_id.name", "ilike", clientName]
      ];

      final queryFields = [
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
        "partner_phone",
        "partner_address",
        "installments"
      ];

      final response = await executeOdooMethod(
        model: "loan.management",
        method: "search_read",
        args: [queryFilters, queryFields],
      );

      if (response['result'] != null) {
        return {
          'success': true,
          'loans': response['result'],
        };
      }

      return {
        'success': true,
        'loans': [],
      };
    } catch (e) {
      Logger.error('Error en searchLoansByClientName', e);
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener los pagos de un préstamo
  Future<Map<String, dynamic>> getLoanPayments(int uid, String loanId) async {
    try {
      final queryFilters = [
        ["loan_id", "=", loanId]
      ];

      final queryFields = [
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
        "monthly_total_due"
      ];

      final response = await executeOdooMethod(
        model: "loan.payment",
        method: "search_read",
        args: [queryFilters, queryFields],
      );

      if (response['result'] != null) {
        return response;
      }

      throw Exception('Error al obtener pagos');
    } catch (e) {
      Logger.error('Error en getLoanPayments', e);
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
      Logger.info('Registrando pago: $paymentData');

      // Asegurarse de que el JSON tenga el formato correcto según el método de pago
      final params = paymentData['params'];
      if (params['payment_met'] == 'mixto') {
        // Para pagos mixtos, asegurarse de que los montos estén presentes
        params['paid_amount_cash'] = params['paid_amount_cash'] ?? 0.0;
        params['paid_amount_transferencia'] =
            params['paid_amount_transferencia'] ?? 0.0;

        // Calcular el monto total para la verificación
        params['paid_amount'] =
            (params['paid_amount_cash'] + params['paid_amount_transferencia'])
                .toDouble();
      } else {
        // Para pagos en efectivo o transferencia
        params['paid_amount'] = params['paid_amount'] ??
            params['paid_amount_cash'] ??
            params['paid_amount_transferencia'] ??
            0.0;

        // Eliminar campos innecesarios para pagos no mixtos
        params.remove('paid_amount_cash');
        params.remove('paid_amount_transferencia');
      }

      final response =
          await post('/api/payment/daily/update', body: paymentData);

      if (response.containsKey('error')) {
        return {'error': response['error']['message'] ?? 'Error desconocido'};
      }

      // Esperar un momento para que el backend procese el pago
      await Future.delayed(const Duration(milliseconds: 500));

      // Intentar obtener el estado actualizado del pago
      final verificationResponse =
          await getLoanPayments(uid, paymentId.toString());

      if (verificationResponse.containsKey('error')) {
        return {
          'error': 'El pago se registró pero no se pudo verificar el estado'
        };
      }

      return {'success': true, 'data': response};
    } catch (e) {
      Logger.error('Error en registerPayment', e);
      return {'error': 'Error al procesar el pago: $e'};
    }
  }

  // Función para obtener indicadores KPI del día
  Future<Map<String, dynamic>> getDailyKPIs(int uid, String date) async {
    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {'Content-Type': 'application/json'};

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
            ["loan_id", "!=", false],
            ["loan_id.partner_salesperson", "=", uid],
            ["payment_date", "=", date],
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
    });

    try {
      print('ApiService - URL: $url'); // Debug
      print('ApiService - Headers: $headers'); // Debug
      print('ApiService - Body: $body'); // Debug

      final response = await http.post(url, headers: headers, body: body);
      print('ApiService - Status code: ${response.statusCode}'); // Debug
      print('ApiService - Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          print(
              'ApiService - Error en la respuesta: ${data['error']}'); // Debug
          return {'error': data['error']['message'] ?? 'Error al obtener KPIs'};
        }

        // Procesar los resultados para calcular KPIs
        final List<dynamic> payments = data['result'] ?? [];
        print(
            'ApiService - Número de pagos encontrados: ${payments.length}'); // Debug

        // Calcular totales
        double totalAmount = 0;
        double totalPaid = 0;
        double totalPending = 0;
        int onTimeCount = 0;
        int lateCount = 0;
        int pendingCount = 0;

        for (var payment in payments) {
          final double paymentAmount =
              (payment['payment_amount'] ?? 0).toDouble();
          final double paidAmount = (payment['paid_amount'] ?? 0).toDouble();
          final String status = payment['payment_status'] ?? 'pending';

          totalAmount += paymentAmount;
          totalPaid += paidAmount;

          if (status == 'on_time') {
            onTimeCount++;
          } else if (status == 'late') {
            lateCount++;
          } else {
            pendingCount++;
            totalPending += (paymentAmount - paidAmount);
          }
        }

        return {
          'onTime': onTimeCount,
          'late': lateCount,
          'pending': pendingCount,
          'totalAmount': totalAmount,
          'totalPaid': totalPaid,
          'totalPending': totalPending,
          'payments': payments,
        };
      } else {
        return {
          'error': 'Error en la conexión, código: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('ApiService - Error al obtener KPIs: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener préstamos para el mapa
  Future<Map<String, dynamic>> getMapLoans(int uid, String date) async {
    final url = Uri.parse('$baseUrl/web/dataset/call_kw');

    final headers = {'Content-Type': 'application/json'};

    // Estructura exacta como en Postman para obtener préstamos del día
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "model": "loan.payment",
        "method": "search_read",
        "args": [
          [
            ["loan_id", "!=", false],
            ["loan_id.partner_salesperson", "=", uid],
            ["payment_date", "=", date],
            ["payment_status", "=", "pending"]
          ],
          ["loan_id", "payment_date"]
        ],
        "kwargs": {}
      }
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
            'error': data['error']['message'] ??
                'Error al obtener préstamos para el mapa',
          };
        }
        return data;
      } else {
        return {'error': 'Error de conexión: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error al obtener préstamos para el mapa: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Función para obtener coordenadas de préstamos
  Future<Map<String, dynamic>> getLoanCoordinates(
      int uid, String loanId) async {
    final url = Uri.parse('$baseUrl/jsonrpc');

    final headers = {'Content-Type': 'application/json'};

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
          "1234",
          "loan.management",
          "search_read",
          [
            ["loan_status", "=", "pending"],
            ["partner_salesperson.id", "=", uid],
            ["name", "=", loanId]
          ],
          ["id", "partner_latitude", "partner_longitude"]
        ]
      }
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
            'error': data['error']['message'] ?? 'Error al obtener coordenadas',
          };
        }
        return data;
      } else {
        return {'error': 'Error de conexión: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error al obtener coordenadas: $e'); // Debug
      return {'error': 'Error de conexión: $e'};
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }
}
