import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:yatha_app/providers/auth_provider.dart';
import 'package:yatha_app/providers/loan_provider.dart';
import 'package:yatha_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/providers/cliente_provider.dart';
import 'package:yatha_app/models/loan.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          body: RefreshIndicator(
            onRefresh: _loadLoans,
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre de cliente...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchLoans('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: _searchLoans,
                      ),
                    ),
                    Expanded(
                      child: _buildLoanList(clienteProvider),
                    ),
                  ],
                ),
                if (clienteProvider.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanList(ClienteProvider clienteProvider) {
    if (clienteProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              clienteProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (clienteProvider.loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching && _searchController.text.isNotEmpty
                  ? 'No se encontraron préstamos para "${_searchController.text}"'
                  : 'No hay préstamos para mostrar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clienteProvider.loans.length,
      itemBuilder: (context, index) {
        final loan = clienteProvider.loans[index];
        final clientName = loan['partner_id'] is List
            ? loan['partner_id'][1]
            : 'Cliente sin nombre';
        final amount = loan['loan_amount'] ?? 0.0;
        final status = loan['loan_status'] ?? 'pending';
        final paymentPeriod = loan['payment_period'] ?? 'daily';
        final loanId = loan['id']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Get.toNamed(
                '/loan-detail',
                arguments: {'loanId': loanId},
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final loanProvider =
                        Provider.of<LoanProvider>(context, listen: false);
                    final loanObject = Loan.fromJson(loan);
                    loanProvider.selectLoan(loanObject);
                    Get.toNamed(
                      '/loan-detail',
                      arguments: {'loanId': loanId},
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.colorScheme.primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  clientName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.colorScheme.primary,
                                    fontSize: 20,
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: paymentPeriod == 'daily'
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.purple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          paymentPeriod == 'daily'
                                              ? 'Diario'
                                              : 'Mensual',
                                          style: TextStyle(
                                            color: paymentPeriod == 'daily'
                                                ? Colors.blue
                                                : Colors.purple,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Monto del préstamo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/.${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'pending'
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: status == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status == 'pending' ? 'Pendiente' : 'Pagado',
                                style: TextStyle(
                                  color: status == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
}
