import 'package:flutter/material.dart';
import '../services/supervisor_service.dart';

class SupervisorProvider extends ChangeNotifier {
  final SupervisorService _supervisorService = SupervisorService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _gestores = [];
  Map<String, dynamic>? _selectedGestorKPIs;
  bool _isInitialized = false;
  String? _selectedGestorId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _clientLocations = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get gestores => _gestores;
  Map<String, dynamic>? get selectedGestorKPIs => _selectedGestorKPIs;
  bool get isInitialized => _isInitialized;
  String? get selectedGestorId => _selectedGestorId;
  DateTime get selectedDate => _selectedDate;
  List<Map<String, dynamic>> get clientLocations => _clientLocations;

  // Setters
  set selectedGestorId(String? id) {
    _selectedGestorId = id;
    if (id != null) {
      loadGestorKPIs(id, _selectedDate);
    } else {
      _selectedGestorKPIs = null;
      _clientLocations = [];
      notifyListeners();
    }
  }

  set selectedDate(DateTime date) {
    _selectedDate = date;
    if (_selectedGestorId != null) {
      loadGestorKPIs(_selectedGestorId!, date);
    }
    notifyListeners();
  }

  // Métodos para obtener la información formateada
  double get progressPercentage {
    if (_selectedGestorKPIs == null) return 0.0;
    return _selectedGestorKPIs!['efficiency'] ?? 0.0;
  }

  int getPendingPaymentsCount() {
    if (_selectedGestorKPIs == null) return 0;
    return _selectedGestorKPIs!['pending_count'] ?? 0;
  }

  int getCompletedPaymentsCount() {
    if (_selectedGestorKPIs == null) return 0;
    return _selectedGestorKPIs!['completed_count'] ?? 0;
  }

  double getTotalAmount() {
    if (_selectedGestorKPIs == null) return 0.0;
    return _selectedGestorKPIs!['total_amount'] ?? 0.0;
  }

  double getCollectedAmount() {
    if (_selectedGestorKPIs == null) return 0.0;
    return _selectedGestorKPIs!['collected_amount'] ?? 0.0;
  }

  // Métodos para cargar datos
  Future<void> loadGestores() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _gestores = await _supervisorService.getGestores();
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _gestores = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGestorKPIs(String gestorId, [DateTime? date]) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final targetDate = date ?? _selectedDate;
      _selectedGestorKPIs =
          await _supervisorService.getGestorKPIs(gestorId, targetDate);

      // Cargar también las ubicaciones de los clientes
      await loadGestorClientLocations(gestorId, targetDate);
    } catch (e) {
      _error = e.toString();
      _selectedGestorKPIs = null;
      _clientLocations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGestorClientLocations(String gestorId, DateTime date) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final locations =
          await _supervisorService.getGestorClientLocations(gestorId, date);
      _clientLocations = locations;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _clientLocations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _isLoading = false;
    _error = null;
    _gestores = [];
    _selectedGestorKPIs = null;
    _isInitialized = false;
    _selectedGestorId = null;
    _clientLocations = [];
    notifyListeners();
  }

  String? getGestorName(String gestorId) {
    final gestor = _gestores.firstWhere(
      (g) => g['id'] == gestorId,
      orElse: () => {'name': 'Desconocido'},
    );
    return gestor['name'];
  }
}
