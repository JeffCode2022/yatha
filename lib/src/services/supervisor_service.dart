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

      if (response['result'] == null) {
        return {
          'pending_count': 0,
          'completed_count': 0,
          'total_amount': 0.0,
          'collected_amount': 0.0,
          'efficiency': 0.0,
          'payments': [],
          'loans': [],
        };
      }

      // Obtener los IDs de los préstamos
      final List<dynamic> payments = response['result'];
      final List<dynamic> loanIds = payments
          .where((payment) => payment['loan_id'] != null)
          .map((payment) => payment['loan_id'][0])
          .toList();

      // Obtener los detalles de los préstamos incluyendo due_date
      final loansResponse = await getLoansByIds(loanIds);
      final Map<int, dynamic> loansMap = {};
      if (loansResponse['result'] != null) {
        for (var loan in loansResponse['result']) {
          loansMap[loan['id']] = loan;
        }
      }

      // Combinar la información de pagos con los detalles de préstamos
      for (var payment in payments) {
        if (payment['loan_id'] != null) {
          final loanId = payment['loan_id'][0];
          final loanDetails = loansMap[loanId];
          if (loanDetails != null) {
            payment['due_date'] = loanDetails['due_date'];
          }
        }
      }

      // Procesar los pagos y calcular métricas
      int pendingCount = 0;
      int completedCount = 0;
      int lateCount = 0;
      double totalDue = 0.0; // meta
      double totalCollected = 0.0; // recaudado
      List<dynamic> filteredPayments = [];

      for (var payment in payments) {
        // Filtrar préstamos renovados, refinanciados o cancelados
        String loanStatus = '';
        if (payment['loan_id'] != null &&
            payment['loan_id'] is List &&
            payment['loan_id'].length > 2) {
          loanStatus = payment['loan_id'][2]?.toString() ?? '';
        } else if (payment['loan_status'] != null) {
          loanStatus = payment['loan_status'].toString();
        }
        if (loanStatus == 'refinanced' ||
            loanStatus == 'renewed' ||
            loanStatus == 'cancelled') {
          continue;
        }
        filteredPayments.add(payment);
        final status = payment['payment_status']?.toString() ?? 'pending';
        final expectedAmount = (payment['payment_amount'] ?? 0.0).toDouble();
        double paidAmount = 0.0;
        if (payment['payment_met'] == 'mixto') {
          double cashAmount = (payment['paid_amount_cash'] ?? 0.0).toDouble();
          double transferAmount =
              (payment['paid_amount_transferencia'] ?? 0.0).toDouble();
          paidAmount = cashAmount + transferAmount;
        } else {
          paidAmount = (payment['paid_amount'] ?? 0.0).toDouble();
        }
        if (status == 'pending') {
          // Verificar que tenga saldo pendiente > 0 (igual que cliente_service.dart)
          final saldoPendiente = expectedAmount - paidAmount;
          if (saldoPendiente > 0.0) {
            pendingCount++;
            final timeStatus = _calculatePaymentTimeStatus(
                payment['payment_date']?.toString() ?? '',
                payment['actual_payment_date']?.toString(),
                status);
            if (timeStatus == 'late') {
              lateCount++;
            }
          }
        } else if (status == 'paid' ||
            status == 'partial' ||
            status == 'overpaid') {
          completedCount++;
          totalCollected += paidAmount;
        }
        totalDue += expectedAmount;
      }
      // Calcular eficiencia igual que gestor
      double efficiency = totalDue > 0 ? (totalCollected / totalDue) : 0.0;
      return {
        'pending_count': pendingCount,
        'completed_count': completedCount,
        'late_count': lateCount,
        'total_amount': totalDue,
        'collected_amount': totalCollected,
        'efficiency': efficiency,
        'payments': filteredPayments,
        'loans': loansResponse['result'] ?? [],
      };
    } catch (e) {
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
      // print('Error al calcular estado por tiempo: $e');
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

      if (response['result'] == null) {
        return [];
      }

      final List<dynamic> loans = response['result'];

      final List<Map<String, dynamic>> locations = [];

      for (var loan in loans) {
        final lat = loan['partner_latitude'];
        final lng = loan['partner_longitude'];

        if (lat == null || lng == null) {
          continue;
        }

        locations.add({
          'latitude': lat,
          'longitude': lng,
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

      return locations;
    } catch (e) {
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

      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

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
              ["create_date", ">=", formattedStartDate],
              ["create_date", "<=", formattedEndDate],
              ["partner_salesperson.id", "=", int.parse(gestorId)],
              ["loan_status", "=", "pending"]
            ],
            [
              "id",
              "name",
              "partner_id",
              "loan_amount",
              "profit",
              "total_amount",
              "current_due",
              "create_date",
              "partner_salesperson"
            ]
          ]
        }
      });

      return response;
    } catch (e) {
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

      if (response['result'] == null) {
        return [];
      }

      final List<dynamic> payments = response['result'];

      final List<Map<String, dynamic>> locations = [];

      for (var payment in payments) {
        final lat = payment['loan_id/partner_latitude'];
        final lng = payment['loan_id/partner_longitude'];

        if (lat == null || lng == null) {
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

      return locations;
    } catch (e) {
      throw Exception('Error al obtener las ubicaciones para el mapa: $e');
    }
  }

  // Método para obtener préstamos por sus IDs
  Future<Map<String, dynamic>> getLoansByIds(List<dynamic> loanIds) async {
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
              ["id", "in", loanIds]
            ],
            [
              "id",
              "name",
              "partner_id",
              "loan_amount",
              "profit",
              "total_amount",
              "current_due",
              "create_date",
              "partner_salesperson",
              "due_date",
              "payment_period",
              "loan_status",
              "partner_latitude",
              "partner_longitude",
              "partner_address"
            ]
          ]
        }
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene los pagos pendientes de un gestor para una fecha específica, replicando la lógica del gestor
  Future<List<Map<String, dynamic>>> getGestorPendingPayments(
      String gestorId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '1234';
      final database = prefs.getString('database') ?? 'prestamovf';
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // 1. Obtener todos los pagos del gestor para la fecha
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
              ["payment_date", "=", formattedDate]
            ],
            [
              "id",
              "name",
              "payment_date",
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

      final pagos = List<Map<String, dynamic>>.from(response['result'] ?? []);

      // 2. Filtrar pagos pendientes (pending o late), saldo pendiente > 0, sin duplicados por loan_id
      final Set<dynamic> processedLoans = {};
      final pagosPendientes = pagos.where((pago) {
        final status = (pago['payment_status'] ?? '').toLowerCase();
        final paymentAmount = (pago['payment_amount'] ?? 0.0) is num
            ? (pago['payment_amount'] ?? 0.0).toDouble()
            : double.tryParse(pago['payment_amount']?.toString() ?? '0') ?? 0.0;
        double paidAmount = 0.0;
        if (pago['payment_met'] == 'mixto') {
          paidAmount = (pago['paid_amount_cash'] ?? 0.0).toDouble() +
              (pago['paid_amount_transferencia'] ?? 0.0).toDouble();
        } else {
          paidAmount = (pago['paid_amount'] ?? 0.0).toDouble();
        }
        final loanId = pago['loan_id']?[0];
        final pendiente = (status == 'pending' || status == 'late') &&
            (paymentAmount - paidAmount) > 0.0 &&
            loanId != null &&
            !processedLoans.contains(loanId);
        if (pendiente) processedLoans.add(loanId);
        return pendiente;
      }).toList();

      // 3. Excluir préstamos refinanciados, renovados o cancelados
      // Obtener los IDs de los préstamos
      final loanIds = pagosPendientes
          .map((pago) => pago['loan_id'][0])
          .where((id) => id != null)
          .toSet()
          .toList();

      // Obtener los datos de los préstamos
      final prestamosResponse = await post('/jsonrpc', body: {
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
              ["id", "in", loanIds]
            ],
            ["id", "loan_status"]
          ]
        }
      });

      final prestamos = Map<int, Map<String, dynamic>>.fromIterable(
        List<Map<String, dynamic>>.from(prestamosResponse['result'] ?? []),
        key: (prestamo) => prestamo['id'],
        value: (prestamo) => prestamo,
      );

      final pagosFinal = pagosPendientes.where((pago) {
        final loanId = pago['loan_id'][0];
        final prestamo = prestamos[loanId] ?? {};
        final loanStatus =
            (prestamo['loan_status'] ?? '').toString().toLowerCase();
        return loanStatus != 'refinanced' &&
            loanStatus != 'renewed' &&
            loanStatus != 'cancelled';
      }).toList();

      return pagosFinal;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la primera cuota pendiente de cada préstamo activo (no refinanciado, renovado ni cancelado, y con saldo > 0) en un rango de fechas para un gestor
  Future<List<Map<String, dynamic>>> getGestorPendingPaymentsInRange(
      String gestorId, DateTime start, DateTime end) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '1234';
      final database = prefs.getString('database') ?? 'prestamovf';
      final formattedStart = DateFormat('yyyy-MM-dd').format(start);
      final formattedEnd = DateFormat('yyyy-MM-dd').format(end);

      // 1. Obtener todos los pagos del gestor en el rango
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
              ["payment_date", ">=", formattedStart],
              ["payment_date", "<=", formattedEnd]
            ],
            [
              "id",
              "name",
              "payment_date",
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

      final pagos = List<Map<String, dynamic>>.from(response['result'] ?? []);

      // 2. Agrupar pagos por préstamo y quedarnos solo con la primera cuota pendiente en el rango
      final Map<dynamic, Map<String, dynamic>> firstPendingByLoan = {};
      for (var pago in pagos) {
        final loanId = pago['loan_id']?[0];
        if (loanId == null) continue;
        final status = (pago['payment_status'] ?? '').toLowerCase();
        final paymentAmount = (pago['payment_amount'] ?? 0.0) is num
            ? (pago['payment_amount'] ?? 0.0).toDouble()
            : double.tryParse(pago['payment_amount']?.toString() ?? '0') ?? 0.0;
        double paidAmount = 0.0;
        if (pago['payment_met'] == 'mixto') {
          paidAmount = (pago['paid_amount_cash'] ?? 0.0).toDouble() +
              (pago['paid_amount_transferencia'] ?? 0.0).toDouble();
        } else {
          paidAmount = (pago['paid_amount'] ?? 0.0).toDouble();
        }
        final isPending = (status == 'pending' || status == 'late') &&
            (paymentAmount - paidAmount) > 0.0;
        if (!isPending) continue;
        if (!firstPendingByLoan.containsKey(loanId) ||
            (pago['payment_date'] != null &&
                (firstPendingByLoan[loanId]!['payment_date'] == null ||
                    pago['payment_date'].compareTo(
                            firstPendingByLoan[loanId]!['payment_date']) <
                        0))) {
          firstPendingByLoan[loanId] = pago;
        }
      }

      if (firstPendingByLoan.isEmpty) return [];

      // 3. Excluir préstamos refinanciados, renovados, cancelados o con saldo 0
      final loanIds = firstPendingByLoan.keys.toList();
      final prestamosResponse = await post('/jsonrpc', body: {
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
              ["id", "in", loanIds]
            ],
            ["id", "loan_status", "current_due"]
          ]
        }
      });
      final prestamos = Map<int, Map<String, dynamic>>.fromIterable(
        List<Map<String, dynamic>>.from(prestamosResponse['result'] ?? []),
        key: (prestamo) => prestamo['id'],
        value: (prestamo) => prestamo,
      );
      final pagosFinal = firstPendingByLoan.entries
          .where((entry) {
            final prestamo = prestamos[entry.key] ?? {};
            final loanStatus =
                (prestamo['loan_status'] ?? '').toString().toLowerCase();
            final currentDue = (prestamo['current_due'] ?? 0.0) is num
                ? (prestamo['current_due'] ?? 0.0).toDouble()
                : double.tryParse(prestamo['current_due']?.toString() ?? '0') ??
                    0.0;
            return loanStatus == 'pending' && currentDue > 0.0;
          })
          .map((e) => e.value)
          .toList();

      return pagosFinal;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene los pagos diarios pendientes con coordenadas válidas para el mapa del supervisor, filtrando por gestor y fecha, sin filtrar por saldo ni duplicados
  Future<List<Map<String, dynamic>>>
      getDailyPendingPaymentsWithCoordinatesForSupervisor(
          String gestorId, String formattedDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '1234';
      final database = prefs.getString('database') ?? 'prestamovf';

      // 1. Obtener pagos pendientes diarios del gestor (solo campos simples)
      final pagosResponse = await post('/jsonrpc', body: {
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
              ["payment_date", "=", formattedDate],
              ["payment_status", "=", "pending"],
              ["loan_id.payment_period", "=", "daily"],
              ["loan_id.partner_salesperson", "=", int.parse(gestorId)]
            ],
            [
              "id",
              "loan_id",
              "partner_id",
              "payment_amount",
              "payment_status",
              "payment_date"
            ]
          ]
        }
      });

      if (pagosResponse.containsKey('error')) {
        print('ODDO ERROR (pagos): \n${pagosResponse['error']}');
        throw Exception(
            pagosResponse['error']['message'] ?? 'Error desconocido');
      }

      final pagos =
          List<Map<String, dynamic>>.from(pagosResponse['result'] ?? []);
      if (pagos.isEmpty) return [];

      // 2. Obtener los IDs únicos de préstamo
      final loanIds = pagos
          .map((p) => p['loan_id'] != null && p['loan_id'] is List
              ? p['loan_id'][0]
              : null)
          .where((id) => id != null)
          .toSet()
          .toList();
      if (loanIds.isEmpty) return [];

      // 3. Consultar préstamos para obtener coordenadas y saldo actual
      final prestamosResponse = await post('/jsonrpc', body: {
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
              ["id", "in", loanIds]
            ],
            [
              "id",
              "partner_latitude",
              "partner_longitude",
              "name",
              "partner_id",
              "current_due"
            ]
          ]
        }
      });

      if (prestamosResponse.containsKey('error')) {
        print('ODDO ERROR (prestamos): \n${prestamosResponse['error']}');
        throw Exception(
            prestamosResponse['error']['message'] ?? 'Error desconocido');
      }

      final prestamos =
          List<Map<String, dynamic>>.from(prestamosResponse['result'] ?? []);
      final prestamosMap = {for (var p in prestamos) p['id']: p};

      // 4. Unir pagos y préstamos, filtrar solo los que tienen coordenadas válidas y saldo > 0
      final pagosConCoords = pagos
          .map((pago) {
            final loanId = pago['loan_id'] != null && pago['loan_id'] is List
                ? pago['loan_id'][0]
                : null;
            final prestamo = prestamosMap[loanId];
            if (prestamo == null) return null;
            final lat = prestamo['partner_latitude'] ?? 0.0;
            final lng = prestamo['partner_longitude'] ?? 0.0;
            final currentDue = prestamo['current_due'] ?? 0.0;
            if (lat == 0.0 && lng == 0.0) return null;
            if ((lat is num && lat.abs() < 0.001) ||
                (lng is num && lng.abs() < 0.001)) return null;
            if (currentDue == 0.0) return null;
            return {
              'latitude': lat,
              'longitude': lng,
              'client_name':
                  pago['partner_id'] != null && pago['partner_id'] is List
                      ? pago['partner_id'][1]
                      : 'Sin nombre',
              'amount': pago['payment_amount'] ?? 0.0,
              'status': pago['payment_status'] ?? 'pending',
              'loan_id': pago['loan_id'] != null && pago['loan_id'] is List
                  ? pago['loan_id'][1]
                  : '',
              'payment_id': pago['id'],
              'payment_date': pago['payment_date'],
              'partner_id':
                  pago['partner_id'] != null && pago['partner_id'] is List
                      ? pago['partner_id'][0]
                      : null,
              'loan_name': prestamo['name'] ?? '',
              'partner_id_name': prestamo['partner_id'] != null &&
                      prestamo['partner_id'] is List
                  ? prestamo['partner_id'][1]
                  : '',
            };
          })
          .where((p) => p != null)
          .cast<Map<String, dynamic>>()
          .toList();

      return pagosConCoords;
    } catch (e) {
      rethrow;
    }
  }
}
