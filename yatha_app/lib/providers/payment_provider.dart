import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _kpiData = {'onTime': [], 'late': [], 'total': []};
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get kpiData => _kpiData;
  String get selectedDate => _selectedDate;

  // Función para registrar un pago
  Future<bool> registerPayment(
    int uid,
    int paymentId,
    Map<String, dynamic> paymentData,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().registerPayment(
        uid,
        paymentId,
        paymentData,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error al registrar pago: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Función para obtener los KPIs del día
  Future<void> fetchDailyKPIs(int uid, [String? date]) async {
    _isLoading = true;
    _errorMessage = null;

    if (date != null) {
      _selectedDate = date;
    }

    notifyListeners();

    try {
      final response = await ApiService().getDailyKPIs(uid, _selectedDate);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _kpiData = {'onTime': [], 'late': [], 'total': []};
      } else {
        _kpiData = response;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar indicadores: $e';
      _kpiData = {'onTime': [], 'late': [], 'total': []};
    }

    _isLoading = false;
    notifyListeners();
  }

  // Función para cambiar la fecha seleccionada
  void setSelectedDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Calcular total de pagos realizados
  double getTotalPaidAmount() {
    double onTimeAmount = 0;
    for (var payment in _kpiData['onTime']) {
      onTimeAmount += payment['paid_amount'] ?? 0.0;
    }

    double lateAmount = 0;
    for (var payment in _kpiData['late']) {
      lateAmount += payment['paid_amount'] ?? 0.0;
    }

    return onTimeAmount + lateAmount;
  }

  // Calcular total de pagos esperados
  double getTotalExpectedAmount() {
    double total = 0;
    for (var payment in _kpiData['total']) {
      total += payment['payment_amount'] ?? 0.0;
    }
    return total;
  }

  // Calcular porcentaje de avance
  double getProgressPercentage() {
    final totalExpected = getTotalExpectedAmount();
    if (totalExpected == 0) return 0;

    return getTotalPaidAmount() / totalExpected;
  }

  // Obtener número de pagos a tiempo
  int getOnTimePaymentsCount() {
    return _kpiData['onTime'].length;
  }

  // Obtener número de pagos atrasados
  int getLatePaymentsCount() {
    return _kpiData['late'].length;
  }

  // Obtener número total de pagos
  int getTotalPaymentsCount() {
    return _kpiData['total'].length;
  }
}
