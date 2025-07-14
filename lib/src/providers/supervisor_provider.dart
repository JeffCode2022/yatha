import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../services/supervisor_service.dart';
import 'package:yatha_app/src/models/gestor.dart';
import '../services/supervisor_map_service.dart';
import 'package:intl/intl.dart';

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
  DateTime _selectedDate = DateTime.now();

  // Variables para KPIs por rango
  Map<String, dynamic> _rangeKpis = {};
  bool _isLoadingRange = false;
  double _rangeEfficiencyPercentage = 0.0;
  double _rangeExpectedAmount = 0.0;

  // --- NUEVO: Pagos pendientes filtrados igual que gestor ---
  List<Map<String, dynamic>> _gestorPendingPayments = [];
  List<Map<String, dynamic>> get gestorPendingPayments =>
      _gestorPendingPayments;

  // --- NUEVO: Estado específico para el mapa del supervisor ---
  Gestor? _mapSelectedGestor;
  DateTime _mapSelectedDate = DateTime.now();
  bool _isLoadingMap = false;
  String? _mapErrorMessage;
  List<Map<String, dynamic>> _mapLocations = [];
  Map<String, dynamic>? _gestorLocation;
  bool _mapDataLoaded = false;

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
  DateTime get selectedDate => _selectedDate;

  // --- NUEVO: Getters específicos para el mapa ---
  Gestor? get mapSelectedGestor => _mapSelectedGestor;
  DateTime get mapSelectedDate => _mapSelectedDate;
  bool get isLoadingMap => _isLoadingMap;
  String? get mapErrorMessage => _mapErrorMessage;
  List<Map<String, dynamic>> get mapLocations => _mapLocations;
  Map<String, dynamic>? get gestorLocation => _gestorLocation;
  bool get mapDataLoaded => _mapDataLoaded;

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

  List<Map<String, dynamic>> _gestorPendingPaymentsInRange = [];
  List<Map<String, dynamic>> get gestorPendingPaymentsInRange =>
      _gestorPendingPaymentsInRange;

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

  // --- NUEVO: Setters específicos para el mapa ---
  void setMapSelectedGestor(Gestor gestor) {
    _mapSelectedGestor = gestor;
    _mapDataLoaded = false; // Resetear estado de datos cargados
    notifyListeners();
  }

  void setMapSelectedDate(DateTime date) {
    _mapSelectedDate = date;
    _mapDataLoaded = false; // Resetear estado de datos cargados
    notifyListeners();
  }

  void clearMapData() {
    _mapLocations = [];
    _gestorLocation = null;
    _mapDataLoaded = false;
    _mapErrorMessage = null;
    notifyListeners();
  }

  void clearMapError() {
    _mapErrorMessage = null;
    notifyListeners();
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

      final locations = await _service.getGestorClientLocations(gestorId, date);

      _clientLocations = locations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar ubicaciones: $e';
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

      final locations = await _service.getMapLocations(gestorId, date);

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

  Future<void> loadMapPendingClients(String gestorId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cargar clientes pendientes
      final clientLocations =
          await _mapService.getPendingClientsForGestorAndDate(
        gestorId: gestorId,
        date: date,
      );

      // Cargar ubicación del gestor
      final gestorLocation = await _mapService.getGestorLocation(gestorId);

      // Combinar clientes y gestor en una sola lista
      _clientLocations = [...clientLocations];
      if (gestorLocation != null) {
        _clientLocations.add(gestorLocation);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar ubicaciones del mapa: $e';
      _isLoading = false;
      _clientLocations = [];
      notifyListeners();
    }
  }

  // --- NUEVO: Método mejorado para cargar datos del mapa ---
  Future<void> loadMapData() async {
    if (_mapSelectedGestor == null) {
      _mapErrorMessage = 'No hay gestor seleccionado';
      notifyListeners();
      return;
    }

    try {
      _isLoadingMap = true;
      _mapErrorMessage = null;
      _mapDataLoaded = false;
      notifyListeners();

      print(
          '🔄 Cargando datos del mapa para gestor: ${_mapSelectedGestor!.name}');
      print(
          '📅 Fecha seleccionada: ${DateFormat('yyyy-MM-dd').format(_mapSelectedDate)}');

      // Cargar clientes pendientes
      final clientLocations =
          await _mapService.getPendingClientsForGestorAndDate(
        gestorId: _mapSelectedGestor!.id,
        date: _mapSelectedDate,
      );

      // Cargar ubicación del gestor
      final gestorLocation =
          await _mapService.getGestorLocation(_mapSelectedGestor!.id);

      // Validar y filtrar ubicaciones válidas
      final validClientLocations = _validateAndFilterLocations(clientLocations);

      // Combinar datos
      _mapLocations = [...validClientLocations];
      _gestorLocation = gestorLocation;

      if (gestorLocation != null) {
        _mapLocations.add(gestorLocation);
      }

      _mapDataLoaded = true;
      _isLoadingMap = false;

      print('✅ Datos del mapa cargados exitosamente');
      print('📍 Total de ubicaciones: ${_mapLocations.length}');
      print(
          '👤 Ubicación del gestor: ${gestorLocation != null ? 'Encontrada' : 'No encontrada'}');

      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar datos del mapa: $e');
      _mapErrorMessage = 'Error al cargar datos del mapa: $e';
      _isLoadingMap = false;
      _mapDataLoaded = false;
      _mapLocations = [];
      _gestorLocation = null;
      notifyListeners();
    }
  }

  // --- NUEVO: Método para validar y filtrar ubicaciones ---
  List<Map<String, dynamic>> _validateAndFilterLocations(
      List<Map<String, dynamic>> locations) {
    return locations.where((location) {
      final lat = location['latitude'];
      final lng = location['longitude'];

      // Validar que las coordenadas sean números válidos
      if (lat == null || lng == null) return false;

      final latDouble = lat is String
          ? double.tryParse(lat)
          : (lat is num ? lat.toDouble() : null);
      final lngDouble = lng is String
          ? double.tryParse(lng)
          : (lng is num ? lng.toDouble() : null);

      if (latDouble == null || lngDouble == null) return false;

      // Filtrar coordenadas inválidas (0.0, 0.0 está en el océano)
      if (latDouble == 0.0 && lngDouble == 0.0) return false;

      // Filtrar coordenadas muy pequeñas que podrían ser errores
      if (latDouble.abs() < 0.001 || lngDouble.abs() < 0.001) return false;

      // Actualizar las coordenadas como double para consistencia
      location['latitude'] = latDouble;
      location['longitude'] = lngDouble;

      return true;
    }).toList();
  }

  // --- NUEVO: Método para obtener estadísticas del mapa ---
  Map<String, dynamic> getMapStatistics() {
    if (!_mapDataLoaded) {
      return {
        'total_locations': 0,
        'valid_locations': 0,
        'gestor_location': false,
        'total_amount': 0.0,
        'pending_count': 0,
      };
    }

    final validLocations =
        _mapLocations.where((loc) => loc['is_gestor'] != true).toList();
    final totalAmount = validLocations.fold<double>(
        0.0, (sum, loc) => sum + (loc['amount'] ?? 0.0));
    final pendingCount =
        validLocations.where((loc) => loc['status'] == 'pending').length;

    return {
      'total_locations': _mapLocations.length,
      'valid_locations': validLocations.length,
      'gestor_location': _gestorLocation != null,
      'total_amount': totalAmount,
      'pending_count': pendingCount,
    };
  }

  // --- NUEVO: Método para recargar datos del mapa ---
  Future<void> refreshMapData() async {
    if (_mapSelectedGestor != null) {
      await loadMapData();
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

      if (response != null && response['result'] != null) {
        _dailyLoans = List<Map<String, dynamic>>.from(response['result']);

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
          _efficiencyPercentage = _totalDisbursed / targetAmount;
        } else {
          // Si no hay préstamos, todos los totales y eficiencia deben ser 0
          _totalDisbursed = 0.0;
          _totalInterest = 0.0;
          _totalToCollect = 0.0;
          _expectedAmount = 0.0;
          _efficiencyPercentage = 0.0;
        }
      } else {
        // Si la respuesta es nula o vacía, también poner todo en 0
        _dailyLoans = [];
        _totalDisbursed = 0.0;
        _totalInterest = 0.0;
        _totalToCollect = 0.0;
        _expectedAmount = 0.0;
        _efficiencyPercentage = 0.0;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar préstamos: $e';
      _dailyLoans = [];
      _totalDisbursed = 0.0;
      _totalInterest = 0.0;
      _totalToCollect = 0.0;
      _expectedAmount = 0.0;
      _efficiencyPercentage = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para obtener préstamos por sus IDs
  Future<List<Map<String, dynamic>>> getLoansByIds(
      List<dynamic> loanIds) async {
    try {
      final response = await _service.getLoansByIds(loanIds);
      if (response != null && response['result'] != null) {
        return List<Map<String, dynamic>>.from(response['result']);
      }
      return [];
    } catch (e) {
      return [];
    }
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
      } else {
        _resetRangeData();
      }

      _isLoadingRange = false;
      notifyListeners();
    } catch (e) {
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

  Future<void> fetchGestorPendingPayments(
      String gestorId, DateTime date) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();
      final pagos = await _service.getGestorPendingPayments(gestorId, date);
      _gestorPendingPayments = pagos;
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _gestorPendingPayments = [];
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchGestorPendingPaymentsInRange(
      String gestorId, DateTime start, DateTime end) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();
      final pagos =
          await _service.getGestorPendingPaymentsInRange(gestorId, start, end);
      _gestorPendingPaymentsInRange = pagos;
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _gestorPendingPaymentsInRange = [];
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // --- NUEVO: Imprimir pagos pendientes con coordenadas válidas ---
  Future<void> printPendingPaymentsWithCoordinates(
      String gestorId, DateTime date) async {
    // 1. Obtener pagos pendientes con los mismos filtros del KPI
    final pagos = await _service.getGestorPendingPayments(gestorId, date);

    // 2. Filtrar solo los que tienen coordenadas válidas
    final pagosConCoordenadas = pagos.where((pago) {
      final lat = pago['loan_id/partner_latitude'] ?? pago['partner_latitude'];
      final lng =
          pago['loan_id/partner_longitude'] ?? pago['partner_longitude'];
      if (lat == null || lng == null) return false;
      final latDouble = lat is String
          ? double.tryParse(lat)
          : (lat is num ? lat.toDouble() : null);
      final lngDouble = lng is String
          ? double.tryParse(lng)
          : (lng is num ? lng.toDouble() : null);
      if (latDouble == null || lngDouble == null) return false;
      if (latDouble == 0.0 && lngDouble == 0.0) return false;
      if (latDouble.abs() < 0.001 || lngDouble.abs() < 0.001) return false;
      return true;
    }).toList();

    // 3. Imprimir en consola la información relevante
    print(
        '--- Pagos pendientes con coordenadas válidas para el gestor $gestorId en ${date.toIso8601String().substring(0, 10)} ---');
    for (final pago in pagosConCoordenadas) {
      final cliente = pago['loan_id/partner_id'] != null
          ? pago['loan_id/partner_id'][1]
          : 'Sin nombre';
      final monto = pago['payment_amount'] ?? 0.0;
      final estado = pago['payment_status'] ?? 'pending';
      final lat = pago['loan_id/partner_latitude'] ?? pago['partner_latitude'];
      final lng =
          pago['loan_id/partner_longitude'] ?? pago['partner_longitude'];
      print(
          'Cliente: $cliente | Monto: $monto | Estado: $estado | Lat: $lat | Lng: $lng');
    }
    print(
        '--- Total: ${pagosConCoordenadas.length} pagos con coordenadas válidas ---');
  }

  // --- NUEVO: Cargar clientes pendientes para el mapa del supervisor (TODOS los gestores) ---
  Future<void> loadMapPendingClientsWithCoordinatesForSupervisor(
      DateTime date) async {
    try {
      _isLoadingMap = true;
      _mapErrorMessage = null;
      _mapDataLoaded = false;
      notifyListeners();

      // 1. Obtener pagos pendientes diarios con coordenadas válidas para la fecha seleccionada (todos los gestores)
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final pagos =
          await _service.getDailyPendingPaymentsWithCoordinatesForSupervisor(
        mapSelectedGestor?.id ?? '',
        formattedDate,
      );
      print('--- RESPUESTA CRUDA DEL ENDPOINT (pagos diarios supervisor) ---');
      for (final pago in pagos) {
        print(pago);
      }
      print('--- FIN RESPUESTA CRUDA (pagos diarios supervisor) ---');

      // 2. Filtrar y mapear los datos para el mapa
      final clientesConCoords = pagos
          .where((pago) {
            final lat = pago['latitude'];
            final lng = pago['longitude'];
            if (lat == null || lng == null) return false;
            if (lat == 0.0 && lng == 0.0) return false;
            if ((lat is num && lat.abs() < 0.001) ||
                (lng is num && lng.abs() < 0.001)) return false;
            return true;
          })
          .map((pago) => pago)
          .toList();

      print(
          'Clientes con coordenadas válidas tras filtrar (supervisor): ${clientesConCoords.length}');
      if (clientesConCoords.isEmpty) {
        print(
            'No hay clientes válidos tras filtrar, no se actualizará mapLocations.');
        _mapDataLoaded = true;
        _isLoadingMap = false;
        notifyListeners();
        return;
      }

      _mapLocations = [...clientesConCoords];
      _gestorLocation = null;
      _mapDataLoaded = true;
      _isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      _mapErrorMessage = 'Error al cargar datos del mapa: $e';
      _isLoadingMap = false;
      _mapDataLoaded = false;
      _mapLocations = [];
      _gestorLocation = null;
      notifyListeners();
    }
  }
}
