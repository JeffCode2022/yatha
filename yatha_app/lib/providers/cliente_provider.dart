import 'package:flutter/foundation.dart';
import '../services/cliente_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  List<Map<String, dynamic>> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarClientes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clientes = await _clienteService.obtenerClientes();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Filtrar clientes por vendedor
  List<Map<String, dynamic>> filtrarPorVendedor(int vendedorId) {
    return _clientes
        .where((cliente) => cliente['vendedor_id'] == vendedorId)
        .toList();
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
