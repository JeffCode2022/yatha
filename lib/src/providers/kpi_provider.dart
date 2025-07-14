import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/src/services/kpi_service.dart';

/// KpiProvider - Proveedor para gestionar KPIs de préstamos y pagos
///
/// Este provider calcula automáticamente:
/// - Meta (total esperado)
/// - Recaudado (total pagado)
/// - Eficiencia (porcentaje de cumplimiento)
/// - Pagos pendientes, a tiempo y tardíos
/// - Monto pendiente y préstamos pendientes
///
/// Uso:
/// ```dart
/// final kpiProvider = Provider.of<KpiProvider>(context, listen: false);
/// await kpiProvider.fetchDailyKPIs(userId, date);
///
/// // Acceder a KPIs
/// double meta = kpiProvider.meta;
/// double recaudado = kpiProvider.recaudado;
/// double eficiencia = kpiProvider.eficiencia;
/// int pendientes = kpiProvider.pagosPendientes;
/// int aTiempo = kpiProvider.pagosATiempo;
/// int tardios = kpiProvider.pagosTardios;
///
/// // Obtener resumen completo
/// Map<String, dynamic> resumen = kpiProvider.kpiResumen;
/// Map<String, dynamic> estadisticas = kpiProvider.estadisticasDetalladas;
/// ```
class KpiProvider extends ChangeNotifier {
  final KpiService _kpiService = KpiService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _totals = {
    'expected': 0.0,
    'paid': 0.0,
    'completionPercentage': 0.0,
    'pendingAmount': 0.0,
    'totalLoans': 0
  };
  Map<String, int> _statusCounts = {
    'pending': 0,
    'late': 0,
    'completed': 0,
    'cancelled': 0,
    'partial': 0,
    'ontime': 0
  };
  bool _isMonthly = false;
  String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _currentUserId;
  bool _disposed = false;
  bool _sessionExpired = false;

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
  double get pendingAmount => _totals['pendingAmount'] ?? 0.0;
  int get totalLoans => _totals['totalLoans'] ?? 0;
  double get completionPercentage => _totals['completionPercentage'] ?? 0.0;
  double get progressPercentage => completionPercentage / 100;

  // Métodos para obtener estadísticas de pagos
  int getPendingPaymentsCount() => _statusCounts['pending'] ?? 0;
  int getOnTimePaymentsCount() => _statusCounts['ontime'] ?? 0;
  int getLatePaymentsCount() => _statusCounts['late'] ?? 0;
  int getTotalPaymentsCount() {
    return (_statusCounts['ontime'] ?? 0) +
        (_statusCounts['late'] ?? 0) +
        (_statusCounts['pending'] ?? 0);
  }

  double getTotalPaidAmount() => totalPaid;
  double getTotalExpectedAmount() => totalExpected;
  double getProgressPercentage() => progressPercentage;

  // Nuevos métodos para KPIs específicos
  double get meta => totalExpected; // Total esperado
  double get recaudado => totalPaid; // Total pagado
  double get eficiencia => completionPercentage; // Porcentaje de eficiencia
  int get pagosPendientes => getPendingPaymentsCount(); // Pagos pendientes
  int get pagosATiempo => getOnTimePaymentsCount(); // Pagos a tiempo
  int get pagosTardios => getLatePaymentsCount(); // Pagos tardíos

  // Método para obtener resumen de KPIs
  Map<String, dynamic> get kpiResumen => {
        'meta': meta,
        'recaudado': recaudado,
        'eficiencia': eficiencia,
        'pagosPendientes': pagosPendientes,
        'pagosATiempo': pagosATiempo,
        'pagosTardios': pagosTardios,
        'montoPendiente': pendingAmount,
        'prestamosPendientes': totalLoans,
      };

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
        // Filtrar préstamos renovados/refinanciados/cancelados
        _payments = _payments.where((p) {
          final loanStatus = p['loan_status']?.toString() ?? '';
          return loanStatus != 'refinanced' &&
              loanStatus != 'renewed' &&
              loanStatus != 'cancelled';
        }).toList();
        _totals = Map<String, dynamic>.from(data['totals']);
        _pagosRealizados = data['pagosRealizados'] ?? 0;
        _pagosPendientes = data['pagosPendientes'] ?? 0;
        _currentDate = data['date'];
        _error = null;
        _calculateCompleteKPIs();
      } else {
        // Manejar errores específicos del servidor
        final errorMessage = response['error'] ?? 'Error desconocido';
        if (errorMessage.contains('MissingError')) {
          _error =
              'No se encontraron datos para la fecha especificada. Verifique que tenga préstamos asignados para hoy.';
        } else if (errorMessage.contains('AccessDenied')) {
          // Intentar renovar la sesión automáticamente
          _error = 'Sesión expirada. Por favor, inicie sesión nuevamente.';
          // Notificar que la sesión expiró para que se maneje en el UI
          _notifySessionExpired();
        } else if (errorMessage.contains('Odoo Server Error')) {
          _error =
              'Error del servidor. Por favor, intente nuevamente en unos minutos.';
        } else if (errorMessage.contains('Error de conexión')) {
          _error = 'Error de conexión. Verifique su conexión a internet.';
        } else {
          _error = 'Error al cargar los datos: $errorMessage';
        }
        _resetData();
      }
    } catch (e) {
      _error = 'Error interno de la aplicación. Por favor, reinicie la app.';
      _resetData();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _calculateCompleteKPIs() {
    // Inicializar contadores
    double totalExpected = 0.0;
    double totalPaid = 0.0;
    double totalPendingAmount = 0.0;
    int pendingLoans = 0;
    int ontimeCount = 0;
    int lateCount = 0;
    int pendingCount = 0;
    Set<dynamic> processedLoans = {};

    // Procesar cada pago
    for (var payment in _payments) {
      final expectedAmount = (payment['expectedAmount'] ?? 0.0).toDouble();
      final paidAmount = (payment['paidAmount'] ?? 0.0).toDouble();
      final status = payment['status']?.toString() ?? 'pending';
      final timeStatus = payment['timeStatus']?.toString();
      final loanId = payment['loanId'];

      // Calcular totales
      totalExpected += expectedAmount;
      totalPaid += paidAmount;

      // Calcular monto pendiente y préstamos pendientes
      if ((status == 'pending' || status == 'late') &&
          (expectedAmount - paidAmount) > 0.0) {
        totalPendingAmount += expectedAmount - paidAmount;
        if (loanId != null && !processedLoans.contains(loanId)) {
          pendingLoans++;
          processedLoans.add(loanId);
        }
      }

      // Contar por estado de tiempo
      if (status == 'paid' ||
          status == 'completed' ||
          status == 'overpaid' ||
          status == 'partial') {
        if (timeStatus == 'ontime') {
          ontimeCount++;
        } else if (timeStatus == 'late') {
          lateCount++;
        }
      } else if (status == 'pending' && (expectedAmount - paidAmount) > 0.0) {
        pendingCount++;
      } else if (status == 'late') {
        lateCount++;
      }
    }

    // Calcular eficiencia
    double completionPercentage =
        totalExpected > 0 ? (totalPaid / totalExpected * 100) : 0.0;

    // Actualizar totales
    _totals = {
      'expected': totalExpected,
      'paid': totalPaid,
      'completionPercentage': completionPercentage,
      'pendingAmount': totalPendingAmount,
      'totalLoans': pendingLoans
    };

    // Actualizar contadores de estado
    _statusCounts = {
      'pending': pendingCount,
      'late': lateCount,
      'completed': 0, // Se calcula por separado
      'cancelled': 0,
      'partial': 0,
      'ontime': ontimeCount
    };
  }

  void _resetData() {
    _payments = [];
    _totals = {
      'expected': 0.0,
      'paid': 0.0,
      'completionPercentage': 0.0,
      'pendingAmount': 0.0,
      'totalLoans': 0
    };
    _statusCounts = {
      'pending': 0,
      'late': 0,
      'completed': 0,
      'cancelled': 0,
      'partial': 0,
      'ontime': 0
    };
    _processedLoans.clear();
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
      if (paymentMethod == 'mixto') return 'Mixto';
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

    // Si es pago mixto, mostrar el desglose
    if (payment['paymentMet'] == 'mixto') {
      details.add({
        'label': 'Efectivo',
        'value':
            'S/.${(payment['paid_amount_cash'] ?? 0.0).toStringAsFixed(2)}',
      });
      details.add({
        'label': 'Transferencia',
        'value':
            'S/.${(payment['paid_amount_transferencia'] ?? 0.0).toStringAsFixed(2)}',
      });
    }

    details.add({
      'label': 'Monto total pagado',
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

  // Método para obtener estadísticas detalladas
  Map<String, dynamic> get estadisticasDetalladas {
    final totalPayments = _payments.length;
    final completedPayments = _payments
        .where((p) =>
            p['status'] == 'paid' ||
            p['status'] == 'completed' ||
            p['status'] == 'overpaid')
        .length;

    return {
      'totalPagos': totalPayments,
      'pagosCompletados': completedPayments,
      'pagosPendientes': pagosPendientes,
      'pagosATiempo': pagosATiempo,
      'pagosTardios': pagosTardios,
      'meta': meta,
      'recaudado': recaudado,
      'eficiencia': eficiencia,
      'montoPendiente': pendingAmount,
      'prestamosPendientes': totalLoans,
      'porcentajeCompletado':
          totalPayments > 0 ? (completedPayments / totalPayments * 100) : 0.0,
    };
  }

  // Método para obtener pagos filtrados por estado
  List<Map<String, dynamic>> getPagosPorEstado(String estado) {
    return _payments
        .where((payment) =>
            payment['status']?.toString().toLowerCase() == estado.toLowerCase())
        .toList();
  }

  // Método para obtener pagos por tiempo
  List<Map<String, dynamic>> getPagosPorTiempo(String tiempo) {
    return _payments
        .where((payment) =>
            payment['timeStatus']?.toString().toLowerCase() ==
            tiempo.toLowerCase())
        .toList();
  }

  // Método para verificar si hay datos cargados
  bool get tieneDatos => _payments.isNotEmpty;

  // Método para obtener el resumen en formato de texto
  String get resumenTexto {
    return 'Meta: S/.${meta.toStringAsFixed(2)} | '
        'Recaudado: S/.${recaudado.toStringAsFixed(2)} | '
        'Eficiencia: ${eficiencia.toStringAsFixed(1)}% | '
        'Pendientes: $pagosPendientes | '
        'A tiempo: $pagosATiempo | '
        'Tardíos: $pagosTardios';
  }

  final Set<dynamic> _processedLoans = {};

  // Nuevos campos para pagos realizados y pendientes
  int _pagosRealizados = 0;
  int _pagosPendientes = 0;
  int get pagosRealizados => _pagosRealizados;

  void _notifySessionExpired() {
    // Marcar que la sesión expiró para que se maneje en el UI
    _sessionExpired = true;
    _safeNotifyListeners();
  }

  // Getter para verificar si la sesión expiró
  bool get sessionExpired => _sessionExpired;

  // Método para resetear el estado de sesión expirada
  void resetSessionExpired() {
    _sessionExpired = false;
    _safeNotifyListeners();
  }
}
