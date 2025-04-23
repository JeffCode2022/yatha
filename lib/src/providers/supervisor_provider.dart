import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../services/supervisor_service.dart';
import 'package:yatha_app/src/models/gestor.dart';

class SupervisorProvider with ChangeNotifier {
  final SupervisorService _service = SupervisorService();

  List<Gestor> _gestores = [];
  Gestor? _selectedGestor;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _clientLocations = [];
  Map<String, dynamic> _kpiData = {};
  bool _disposed = false;

  // Getters
  List<Gestor> get gestores => _gestores;
  Gestor? get selectedGestor => _selectedGestor;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get clientLocations => _clientLocations;
  Map<String, dynamic> get kpiData => _kpiData;

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
  void setSelectedGestor(Gestor? gestor) {
    if (gestor != _selectedGestor) {
      _selectedGestor = gestor;
      _safeNotifyListeners();
      loadKpis();
    }
  }

  void setSelectedDate(DateTime date) {
    if (date != _selectedDate) {
      _selectedDate = date;
      _safeNotifyListeners();
      loadKpis();
    }
  }

  // Métodos para obtener la información formateada
  double get progressPercentage {
    if (_selectedGestor == null) return 0.0;
    return _kpiData['efficiency'] ?? 0.0;
  }

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
          _selectedDate,
        );

        // Cargar también las ubicaciones de los clientes
        await loadGestorClientLocations(_selectedGestor!.id, _selectedDate);
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
    if (_isLoading) return;

    try {
      _isLoading = true;
      _safeNotifyListeners();

      final locations = await _service.getGestorClientLocations(gestorId, date);
      if (!_disposed) {
        _clientLocations = locations;
        _errorMessage = null;
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = e.toString();
        _clientLocations = [];
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
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
}
