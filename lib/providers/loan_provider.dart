import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/loan.dart';

class LoanProvider with ChangeNotifier {
  List<Loan> _loans = [];
  List<Loan> _searchResults = [];
  Loan? _selectedLoan;
  List<dynamic> _loanPayments = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String _searchQuery = '';
  Map<String, int> _loanStats = {
    'total': 0,
    'active': 0,
    'pending': 0,
    'completed': 0,
  };

  // Getters
  List<Loan> get loans => _loans;
  List<Loan> get searchResults => _searchResults;
  Loan? get selectedLoan => _selectedLoan;
  List<dynamic> get loanPayments => _loanPayments;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  Map<String, int> get loanStats => _loanStats;

  // Función unificada para obtener préstamos
  Future<void> fetchLoans(int uid, String paymentPeriod) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().getAssignedLoans(uid, paymentPeriod);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _loans = [];
      } else if (response.containsKey('success') && response['success']) {
        final loansList = response['loans'] ?? [];
        _loans = loansList.map<Loan>((loan) => Loan.fromJson(loan)).toList();
        _updateLoanStats();
        _errorMessage = null;
      } else {
        _errorMessage = 'Formato de respuesta inválido';
        _loans = [];
      }
    } catch (e) {
      _errorMessage = 'Error al cargar préstamos: $e';
      _loans = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Actualizar estadísticas de préstamos
  void _updateLoanStats() {
    _loanStats = {
      'total': _loans.length,
      'active': _loans.where((loan) => loan.status == 'active').length,
      'pending': _loans.where((loan) => loan.status == 'pending').length,
      'completed': _loans.where((loan) => loan.status == 'completed').length,
    };
  }

  // Función para buscar préstamos por nombre de cliente
  Future<void> searchLoansByClientName(int uid, String clientName) async {
    _isSearching = true;
    _searchQuery = clientName;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiService().searchLoansByClientName(uid, clientName);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _searchResults = [];
      } else if (response.containsKey('success') && response['success']) {
        final loansList = response['loans'] ?? [];
        _searchResults =
            loansList.map<Loan>((loan) => Loan.fromJson(loan)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Formato de respuesta inválido';
        _searchResults = [];
      }
    } catch (e) {
      _errorMessage = 'Error al buscar préstamos: $e';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Función para limpiar la búsqueda
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  // Función para seleccionar un préstamo
  void selectLoan(Loan loan) {
    _selectedLoan = loan;
    notifyListeners();
  }

  // Función para obtener los pagos de un préstamo
  Future<void> fetchLoanPayments(int uid, String loanId) async {
    _isLoading = true;
    _errorMessage = null;
    _loanPayments = [];
    notifyListeners();

    try {
      final response = await ApiService().getLoanPayments(uid, loanId);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _loanPayments = [];
      } else {
        _loanPayments = response['result'] ?? [];
        // Ordenar los pagos por fecha
        _loanPayments.sort((a, b) =>
            a['payment_date'] != null && b['payment_date'] != null
                ? a['payment_date'].compareTo(b['payment_date'])
                : 0);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar pagos: $e';
      _loanPayments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Limpiar datos seleccionados
  void clearSelectedLoan() {
    _selectedLoan = null;
    _loanPayments = [];
    notifyListeners();
  }

  // Método para limpiar todos los datos
  void clearData() {
    _loans = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
