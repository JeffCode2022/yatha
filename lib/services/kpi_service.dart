import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yatha_app/config/environment.dart';
import 'package:intl/intl.dart';

class KpiService {
  final String baseUrl = Environment.apiUrl;
  final String dbName = Environment.dbName;

  Future<Map<String, dynamic>> getDailyKPIs(String userId, DateTime date,
      {bool isMonthly = false}) async {
    try {
      final response = await _getPayments(userId, date, isMonthly);
      final payments = _processPayments(response, isMonthly);

      final totalExpected = _calculateTotalExpected(payments);
      final totalPaid = _calculateTotalPaid(payments);
      final statusCounts = _calculateStatusCounts(payments);
      final completionPercentage = totalExpected > 0
          ? (totalPaid / totalExpected * 100).toDouble()
          : 0.0;

      return {
        'success': true,
        'data': {
          'payments': payments,
          'totals': {
            'expected': totalExpected,
            'paid': totalPaid,
            'completionPercentage': completionPercentage
          },
          'statusCounts': statusCounts,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'isMonthly': isMonthly
        }
      };
    } catch (e) {
      print('Error en getDailyKPIs: ${e.toString()}');
      return {
        'success': false,
        'error': e.toString(),
        'data': {
          'payments': [],
          'totals': {'expected': 0.0, 'paid': 0.0, 'completionPercentage': 0.0},
          'statusCounts': {
            'pending': 0,
            'late': 0,
            'completed': 0,
            'cancelled': 0,
            'partial': 0
          },
          'date': DateFormat('yyyy-MM-dd').format(date),
          'isMonthly': isMonthly
        }
      };
    }
  }

  Future<dynamic> _getPayments(
      String userId, DateTime date, bool isMonthly) async {
    final url = Uri.parse('$baseUrl/jsonrpc');
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

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
            ["payment_date", "=", formattedDate]
          ];

    print('KpiService - URL: $url');
    print('KpiService - Filtros: $queryFilters');
    print('KpiService - Campos: $queryFields');
    print('KpiService - Usuario ID: $userId');
    print('KpiService - Es mensual: $isMonthly');

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
            isMonthly ? "loan.management" : "loan.payment",
            "search_read",
            queryFilters,
            queryFields
          ]
        }
      }),
    );

    print('KpiService - Status code: ${response.statusCode}');
    print('KpiService - Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      if (decodedData.containsKey('error')) {
        print('KpiService - Error en la respuesta: ${decodedData['error']}');
        throw Exception(
            decodedData['error']['data']['message'] ?? 'Error desconocido');
      }
      final result = decodedData['result'] ?? [];
      print('KpiService - Número de préstamos encontrados: ${result.length}');
      return result;
    } else {
      throw Exception('Error al obtener pagos: ${response.statusCode}');
    }
  }

  List<Map<String, dynamic>> _processPayments(
      List<dynamic> rawPayments, bool isMonthly) {
    print('KpiService - Procesando ${rawPayments.length} pagos');
    return rawPayments.map<Map<String, dynamic>>((payment) {
      if (isMonthly) {
        final totalPaid = ((payment['total_cash_payments'] ?? 0.0) +
                (payment['total_transfer_payments'] ?? 0.0))
            .toDouble();
        final status = _determinePaymentStatus(payment['days_overdue'] ?? 0,
            totalPaid, payment['amount_due_today'] ?? 0.0);

        print(
            'KpiService - Procesando pago mensual: ${payment['name']} - Estado: $status');

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
        print(
            'KpiService - Procesando pago diario: ${payment['name']} - Estado: $status');

        return {
          'id': payment['id'],
          'name': payment['name'],
          'paymentDate': payment['payment_date'],
          'actualPaymentDate': payment['actual_payment_date'],
          'status': status,
          'expectedAmount': (payment['payment_amount'] ?? 0).toDouble(),
          'paidAmount': (payment['paid_amount'] ?? 0).toDouble(),
          'partnerId': payment['partner_id'],
          'loanId': payment['loan_id'],
          'paymentMet': payment['payment_met'],
        };
      }
    }).toList();
  }

  String _determinePaymentStatus(
      int daysOverdue, double totalPaid, double amountDue) {
    if (totalPaid >= amountDue) {
      return daysOverdue > 0 ? 'late' : 'paid';
    }
    if (totalPaid > 0 && totalPaid < amountDue) {
      return 'partial';
    }
    if (daysOverdue > 0) {
      return 'late';
    }
    return 'pending';
  }

  double _calculateTotalExpected(List<Map<String, dynamic>> payments) {
    return payments.fold(
        0.0, (sum, payment) => sum + (payment['expectedAmount'] ?? 0.0));
  }

  double _calculateTotalPaid(List<Map<String, dynamic>> payments) {
    return payments.fold(
        0.0, (sum, payment) => sum + (payment['paidAmount'] ?? 0.0));
  }

  Map<String, int> _calculateStatusCounts(List<Map<String, dynamic>> payments) {
    final counts = {
      'pending': 0,
      'late': 0,
      'completed': 0,
      'cancelled': 0,
      'partial': 0,
    };

    for (var payment in payments) {
      final status = payment['status']?.toLowerCase() ?? 'pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
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
      final currentDue = (payment['current_due'] ?? 0.0).toDouble();

      if (status == 'pending') {
        stats['pending'] = (stats['pending'] as int) + 1;
      } else if (status == 'completed') {
        stats['completed'] = (stats['completed'] as int) + 1;
      }

      stats['total_expected'] =
          (stats['total_expected'] as double) + paymentAmount;
      stats['total_paid'] = (stats['total_paid'] as double) + paidAmount;
      stats['total_due'] = (stats['total_due'] as double) + currentDue;
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
}
