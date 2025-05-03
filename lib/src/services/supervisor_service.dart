import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/src/config/environment.dart';
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/logger.dart';

class SupervisorService extends BaseService {
  String get _baseUrl => Environment.apiUrl;

  Future<List<Map<String, dynamic>>> getGestores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print('Fetching gestores with uid: $uid, database: $database');

      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "res.users",
            "search_read",
            [
              ["active", "=", true],
              ["x_role", "=", "gestor"]
            ],
            ["id", "partner_id", "x_role"]
          ]
        }
      });

      print('Response: $response');

      if (response['result'] != null) {
        final List<dynamic> result = response['result'];
        return result
            .map((gestor) => {
                  'id': gestor['id'].toString(),
                  'name': gestor['partner_id'] != null
                      ? gestor['partner_id'][1] ?? 'Sin nombre'
                      : 'Sin nombre',
                  'role': gestor['x_role'] ?? 'gestor'
                })
            .toList();
      }
      throw Exception('No se encontraron gestores');
    } catch (e) {
      print('Error en getGestores: $e');
      throw Exception('Error al obtener gestores: $e');
    }
  }

  Future<Map<String, dynamic>> getGestorKPIs(
      String gestorId, DateTime startDate, DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching KPIs for gestor: $gestorId, start date: ${DateFormat('yyyy-MM-dd').format(startDate)}, end date: ${DateFormat('yyyy-MM-dd').format(endDate)}');

      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "loan.payment",
            "search_read",
            [
              ["loan_id", "!=", false],
              ["loan_id.partner_salesperson", "=", int.parse(gestorId)],
              [
                "payment_date",
                ">=",
                DateFormat('yyyy-MM-dd').format(startDate)
              ],
              ["payment_date", "<=", DateFormat('yyyy-MM-dd').format(endDate)]
            ],
            [
              "id",
              "name",
              "payment_date",
              "actual_payment_date",
              "payment_status",
              "payment_amount",
              "paid_amount",
              "paid_amount_cash",
              "paid_amount_transferencia",
              "partner_id",
              "loan_id",
              "payment_met"
            ]
          ]
        }
      });

      print('KPI Response: $response');

      if (response['result'] == null) {
        return {
          'pending_count': 0,
          'completed_count': 0,
          'total_amount': 0.0,
          'collected_amount': 0.0,
          'efficiency': 0.0,
          'payments': []
        };
      }

      // Procesar los pagos y calcular métricas
      final List<dynamic> payments = response['result'];
      int pendingCount = 0;
      int completedCount = 0;
      int lateCount = 0;
      double totalAmount = 0.0;
      double collectedAmount = 0.0;

      for (var payment in payments) {
        final status = payment['payment_status']?.toString() ?? 'pending';
        final expectedAmount = (payment['payment_amount'] ?? 0.0).toDouble();
        double paidAmount = 0.0;

        // Calcular el monto pagado considerando pagos mixtos
        if (payment['payment_met'] == 'mixto') {
          double cashAmount = (payment['paid_amount_cash'] ?? 0.0).toDouble();
          double transferAmount =
              (payment['paid_amount_transferencia'] ?? 0.0).toDouble();
          paidAmount = cashAmount + transferAmount;

          // Validar que la suma de los pagos mixtos no exceda significativamente el monto esperado
          if (paidAmount > expectedAmount * 1.5) {
            // 50% de tolerancia
            Logger.warning(
                'Pago mixto excede significativamente el monto esperado: $paidAmount > $expectedAmount');
          }
        } else {
          paidAmount = (payment['paid_amount'] ?? 0.0).toDouble();
        }

        final timeStatus = _calculatePaymentTimeStatus(
            payment['payment_date']?.toString() ?? '',
            payment['actual_payment_date']?.toString(),
            status);

        if (status == 'pending') {
          pendingCount++;
          if (timeStatus == 'late') {
            lateCount++;
          }
        } else if (status == 'paid' ||
            status == 'partial' ||
            status == 'overpaid') {
          if (status == 'paid' || status == 'overpaid' || status == 'partial') {
            completedCount++;
          }
          collectedAmount += paidAmount;
        }

        totalAmount += expectedAmount;
      }

      // Calcular eficiencia de desembolso
      double efficiency =
          payments.isEmpty ? 0.0 : completedCount / payments.length;

      return {
        'pending_count': pendingCount,
        'completed_count': completedCount,
        'late_count': lateCount,
        'total_amount': totalAmount,
        'collected_amount': collectedAmount,
        'efficiency': efficiency,
        'payments': payments
      };
    } catch (e) {
      print('Error en getGestorKPIs: $e');
      throw Exception('Error al obtener los KPIs del gestor: $e');
    }
  }

  String _calculatePaymentTimeStatus(
      String paymentDate, String? actualPaymentDate, String status) {
    if (status == 'pending') return 'pending';

    try {
      final expectedDate = DateTime.parse(paymentDate);
      if (actualPaymentDate == null) return 'pending';

      final actualDate = DateTime.parse(actualPaymentDate);

      if (actualDate.isAfter(expectedDate)) {
        return 'late';
      } else if (actualDate.isAtSameMomentAs(expectedDate) ||
          actualDate.isBefore(expectedDate)) {
        return 'ontime';
      }
    } catch (e) {
      print('Error al calcular estado por tiempo: $e');
    }

    return 'pending';
  }

  Future<List<Map<String, dynamic>>> getGestorClientLocations(
      String gestorId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching client locations for gestor: $gestorId, date: ${DateFormat('yyyy-MM-dd').format(date)}');

      // Primero obtenemos los préstamos pendientes
      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "loan.management",
            "search_read",
            [
              ["loan_status", "=", "pending"],
              ["partner_salesperson.id", "=", int.parse(gestorId)],
              ["partner_latitude", "!=", false],
              ["partner_longitude", "!=", false]
            ],
            [
              "id",
              "name",
              "partner_id",
              "partner_latitude",
              "partner_longitude",
              "payment_amount",
              "loan_status",
              "partner_salesperson"
            ]
          ]
        }
      });

      print('Location Response: $response');

      if (response['result'] == null) {
        print('No se encontraron ubicaciones para el gestor');
        return [];
      }

      final List<dynamic> loans = response['result'];
      print('Encontrados ${loans.length} préstamos con ubicación');

      final List<Map<String, dynamic>> locations = [];

      for (var loan in loans) {
        print('Procesando préstamo: ${loan['id']}');
        print('Datos del préstamo:');
        print('- Latitud: ${loan['partner_latitude']}');
        print('- Longitud: ${loan['partner_longitude']}');
        print('- Cliente: ${loan['partner_id']}');
        print('- Monto: ${loan['payment_amount']}');
        print('- Estado: ${loan['loan_status']}');
        print('- Gestor: ${loan['partner_salesperson']}');

        // Verificar que las coordenadas sean válidas
        if (loan['partner_latitude'] == null ||
            loan['partner_longitude'] == null) {
          print('Coordenadas inválidas para el préstamo ${loan['id']}');
          continue;
        }

        locations.add({
          'latitude': loan['partner_latitude'],
          'longitude': loan['partner_longitude'],
          'client_name':
              loan['partner_id'] != null ? loan['partner_id'][1] : 'Sin nombre',
          'amount': loan['payment_amount'] as double? ?? 0.0,
          'status': loan['loan_status'] as String? ?? 'pending',
          'gestor_name': loan['partner_salesperson'] != null
              ? loan['partner_salesperson'][1]
              : 'Sin gestor',
          'gestor_id': loan['partner_salesperson'] != null
              ? loan['partner_salesperson'][0].toString()
              : '0',
        });
      }

      print('Ubicaciones procesadas: ${locations.length}');
      return locations;
    } catch (e) {
      print('Error en getGestorClientLocations: $e');
      throw Exception('Error al obtener las ubicaciones de los clientes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllGestorsClientLocations(
      DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching all client locations for date: ${DateFormat('yyyy-MM-dd').format(date)}');

      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "loan.management",
            "search_read",
            [
              ["loan_status", "=", "pending"],
              ["name", "!=", false]
            ],
            [
              "id",
              "name",
              "partner_id",
              "partner_latitude",
              "partner_longitude",
              "payment_amount",
              "loan_status",
              "partner_salesperson"
            ]
          ]
        }
      });

      print('Location Response: $response');

      if (response['result'] == null) {
        return [];
      }

      final List<dynamic> loans = response['result'];
      return loans.where((loan) {
        final lat = loan['partner_latitude'];
        final lng = loan['partner_longitude'];
        return lat != null && lng != null;
      }).map((loan) {
        return {
          'latitude': loan['partner_latitude'] as double,
          'longitude': loan['partner_longitude'] as double,
          'client_name':
              loan['partner_id'] != null ? loan['partner_id'][1] : 'Sin nombre',
          'amount': loan['payment_amount'] as double? ?? 0.0,
          'status': loan['loan_status'] as String? ?? 'pending',
          'gestor_name': loan['partner_salesperson'] != null
              ? loan['partner_salesperson'][1]
              : 'Sin gestor',
          'gestor_id': loan['partner_salesperson'] != null
              ? loan['partner_salesperson'][0].toString()
              : '0',
        };
      }).toList();
    } catch (e) {
      print('Error en getAllGestorsClientLocations: $e');
      throw Exception('Error al obtener las ubicaciones de los clientes: $e');
    }
  }

  Future<Map<String, dynamic>> getDailyLoans(
    DateTime startDate,
    DateTime endDate,
    String gestorId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "loan.management",
            "search_read",
            [
              ["partner_salesperson", "=", int.parse(gestorId)],
              ["loan_status", "!=", "cancelled"],
              ["create_date", ">=", DateFormat('yyyy-MM-dd').format(startDate)],
              ["create_date", "<=", DateFormat('yyyy-MM-dd').format(endDate)]
            ],
            [
              "id",
              "name",
              "loan_amount",
              "profit",
              "total_amount",
              "loan_status",
              "partner_id",
              "partner_salesperson",
              "create_date"
            ]
          ]
        }
      });

      return response;
    } catch (e) {
      print('Error en getDailyLoans: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMapLocations(
      String gestorId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching map locations for gestor: $gestorId, date: ${DateFormat('yyyy-MM-dd').format(date)}');

      final response = await post('/jsonrpc', body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute",
          "args": [
            database,
            uid,
            password,
            "loan.payment",
            "search_read",
            [
              ["loan_id", "!=", false],
              ["loan_id.partner_salesperson", "=", int.parse(gestorId)],
              ["payment_date", "=", DateFormat('yyyy-MM-dd').format(date)],
              ["payment_status", "=", "pending"],
              ["loan_id.partner_latitude", "!=", false],
              ["loan_id.partner_longitude", "!=", false]
            ],
            [
              "id",
              "loan_id",
              "payment_amount",
              "payment_status",
              "loan_id/partner_latitude",
              "loan_id/partner_longitude",
              "loan_id/partner_id",
              "loan_id/partner_salesperson"
            ]
          ]
        }
      });

      print('Map Location Response: $response');

      if (response['result'] == null) {
        print('No se encontraron ubicaciones para el gestor en el mapa');
        return [];
      }

      final List<dynamic> payments = response['result'];
      print('Encontrados ${payments.length} pagos con ubicación');

      final List<Map<String, dynamic>> locations = [];

      for (var payment in payments) {
        print('Procesando pago: ${payment['id']}');

        final lat = payment['loan_id/partner_latitude'];
        final lng = payment['loan_id/partner_longitude'];

        if (lat == null || lng == null) {
          print('Coordenadas inválidas para el pago ${payment['id']}');
          continue;
        }

        locations.add({
          'latitude': double.tryParse(lat.toString()) ?? 0.0,
          'longitude': double.tryParse(lng.toString()) ?? 0.0,
          'client_name': payment['loan_id/partner_id'] != null
              ? payment['loan_id/partner_id'][1]
              : 'Sin nombre',
          'amount': payment['payment_amount'] as double? ?? 0.0,
          'status': payment['payment_status'] as String? ?? 'pending',
          'gestor_name': payment['loan_id/partner_salesperson'] != null
              ? payment['loan_id/partner_salesperson'][1]
              : 'Sin gestor',
          'gestor_id': payment['loan_id/partner_salesperson'] != null
              ? payment['loan_id/partner_salesperson'][0].toString()
              : '0',
        });
      }

      print('Ubicaciones del mapa procesadas: ${locations.length}');
      return locations;
    } catch (e) {
      print('Error en getMapLocations: $e');
      throw Exception('Error al obtener las ubicaciones para el mapa: $e');
    }
  }
}
