import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/src/services/kpi_service.dart';

class KpiProvider extends ChangeNotifier {
  final KpiService _kpiService = KpiService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _totals = {
    'expected': 0.0,
    'paid': 0.0,
    'completionPercentage': 0.0
  };
  Map<String, int> _statusCounts = {
    'pending': 0,
    'late': 0,
    'completed': 0,
    'cancelled': 0,
    'partial': 0
  };
  bool _isMonthly = false;
  String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _currentUserId;
  bool _disposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get payments => _payments;
  Map<String, dynamic> get totals => _totals;
  Map<String, int> get statusCounts => _statusCounts;
  bool get isMonthly => _isMonthly;
  String get currentDate => _currentDate;

  // Getters calculados
  double get totalExpected => _totals['expected'] ?? 0.0;
  double get totalPaid => _totals['paid'] ?? 0.0;
  double get completionPercentage => _totals['completionPercentage'] ?? 0.0;
  double get progressPercentage => completionPercentage / 100;

  // Métodos para obtener estadísticas de pagos
  int getPendingPaymentsCount() => _statusCounts['pending'] ?? 0;
  int getOnTimePaymentsCount() => _statusCounts['completed'] ?? 0;
  int getLatePaymentsCount() => _statusCounts['late'] ?? 0;
  int getTotalPaymentsCount() {
    return (_statusCounts['completed'] ?? 0) +
        (_statusCounts['late'] ?? 0) +
        (_statusCounts['pending'] ?? 0);
  }

  double getTotalPaidAmount() => totalPaid;
  double getTotalExpectedAmount() => totalExpected;
  double getProgressPercentage() => progressPercentage;

  // Getter para datos de KPI
  Map<String, dynamic> get kpiData => {
        'payments': _payments,
        'totals': _totals,
        'statusCounts': _statusCounts,
      };

  // Nuevo getter para el ID de usuario actual
  String? get currentUserId => _currentUserId;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  void setPaymentType(bool isMonthly) {
    _isMonthly = isMonthly;
    _safeNotifyListeners();
  }

  Future<void> fetchDailyKPIs(String userId, String date) async {
    // Limpiar datos si es un usuario diferente
    if (_currentUserId != userId) {
      _resetData();
      _currentUserId = userId;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final DateTime parsedDate = DateTime.parse(date);
      final response = await _kpiService.getDailyKPIs(userId, parsedDate,
          isMonthly: _isMonthly);

      if (response['success']) {
        final data = response['data'];
        _payments = List<Map<String, dynamic>>.from(data['payments']);
        _totals = Map<String, dynamic>.from(data['totals']);
        _statusCounts = Map<String, int>.from(data['statusCounts']);
        _currentDate = data['date'];
        _error = null;
      } else {
        _error = response['error'];
        _resetData();
      }
    } catch (e) {
      _error = e.toString();
      _resetData();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _resetData() {
    _payments = [];
    _totals = {'expected': 0.0, 'paid': 0.0, 'completionPercentage': 0.0};
    _statusCounts = {
      'pending': 0,
      'late': 0,
      'completed': 0,
      'cancelled': 0,
      'partial': 0
    };
    _safeNotifyListeners();
  }

  void changeUser(String? newUserId) {
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _resetData();
    }
  }

  // Métodos de utilidad para la UI
  Map<String, dynamic> getPaymentStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'text': 'Pagado'
        };
      case 'late':
        return {
          'color': Colors.orange,
          'icon': Icons.warning,
          'text': 'Tardío'
        };
      case 'pending':
        return {
          'color': Colors.grey,
          'icon': Icons.schedule,
          'text': 'Pendiente'
        };
      case 'partial':
        return {
          'color': Colors.blue,
          'icon': Icons.incomplete_circle,
          'text': 'Parcial'
        };
      case 'cancelled':
        return {'color': Colors.red, 'icon': Icons.cancel, 'text': 'Cancelado'};
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'text': 'Desconocido'
        };
    }
  }

  String getPaymentMethodText(dynamic paymentMethod) {
    if (paymentMethod == null) return 'No especificado';
    if (paymentMethod is bool) {
      return paymentMethod ? 'Efectivo' : 'Transferencia';
    }
    if (paymentMethod is String) {
      return paymentMethod;
    }
    return 'No especificado';
  }

  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  List<Map<String, dynamic>> getPaymentDetails(Map<dynamic, dynamic> payment) {
    final details = <Map<String, dynamic>>[];

    details.add({
      'label': 'Monto esperado',
      'value': 'S/.${(payment['expectedAmount'] ?? 0.0).toStringAsFixed(2)}',
    });

    details.add({
      'label': 'Monto pagado',
      'value': 'S/.${(payment['paidAmount'] ?? 0.0).toStringAsFixed(2)}',
    });

    details.add({
      'label': 'Método de pago',
      'value': getPaymentMethodText(payment['paymentMet']),
    });

    details.add({
      'label': 'Fecha programada',
      'value': formatDate(payment['paymentDate'] ?? ''),
    });

    if (payment['actualPaymentDate'] != null &&
        payment['actualPaymentDate'].toString().isNotEmpty) {
      details.add({
        'label': 'Fecha real de pago',
        'value': formatDate(payment['actualPaymentDate']),
      });
    }

    return details;
  }

  String getClientName(Map<dynamic, dynamic> payment) {
    return payment['partnerId'] != null && payment['partnerId'] is List
        ? payment['partnerId'][1]
        : 'Cliente no especificado';
  }
}
