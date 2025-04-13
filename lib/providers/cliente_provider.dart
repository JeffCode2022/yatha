import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/cliente_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _filteredLoans = [];

  List<Map<String, dynamic>> get loans =>
      _filteredLoans.isNotEmpty ? _filteredLoans : _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLoans(String userId, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _clienteService.obtenerPrestamos(userId, date);
      _loans = response;
      _filteredLoans = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchLoansByClientName(String userId, String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _clienteService.obtenerPrestamos(
          userId, DateFormat('yyyy-MM-dd').format(DateTime.now()));

      if (response.isEmpty) {
        _error = 'No se encontraron préstamos para "$query"';
        _loans = [];
        _filteredLoans = [];
      } else {
        _loans = response;
        // Filtrar por nombre de cliente
        _filteredLoans = _loans.where((loan) {
          final clientName = loan['partner_id'] is List
              ? loan['partner_id'][1].toString().toLowerCase()
              : '';
          return clientName.contains(query.toLowerCase());
        }).toList();

        if (_filteredLoans.isEmpty) {
          _error = 'No se encontraron préstamos para "$query"';
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _filteredLoans = [];
    notifyListeners();
  }

  Future<void> loadClientes({DateTime? fecha}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final clientes = await _clienteService.obtenerClientes(fecha: fecha);
      _loans = clientes;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    if (!_isLoading) {
      notifyListeners();
    }
  }

  // Filtrar clientes por vendedor
  List<Map<String, dynamic>> filtrarPorVendedor(int vendedorId) {
    return _loans.where((cliente) {
      return cliente['partner_salesperson'] == vendedorId;
    }).toList();
  }

  // Obtener estadísticas de rendimiento por vendedor
  Map<String, dynamic> obtenerEstadisticasVendedor(int vendedorId) {
    final clientesVendedor = filtrarPorVendedor(vendedorId);
    return {
      'total_clientes': clientesVendedor.length,
      'clientes_activos':
          clientesVendedor.where((c) => c['estado'] == 'activo').length,
      'clientes_inactivos':
          clientesVendedor.where((c) => c['estado'] == 'inactivo').length,
    };
  }
}
