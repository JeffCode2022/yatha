import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:yatha_app/src/providers/auth_provider.dart';
import 'package:yatha_app/src/providers/loan_provider.dart';
import 'package:yatha_app/utils/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/src/providers/cliente_provider.dart';
import 'package:yatha_app/src/models/loan.dart';
import 'package:yatha_app/src/routes/app_routes.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clienteProvider =
          Provider.of<ClienteProvider>(context, listen: false);

      if (authProvider.user?.uid != null) {
        await clienteProvider.fetchLoans(
          authProvider.user!.uid.toString(),
          _selectedDate,
        );
      }
    } catch (e) {
      print('Error al cargar préstamos: $e');
    }
  }

  void _searchLoans(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.uid != null) {
        await Provider.of<ClienteProvider>(context, listen: false)
            .fetchLoans(authProvider.user!.uid.toString(), _selectedDate);
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid != null) {
      await Provider.of<ClienteProvider>(
        context,
        listen: false,
      ).searchLoansByClientName(authProvider.user!.uid.toString(), query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, clienteProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Préstamos',
              style: TextStyle(
                color: AppTheme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: _loadLoans,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadLoans,
              color: AppTheme.colorScheme.primary,
              child: Stack(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child: _buildLoanList(clienteProvider),
                        ),
                      ],
                    ),
                  ),
                  if (clienteProvider.isLoading)
                    _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre de cliente...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
              size: 18,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchLoans('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _searchLoans,
        ),
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.7),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.colorScheme.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildLoanList(ClienteProvider clienteProvider) {
    if (clienteProvider.error != null) {
      return _buildErrorState(clienteProvider.error!);
    }

    if (clienteProvider.loans.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: clienteProvider.loans.length,
      itemBuilder: (context, index) {
        final loan = clienteProvider.loans[index];
        return _buildLoanCard(loan, index);
      },
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar préstamos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLoans,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSearching ? Icons.search_off : Icons.account_balance_wallet_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching && _searchController.text.isNotEmpty
                  ? 'No se encontraron préstamos'
                  : 'No hay préstamos para mostrar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchController.text.isNotEmpty
                  ? 'No hay resultados para "${_searchController.text}"'
                  : 'Aún no se han registrado préstamos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _searchLoans('');
                },
                icon: Icon(
                  Icons.clear,
                  size: 16,
                  color: AppTheme.colorScheme.primary,
                ),
                label: Text(
                  'Limpiar búsqueda',
                  style: TextStyle(
                    color: AppTheme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoanCard(dynamic loan, int index) {
    final clientName = loan['partner_id'] is List
        ? loan['partner_id'][1]
        : 'Cliente sin nombre';
    final amount = loan['loan_amount'] ?? 0.0;
    final status = loan['loan_status'] ?? 'pending';
    final paymentPeriod = loan['payment_period'] ?? 'daily';
    final loanId = loan['id']?.toString() ?? '';
    
    // Animación de entrada escalonada
    final delay = Duration(milliseconds: 50 * index);
    
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToLoanDetail(loan, loanId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                                  style: TextStyle(
                                    color: AppTheme.colorScheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: paymentPeriod == 'daily'
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: paymentPeriod == 'daily'
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.purple.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          paymentPeriod == 'daily'
                                              ? 'Diario'
                                              : 'Mensual',
                                          style: TextStyle(
                                            color: paymentPeriod == 'daily'
                                                ? Colors.blue
                                                : Colors.purple,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'pending'
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: status == 'pending'
                                      ? Colors.orange.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status == 'pending' ? 'Pendiente' : 'Pagado',
                                style: TextStyle(
                                  color: status == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monto del préstamo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'S/.${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppTheme.colorScheme.primary,
                                ),
                                onPressed: () => _navigateToLoanDetail(loan, loanId),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: const EdgeInsets.all(8),
                                splashRadius: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _navigateToLoanDetail(dynamic loan, String loanId) {
    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);

      // Crear el objeto Loan
      final loanObject = Loan.fromJson(loan);

      // Seleccionar el préstamo en el provider
      loanProvider.selectLoan(loanObject);

      // Navegar a la pantalla de detalle
      Get.toNamed(
        AppRoutes.loanDetail,
        arguments: {'loanId': loanId},
      );
    } catch (e) {
      print('Error al abrir el préstamo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al abrir el préstamo: ${e.toString()}',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

