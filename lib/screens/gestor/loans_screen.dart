import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/providers/auth_provider.dart';
import 'package:yatha_app/providers/loan_provider.dart';
import 'package:yatha_app/theme/app_theme.dart';
import 'package:yatha_app/widgets/status_badge.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cargar préstamos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLoans() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.user?.uid != null) {
      await loanProvider.fetchMonthlyLoans(authProvider.user!.uid);
      await loanProvider.fetchDailyLoans(authProvider.user!.uid);
    }
  }

  void _searchLoans(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      Provider.of<LoanProvider>(context, listen: false).clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid != null) {
      await Provider.of<LoanProvider>(
        context,
        listen: false,
      ).searchLoansByClientName(authProvider.user!.uid, query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanProvider, AuthProvider>(
      builder: (context, loanProvider, authProvider, _) {
        List<dynamic> loans = [];

        if (_isSearching && loanProvider.searchQuery.isNotEmpty) {
          loans = loanProvider.searchResults;
        } else {
          loans = [...loanProvider.monthlyLoans, ...loanProvider.dailyLoans];
        }

        return Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
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
                ),
                onChanged: (value) {
                  if (value.length > 2) {
                    _searchLoans(value);
                  } else if (value.isEmpty) {
                    _searchLoans('');
                  }
                },
              ),
            ),

            // Etiqueta de resultados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    _isSearching
                        ? 'Resultados para "${loanProvider.searchQuery}"'
                        : 'Préstamos Asignados',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${loans.length} préstamos',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Lista de préstamos
            Expanded(
              child:
                  loanProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : loans.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No se encontraron préstamos'
                                  : 'No tienes préstamos asignados',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadLoans,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: () async => _loadLoans(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            return _buildLoanCard(loan);
                          },
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    // Extraer información del préstamo
    final loanId = loan['id'] as int;
    final clientName =
        loan['partner_id'] is List
            ? loan['partner_id'][1]
            : loan['partner_name'] ?? 'Cliente Desconocido';
    final loanNumber = loan['name'] ?? loanId.toString();
    final amount = loan['loan_amount'] ?? 0.0;
    final status = loan['loan_status'] ?? 'draft';
    final paymentPeriod = loan['payment_period'] ?? 'unknown';

    // Convertir estado a texto en español
    String statusText;
    Color statusColor;
    switch (status) {
      case 'draft':
        statusText = 'Borrador';
        statusColor = Colors.grey;
        break;
      case 'open':
        statusText = 'Abierto';
        statusColor = Colors.blue;
        break;
      case 'paid':
        statusText = 'Pagado';
        statusColor = Colors.green;
        break;
      case 'closed':
        statusText = 'Cerrado';
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusText = 'Cancelado';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Pendiente';
        statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Provider.of<LoanProvider>(context, listen: false).selectLoan(loan);
          Navigator.pushNamed(context, '/loan-detail');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar con iniciales del cliente
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.colorScheme.primaryContainer,
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                      style: TextStyle(
                        color: AppTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Información del cliente y préstamo
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Préstamo #$loanNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Monto y tipo de préstamo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\S/.${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              paymentPeriod == 'monthly'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentPeriod == 'monthly' ? 'Mensual' : 'Diario',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                paymentPeriod == 'monthly'
                                    ? Colors.blue
                                    : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Fila inferior con estado y botón
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<LoanProvider>(
                        context,
                        listen: false,
                      ).selectLoan(loan);
                      Navigator.pushNamed(context, '/loan-detail');
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorScheme.primaryContainer,
                      foregroundColor: AppTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
