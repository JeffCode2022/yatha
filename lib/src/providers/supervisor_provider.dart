import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../services/supervisor_service.dart';
import 'package:yatha_app/src/models/gestor.dart';
import '../services/supervisor_map_service.dart';

class SupervisorProvider with ChangeNotifier {
  final SupervisorService _service = SupervisorService();
  final SupervisorMapService _mapService = SupervisorMapService();

  List<Gestor> _gestores = [];
  Gestor? _selectedGestor;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _clientLocations = [];
  Map<String, dynamic> _kpiData = {};
  bool _disposed = false;

  // Variables para préstamos diarios
  List<Map<String, dynamic>> _dailyLoans = [];
  double _totalDisbursed = 0.0;
  double _totalInterest = 0.0;
  double _totalToCollect = 0.0;
  double _expectedAmount = 0.0;
  double _efficiencyPercentage = 0.0;
  double _paymentAmount = 0.0; // Nuevo: monto por cuota
  bool _isLoadingDailyLoans = false;
  DateTime _selectedDate = DateTime.now();

  // Variables para KPIs por rango
  Map<String, dynamic> _rangeKpis = {};
  bool _isLoadingRange = false;
  double _rangeEfficiencyPercentage = 0.0;
  double _rangeExpectedAmount = 0.0;

  // Getters
  List<Gestor> get gestores => _gestores;
  Gestor? get selectedGestor => _selectedGestor;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get clientLocations => _clientLocations;
  Map<String, dynamic> get kpiData => _kpiData;
  List<Map<String, dynamic>> get dailyLoans => _dailyLoans;
  double get totalDisbursed => _totalDisbursed;
  double get totalInterest => _totalInterest;
  double get totalToCollect => _totalToCollect;
  double get expectedAmount => _expectedAmount;
  double get efficiencyPercentage => _efficiencyPercentage;
  double get paymentAmount => _paymentAmount; // Nuevo getter
  bool get isLoadingDailyLoans => _isLoadingDailyLoans;
  DateTime get selectedDate => _selectedDate;

  // Totales calculados
  double get totalAmount => _totalToCollect;
  double get efficiency => 1.0; // Siempre 100% el primer día

  // Getters para la barra de eficiencia
  double get startAmount => 0.0;
  double get endAmount => _expectedAmount;
  double get currentProgress => _totalToCollect;
  double get progressPercentage => _efficiencyPercentage;

  // Getters para KPIs por rango
  Map<String, dynamic> get rangeKpis => _rangeKpis;
  bool get isLoadingRange => _isLoadingRange;
  double get rangeEfficiencyPercentage => _rangeEfficiencyPercentage;
  double get rangeTotalAmount => _rangeKpis['total_amount']?.toDouble() ?? 0.0;
  double get rangeCollectedAmount =>
      _rangeKpis['collected_amount']?.toDouble() ?? 0.0;
  int get rangePendingCount => _rangeKpis['pending_count']?.toInt() ?? 0;
  int get rangeCompletedCount => _rangeKpis['completed_count']?.toInt() ?? 0;
  double get rangeExpectedAmount => _rangeExpectedAmount;

  // Nuevo getter para pagos a tiempo
  int get onTimePaymentsCount => _rangeKpis['on_time_payments']?.toInt() ?? 0;
  double get onTimePaymentsPercentage {
    final total = rangeCompletedCount + rangePendingCount;
    if (total == 0) return 0.0;
    return (onTimePaymentsCount / total) * 100;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  // Setters
  void setSelectedGestor(Gestor gestor) {
    _selectedGestor = gestor;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    if (start != _startDate || end != _endDate) {
      _startDate = start;
      _endDate = end;
      if (_selectedGestor != null) {
        loadRangeKpis(_startDate, _endDate);
        loadDailyLoans();
      }
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadDailyLoans();
  }

  // Métodos para obtener la información formateada
  int getPendingPaymentsCount() {
    if (_selectedGestor == null) return 0;
    return _kpiData['pending_count'] ?? 0;
  }

  int getCompletedPaymentsCount() {
    if (_selectedGestor == null) return 0;
    return _kpiData['completed_count'] ?? 0;
  }

  double getTotalAmount() {
    if (_selectedGestor == null) return 0.0;
    return _kpiData['total_amount'] ?? 0.0;
  }

  double getCollectedAmount() {
    if (_selectedGestor == null) return 0.0;
    return _kpiData['collected_amount'] ?? 0.0;
  }

  double getTotalPaid() {
    if (_selectedGestor == null) return 0.0;
    double totalPaid = 0.0;

    // Sumar los montos pagados de todos los pagos
    if (_kpiData['payments'] != null) {
      for (var payment in _kpiData['payments']) {
        totalPaid += (payment['paid_amount'] ?? 0.0).toDouble();
      }
    }

    return totalPaid;
  }

  // Métodos para cargar datos
  Future<void> loadGestores() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final gestoresData = await _service.getGestores();
      if (!_disposed) {
        _gestores = gestoresData.map((data) => Gestor.fromJson(data)).toList();

        if (_gestores.isNotEmpty && _selectedGestor == null) {
          _selectedGestor = _gestores.first;
          await loadKpis();
        }
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Error al cargar los gestores: ${e.toString()}';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> loadKpis() async {
    if (_selectedGestor == null || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      if (!_disposed) {
        _kpiData = await _service.getGestorKPIs(
          _selectedGestor!.id,
          _startDate,
          _endDate,
        );

        // Cargar también las ubicaciones de los clientes
        await loadGestorClientLocations(_selectedGestor!.id, _endDate);
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Error al cargar los KPIs: ${e.toString()}';
        _kpiData = {};
        _clientLocations = [];
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> loadGestorClientLocations(String gestorId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('Cargando ubicaciones para gestor: $gestorId en fecha: $date');
      final locations = await _service.getGestorClientLocations(gestorId, date);

      _clientLocations = locations;
      _isLoading = false;
      notifyListeners();

      if (locations.isEmpty) {
        print('No se encontraron ubicaciones para el gestor');
      } else {
        print('Se encontraron ${locations.length} ubicaciones');
      }
    } catch (e) {
      print('Error al cargar ubicaciones: $e');
      _errorMessage = 'Error al cargar las ubicaciones: $e';
      _isLoading = false;
      _clientLocations = [];
      notifyListeners();
    }
  }

  Future<void> loadMapLocations(String gestorId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print(
          'Cargando ubicaciones del mapa para gestor: $gestorId en fecha: $date');
      final locations = await _service.getMapLocations(gestorId, date);

      _clientLocations = locations;
      _isLoading = false;
      notifyListeners();

      if (locations.isEmpty) {
        print('No se encontraron ubicaciones en el mapa para el gestor');
      } else {
        print('Se encontraron ${locations.length} ubicaciones en el mapa');
      }
    } catch (e) {
      print('Error al cargar ubicaciones del mapa: $e');
      _errorMessage = 'Error al cargar las ubicaciones del mapa: $e';
      _isLoading = false;
      _clientLocations = [];
      notifyListeners();
    }
  }

  Future<void> loadMapPendingClients(String gestorId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      final locations = await _mapService.getPendingClientsForGestorAndDate(
        gestorId: gestorId,
        date: date,
      );
      _clientLocations = locations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar ubicaciones del mapa: $e';
      _isLoading = false;
      _clientLocations = [];
      notifyListeners();
    }
  }

  void clearData() {
    if (_disposed) return;

    _gestores = [];
    _selectedGestor = null;
    _kpiData = {};
    _errorMessage = null;
    _clientLocations = [];
    _safeNotifyListeners();
  }

  String? getGestorName(String gestorId) {
    try {
      final gestor = _gestores.firstWhere((g) => g.id == gestorId);
      return gestor.name;
    } catch (e) {
      return 'Desconocido';
    }
  }

  Future<void> loadDailyLoans() async {
    if (_selectedGestor == null) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _service.getDailyLoans(
        _startDate,
        _endDate,
        _selectedGestor!.id, // Pasar el ID del gestor seleccionado
      );
      print('Respuesta del endpoint: $response');

      if (response != null && response['result'] != null) {
        _dailyLoans = List<Map<String, dynamic>>.from(response['result']);
        print('Préstamos cargados: [32m[1m[4m${_dailyLoans.length}[0m');

        if (_dailyLoans.isNotEmpty) {
          // Calcular totales para el gestor seleccionado
          _totalDisbursed = _dailyLoans.fold(
              0.0, (sum, loan) => sum + (loan['loan_amount'] ?? 0.0));
          _totalInterest = _dailyLoans.fold(
              0.0, (sum, loan) => sum + (loan['profit'] ?? 0.0));
          _totalToCollect = _dailyLoans.fold(
              0.0, (sum, loan) => sum + (loan['total_amount'] ?? 0.0));

          // El monto esperado es el monto total a cobrar
          _expectedAmount = _totalToCollect;

          // La eficiencia se calcula como: monto desembolsado / (monto esperado + 20%)
          final double targetAmount = _expectedAmount * 1.2;
          _efficiencyPercentage = targetAmount > 0
              ? (_totalDisbursed / targetAmount).clamp(0.0, 1.0)
              : 0.0;

          print('Totales calculados para el gestor ${_selectedGestor!.name}:');
          print('- Total préstamos: ${_dailyLoans.length}');
          print('- Total desembolsado: $_totalDisbursed');
          print('- Total interés: $_totalInterest');
          print('- Total a cobrar: $_totalToCollect');
          print('- Monto esperado: $_expectedAmount');
          print('- Monto objetivo (120%): $targetAmount');
          print('- Eficiencia actual: ${_efficiencyPercentage * 100}%');
        } else {
          _resetTotals();
        }
      } else {
        _dailyLoans = [];
        _resetTotals();
        print(
            'No se encontraron préstamos para el gestor ${_selectedGestor!.name}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print(
          'Error al cargar préstamos del gestor ${_selectedGestor!.name}: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      _dailyLoans = [];
      _resetTotals();
      notifyListeners();
    }
  }

  void _resetTotals() {
    _totalDisbursed = 0.0;
    _totalInterest = 0.0;
    _totalToCollect = 0.0;
    _expectedAmount = 0.0;
    _efficiencyPercentage = 0.0;
    _paymentAmount = 0.0;
  }

  Future<void> loadRangeKpis(DateTime startDate, DateTime endDate) async {
    if (_selectedGestor == null) return;

    try {
      _isLoadingRange = true;
      notifyListeners();

      final response = await _service.getGestorKPIs(
        _selectedGestor!.id,
        startDate,
        endDate,
      );

      if (response != null) {
        _rangeKpis = response;

        // Calcular el monto esperado y la eficiencia para el rango
        final double totalAmount = _rangeKpis['total_amount'] ?? 0.0;
        final double collectedAmount = _rangeKpis['collected_amount'] ?? 0.0;

        // El monto esperado es el total amount
        _rangeExpectedAmount = totalAmount;

        // La eficiencia se calcula como: monto recaudado / monto esperado
        _rangeEfficiencyPercentage = _rangeExpectedAmount > 0
            ? (collectedAmount / _rangeExpectedAmount)
            : 0.0;

        // Procesar los pagos para calcular los pagos a tiempo
        if (_rangeKpis['payments'] != null) {
          int onTimeCount = 0;
          for (var payment in _rangeKpis['payments']) {
            if (payment['status'] == 'paid' ||
                payment['status'] == 'completed') {
              // Verificar si el pago fue realizado a tiempo
              final paymentDate = DateTime.parse(payment['payment_date'] ?? '');
              final actualPaymentDate = payment['actual_payment_date'] != null
                  ? DateTime.parse(payment['actual_payment_date'])
                  : null;

              if (actualPaymentDate != null &&
                  (actualPaymentDate.isBefore(paymentDate) ||
                      actualPaymentDate.isAtSameMomentAs(paymentDate))) {
                onTimeCount++;
              }
            }
          }
          _rangeKpis['on_time_payments'] = onTimeCount;
        } else {
          _rangeKpis['on_time_payments'] = 0;
        }

        print('Range expected amount: $_rangeExpectedAmount');
        print('Range collected amount: $collectedAmount');
        print(
            'Range efficiency percentage: ${_rangeEfficiencyPercentage * 100}%');
        print('On-time payments: ${_rangeKpis['on_time_payments']}');
        print('On-time payments percentage: ${onTimePaymentsPercentage}%');
      } // No llamar a _resetRangeData() si la respuesta es vacía pero válida
      else {
        _resetRangeData();
      }

      _isLoadingRange = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar KPIs por rango: $e');
      _resetRangeData();
      _isLoadingRange = false;
      notifyListeners();
    }
  }

  void _resetRangeData() {
    _rangeKpis = {
      'total_amount': 0.0,
      'collected_amount': 0.0,
      'pending_count': 0,
      'completed_count': 0,
      'on_time_payments': 0
    };
    _rangeEfficiencyPercentage = 0.0;
    _rangeExpectedAmount = 0.0;
  }

  void clearRangeData() {
    _rangeKpis = {};
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
