import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yatha_app/src/config/environment.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/date_utils.dart';
import 'package:yatha_app/src/utils/logger.dart';
import 'package:yatha_app/src/config/environment.dart' as env;

class KpiService extends BaseService {
  String get baseUrl => Environment.apiUrl;
  String get dbName => Environment.dbName;

  Future<Map<String, dynamic>> _getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid');
      final password = prefs.getString('password');

      if (uid == null || password == null) {
        print('KpiService - No hay credenciales guardadas');
        return {};
      }

      return {
        'uid': uid,
        'password': password,
      };
    } catch (e) {
      print('KpiService - Error al obtener credenciales: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getDailyKPIs(String userId, DateTime date,
      {bool isMonthly = false}) async {
    try {
      final url = Uri.parse('$baseUrl/jsonrpc');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "service": "object",
            "method": "execute",
            "args": [
              dbName,
              int.parse(userId),
              "1234",
              "loan.payment",
              "search_read",
              [
                ["loan_id", "!=", false],
                ["loan_id.partner_salesperson", "=", int.parse(userId)],
                ["payment_date", "=", DateUtils.formatDate(date)]
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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Respuesta cruda del API: $data');

        // Verificar si hay error en la respuesta
        if (data['error'] != null) {
          Logger.error('Error del servidor Odoo', data['error']);
          return {
            'success': false,
            'error': data['error']['message'] ?? 'Error del servidor Odoo',
            'data': {
              'payments': [],
              'totals': {
                'expected': 0.0,
                'paid': 0.0,
                'completionPercentage': 0.0
              },
              'pagosRealizados': 0,
              'pagosPendientes': 0,
              'date': DateUtils.formatDate(date),
              'isMonthly': isMonthly
            }
          };
        }

        // Verificar si hay resultado
        if (data['result'] == null) {
          Logger.warning('No hay resultado en la respuesta del API');
          return {
            'success': false,
            'error': 'No se encontraron datos para la fecha especificada',
            'data': {
              'payments': [],
              'totals': {
                'expected': 0.0,
                'paid': 0.0,
                'completionPercentage': 0.0
              },
              'pagosRealizados': 0,
              'pagosPendientes': 0,
              'date': DateUtils.formatDate(date),
              'isMonthly': isMonthly
            }
          };
        }

        final result = data['result'];
        if (result is Map) {
          final liquidacion = result['liquidacion_diaria'] ?? {};
          final pagos = result['pagos'] ?? [];

          final totalDue = liquidacion['total_due'] ?? 0.0;
          final totalCollected = liquidacion['total_collected'] ?? 0.0;
          final efficiency = liquidacion['progress_percentage'] ?? 0.0;

          int pagosRealizados = pagos
              .where(
                  (p) => (p['pagado'] == true || p['payment_status'] == 'paid'))
              .length;
          int pagosPendientes = pagos
              .where(
                  (p) => (p['pagado'] != true && p['payment_status'] != 'paid'))
              .length;

          final payments = _processPayments(pagos, false);

          return {
            'success': true,
            'data': {
              'payments': payments,
              'totals': {
                'expected': totalDue,
                'paid': totalCollected,
                'completionPercentage': efficiency,
              },
              'pagosRealizados': pagosRealizados,
              'pagosPendientes': pagosPendientes,
              'date': DateUtils.formatDate(date),
              'isMonthly': isMonthly
            }
          };
        } else if (result is List) {
          final pagos = result;
          double totalDue = 0.0;
          double totalCollected = 0.0;
          int pagosRealizados = 0;
          int pagosPendientes = 0;

          for (final p in pagos) {
            final paymentAmount = (p['payment_amount'] ?? 0.0).toDouble();
            double paidAmount = 0.0;
            if (p['payment_met'] == 'mixto') {
              paidAmount = (p['paid_amount_cash'] ?? 0.0).toDouble() +
                  (p['paid_amount_transferencia'] ?? 0.0).toDouble();
            } else {
              paidAmount = (p['paid_amount'] ?? 0.0).toDouble();
            }
            totalDue += paymentAmount;
            totalCollected += paidAmount;
            if ((p['payment_status'] ?? '') == 'paid' ||
                (p['payment_status'] ?? '') == 'overpaid') {
              pagosRealizados++;
            } else {
              pagosPendientes++;
            }
          }
          final efficiency =
              totalDue > 0 ? (totalCollected / totalDue) * 100 : 0.0;
          final payments = _processPayments(pagos, false);

          return {
            'success': true,
            'data': {
              'payments': payments,
              'totals': {
                'expected': totalDue,
                'paid': totalCollected,
                'completionPercentage': efficiency,
              },
              'pagosRealizados': pagosRealizados,
              'pagosPendientes': pagosPendientes,
              'date': DateUtils.formatDate(date),
              'isMonthly': isMonthly
            }
          };
        } else {
          Logger.warning('Tipo de resultado inesperado: ${result.runtimeType}');
          return {
            'success': false,
            'error': 'Formato de respuesta inesperado del servidor',
            'data': {
              'payments': [],
              'totals': {
                'expected': 0.0,
                'paid': 0.0,
                'completionPercentage': 0.0
              },
              'pagosRealizados': 0,
              'pagosPendientes': 0,
              'date': DateUtils.formatDate(date),
              'isMonthly': isMonthly
            }
          };
        }
      } else {
        Logger.error('Error HTTP', 'Status code: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Error de conexión: ${response.statusCode}',
          'data': {
            'payments': [],
            'totals': {
              'expected': 0.0,
              'paid': 0.0,
              'completionPercentage': 0.0
            },
            'pagosRealizados': 0,
            'pagosPendientes': 0,
            'date': DateUtils.formatDate(date),
            'isMonthly': isMonthly
          }
        };
      }
    } catch (e) {
      Logger.error('Error en getDailyKPIs', e);
      return {
        'success': false,
        'error': 'Error interno: ${e.toString()}',
        'data': {
          'payments': [],
          'totals': {'expected': 0.0, 'paid': 0.0, 'completionPercentage': 0.0},
          'pagosRealizados': 0,
          'pagosPendientes': 0,
          'date': DateUtils.formatDate(date),
          'isMonthly': isMonthly
        }
      };
    }
  }

  Future<dynamic> _getPayments(
      String userId, DateTime date, bool isMonthly) async {
    final queryFields = isMonthly
        ? [
            "id",
            "partner_id",
            "name",
            "loan_status",
            "payment_amount",
            "amount_due_today",
            "total_cash_payments",
            "total_transfer_payments",
            "loan_amount",
            "total_amount",
            "current_due",
            "days_overdue",
            "payment_period",
            "partner_salesperson"
          ]
        : [
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
          ];

    final queryFilters = isMonthly
        ? [
            ["payment_period", "=", "monthly"],
            ["partner_salesperson.id", "=", int.parse(userId)],
            [
              "loan_status",
              "in",
              ["pending", "active"]
            ]
          ]
        : [
            ["loan_id", "!=", false],
            ["loan_id.partner_salesperson", "=", int.parse(userId)],
            ["payment_date", "=", DateUtils.formatDate(date)]
          ];

    Logger.debug('Obteniendo pagos para usuario: $userId');
    Logger.debug('Fecha: ${DateUtils.formatDate(date)}');
    Logger.debug('Es mensual: $isMonthly');

    final response = await executeOdooMethod(
      model: isMonthly ? "loan.management" : "loan.payment",
      method: "search_read",
      args: [queryFilters, queryFields],
    );

    if (response['result'] != null) {
      Logger.info('Pagos encontrados: ${response['result'].length}');
      return response['result'];
    }

    throw Exception('Error al obtener pagos');
  }

  List<Map<String, dynamic>> _processPayments(
      List<dynamic> rawPayments, bool isMonthly) {
    Logger.debug('Procesando ${rawPayments.length} pagos');
    return rawPayments.map<Map<String, dynamic>>((payment) {
      if (isMonthly) {
        final totalPaid = ((payment['total_cash_payments'] ?? 0.0) +
                (payment['total_transfer_payments'] ?? 0.0))
            .toDouble();
        final status = _determinePaymentStatus(
          payment['days_overdue'] ?? 0,
          totalPaid,
          payment['amount_due_today'] ?? 0.0,
        );

        return {
          'id': payment['id'],
          'name': payment['name'],
          'status': status,
          'expectedAmount': (payment['amount_due_today'] ?? 0).toDouble(),
          'paidAmount': totalPaid,
          'partnerId': payment['partner_id'],
          'loanAmount': (payment['loan_amount'] ?? 0).toDouble(),
          'totalAmount': (payment['total_amount'] ?? 0).toDouble(),
          'currentDue': (payment['current_due'] ?? 0).toDouble(),
          'daysOverdue': payment['days_overdue'] ?? 0,
        };
      } else {
        final status = payment['payment_status'] ?? 'pending';
        double paidAmount = 0.0;

        if (payment['payment_met'] == 'mixto') {
          double cashAmount = (payment['paid_amount_cash'] ?? 0.0).toDouble();
          double transferAmount =
              (payment['paid_amount_transferencia'] ?? 0.0).toDouble();
          paidAmount = cashAmount + transferAmount;
        } else {
          paidAmount = (payment['paid_amount'] ?? 0.0).toDouble();
        }

        final timeStatus = _calculatePaymentTimeStatus(
          payment['payment_date'] ?? '',
          payment['actual_payment_date'],
          status,
        );

        return {
          'id': payment['id'],
          'name': payment['name'],
          'paymentDate': payment['payment_date'],
          'actualPaymentDate': payment['actual_payment_date'],
          'status': status,
          'timeStatus': timeStatus,
          'expectedAmount': (payment['payment_amount'] ?? 0).toDouble(),
          'paidAmount': paidAmount,
          'partnerId': payment['partner_id'],
          'loanId': payment['loan_id'],
          'paymentMet': payment['payment_met'],
          'paid_amount_cash': (payment['paid_amount_cash'] ?? 0.0).toDouble(),
          'paid_amount_transferencia':
              (payment['paid_amount_transferencia'] ?? 0.0).toDouble(),
        };
      }
    }).toList();
  }

  double _calculateTotalExpected(List<Map<String, dynamic>> payments) {
    return payments.fold(
      0.0,
      (sum, payment) => sum + (payment['expectedAmount'] ?? 0.0),
    );
  }

  double _calculateTotalPaid(List<Map<String, dynamic>> payments) {
    return payments.fold(
      0.0,
      (sum, payment) => sum + (payment['paidAmount'] ?? 0.0),
    );
  }

  Map<String, int> _calculateStatusCounts(List<Map<String, dynamic>> payments) {
    final counts = {
      'pending': 0,
      'late': 0,
      'completed': 0,
      'cancelled': 0,
      'partial': 0
    };

    for (var payment in payments) {
      final status = payment['status']?.toString() ?? 'pending';
      final timeStatus = payment['timeStatus']?.toString();

      if (status == 'pending') {
        if (timeStatus == 'late') {
          counts['late'] = (counts['late'] ?? 0) + 1;
        } else {
          counts['pending'] = (counts['pending'] ?? 0) + 1;
        }
      } else if (status == 'paid' ||
          status == 'overpaid' ||
          status == 'partial') {
        counts['completed'] = (counts['completed'] ?? 0) + 1;
      } else if (status == 'cancelled') {
        counts['cancelled'] = (counts['cancelled'] ?? 0) + 1;
      }
    }

    return counts;
  }

  String _determinePaymentStatus(
    int daysOverdue,
    double paidAmount,
    double expectedAmount,
  ) {
    if (paidAmount >= expectedAmount) {
      return 'paid';
    } else if (paidAmount > 0) {
      return 'partial';
    } else if (daysOverdue > 0) {
      return 'late';
    } else {
      return 'pending';
    }
  }

  String _calculatePaymentTimeStatus(
    String paymentDate,
    String? actualPaymentDate,
    String status,
  ) {
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
      Logger.error('Error al calcular estado por tiempo', e);
    }

    return 'pending';
  }

  Map<String, dynamic> _calculatePaymentStats(List<dynamic> payments) {
    final stats = {
      'pending': 0,
      'completed': 0,
      'total_count': payments.length,
      'total_expected': 0.0,
      'total_paid': 0.0,
      'total_due': 0.0
    };

    for (var payment in payments) {
      final status = payment['payment_status'] as String;
      final paymentAmount = (payment['payment_amount'] ?? 0.0).toDouble();
      final paidAmount = (payment['paid_amount'] ?? 0.0).toDouble();

      if (status == 'pending') {
        stats['pending'] = (stats['pending'] as int) + 1;
      } else if (status == 'completed') {
        stats['completed'] = (stats['completed'] as int) + 1;
      }

      stats['total_expected'] =
          (stats['total_expected'] as double) + paymentAmount;
      stats['total_paid'] = (stats['total_paid'] as double) + paidAmount;
      stats['total_due'] =
          (stats['total_expected'] as double) - (stats['total_paid'] as double);
    }

    return stats;
  }

  Future<Map<String, dynamic>> getPaymentStats(
      String userId, String date) async {
    try {
      final url = Uri.parse('$baseUrl/jsonrpc');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "service": "object",
            "method": "execute",
            "args": [
              dbName,
              int.parse(userId),
              "1234",
              "loan.payment",
              "search_read",
              [
                ["loan_id", "!=", false],
                ["loan_id.partner_salesperson", "=", int.parse(userId)],
                ["payment_date", "=", date]
              ],
              ["payment_status", "paid_amount", "payment_amount", "current_due"]
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData.containsKey('error')) {
          throw Exception(
              decodedData['error']['data']['message'] ?? 'Error desconocido');
        }
        final processedPayments =
            _processPayments(decodedData['result'] ?? [], false);
        return {
          'stats': _calculatePaymentStats(processedPayments),
        };
      } else {
        throw Exception(
            'Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la conexión: $e');
    }
  }

  Future<Map<String, dynamic>> getKpis() async {
    try {
      final queryFilters = [
        ["partner_salesperson", "=", (await getCredentials())['uid']]
      ];

      final response = await executeOdooMethod(
        model: "loan.management",
        method: "search_read",
        args: [queryFilters, _getKpiFields()],
      );

      if (response['result'] != null) {
        final loans = List<Map<String, dynamic>>.from(response['result']);
        return _calculateKpis(loans);
      }
      return {};
    } catch (e) {
      Logger.error('Error en getKpis', e);
      rethrow;
    }
  }

  List<String> _getKpiFields() {
    return [
      "id",
      "name",
      "partner_salesperson",
      "loan_status",
      "loan_amount",
      "payment_period",
      "payment_parts",
      "amount_due_today",
      "total_amount"
    ];
  }

  Map<String, dynamic> _calculateKpis(List<Map<String, dynamic>> loans) {
    final totalLoans = loans.length;
    final totalAmount = loans.fold<double>(
        0, (sum, loan) => sum + (loan['loan_amount'] ?? 0.0));
    final totalDue = loans.fold<double>(
        0, (sum, loan) => sum + (loan['amount_due_today'] ?? 0.0));
    final pendingLoans =
        loans.where((loan) => loan['loan_status'] == 'pending').length;
    final completedLoans =
        loans.where((loan) => loan['loan_status'] == 'paid').length;

    return {
      'total_loans': totalLoans,
      'total_amount': totalAmount,
      'total_due': totalDue,
      'pending_loans': pendingLoans,
      'completed_loans': completedLoans,
      'completion_rate': totalLoans > 0
          ? (completedLoans / totalLoans * 100).toStringAsFixed(2)
          : '0.00',
    };
  }
}
