import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class LoanProvider with ChangeNotifier {
  List<dynamic> _monthlyLoans = [];
  List<dynamic> _dailyLoans = [];
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedLoan;
  List<dynamic> _loanPayments = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<dynamic> get monthlyLoans => _monthlyLoans;
  List<dynamic> get dailyLoans => _dailyLoans;
  List<dynamic> get searchResults => _searchResults;
  Map<String, dynamic>? get selectedLoan => _selectedLoan;
  List<dynamic> get loanPayments => _loanPayments;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Función para obtener los préstamos mensuales
  Future<void> fetchMonthlyLoans(int uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().getAssignedLoans(uid, "monthly");

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _monthlyLoans = [];
      } else {
        _monthlyLoans = response['result'] ?? [];
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar préstamos mensuales: $e';
      _monthlyLoans = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Función para obtener los préstamos diarios
  Future<void> fetchDailyLoans(int uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().getAssignedLoans(uid, "daily");

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _dailyLoans = [];
      } else {
        _dailyLoans = response['result'] ?? [];
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar préstamos diarios: $e';
      _dailyLoans = [];
    }

    _isLoading = false;
    notifyListeners();
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
      } else {
        _searchResults = response['result'] ?? [];
        _errorMessage = null;
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
  void selectLoan(Map<String, dynamic> loan) {
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
}
