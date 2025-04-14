import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _kpiData = _emptyKpiData();
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _disposed = false;

  static Map<String, dynamic> _emptyKpiData() => {
        'onTime': 0,
        'late': 0,
        'pending': 0,
        'totalAmount': 0.0,
        'totalPaid': 0.0,
        'totalPending': 0.0,
        'payments': [],
      };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get kpiData => Map<String, dynamic>.from(_kpiData);
  String get selectedDate => _selectedDate;

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

  Future<bool> registerPayment(
    int uid,
    int paymentId,
    Map<String, dynamic> paymentData,
  ) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final response = await ApiService().registerPayment(
        uid,
        paymentId,
        paymentData,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        return false;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar pago: $e';
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchDailyKPIs(int uid, [String? date]) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    if (date != null) {
      _selectedDate = date;
    }
    _safeNotifyListeners();

    try {
      debugPrint(
        'PaymentProvider - Obteniendo KPIs para fecha: $_selectedDate',
      );
      debugPrint('PaymentProvider - Usuario ID: $uid');

      final response = await ApiService().getDailyKPIs(uid, _selectedDate);

      if (_disposed) return;

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _kpiData = _emptyKpiData();
        debugPrint('PaymentProvider - Error: $_errorMessage');
      } else {
        _kpiData = Map<String, dynamic>.from(response);
        _errorMessage = null;
        debugPrint('PaymentProvider - Datos actualizados exitosamente');
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('PaymentProvider - Error en fetchDailyKPIs: $e');
      _errorMessage = 'Error al cargar indicadores: $e';
      _kpiData = _emptyKpiData();
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void setSelectedDate(String date) {
    if (_selectedDate != date && !_disposed) {
      _selectedDate = date;
      _safeNotifyListeners();
    }
  }

  // Getters seguros para los KPIs
  double getTotalPaidAmount() => _kpiData['totalPaid']?.toDouble() ?? 0.0;

  double getTotalExpectedAmount() => _kpiData['totalAmount']?.toDouble() ?? 0.0;

  double getProgressPercentage() {
    final totalExpected = getTotalExpectedAmount();
    if (totalExpected <= 0) return 0.0;
    final progress = getTotalPaidAmount() / totalExpected;
    return progress.clamp(0.0, 1.0);
  }

  int getOnTimePaymentsCount() => _kpiData['onTime']?.toInt() ?? 0;

  int getLatePaymentsCount() => _kpiData['late']?.toInt() ?? 0;

  int getTotalPaymentsCount() {
    if (_disposed) return 0;
    return (_kpiData['onTime']?.toInt() ?? 0) +
        (_kpiData['late']?.toInt() ?? 0) +
        (_kpiData['pending']?.toInt() ?? 0);
  }

  // Método para limpiar todos los datos
  void clearData() {
    _kpiData = _emptyKpiData();
    _isLoading = false;
    _errorMessage = null;
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _safeNotifyListeners();
  }
}
