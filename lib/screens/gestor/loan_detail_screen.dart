import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/payment_modal.dart';

class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({Key? key}) : super(key: key);

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar pagos del préstamo al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoanPayments();
    });
  }

  void _loadLoanPayments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.user?.uid != null && loanProvider.selectedLoan != null) {
      await loanProvider.fetchLoanPayments(
        authProvider.user!.uid,
        loanProvider.selectedLoan!['name'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanProvider, AuthProvider>(
      builder: (context, loanProvider, authProvider, _) {
        final loan = loanProvider.selectedLoan;

        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de préstamo')),
            body: const Center(
              child: Text('No se ha seleccionado ningún préstamo'),
            ),
          );
        }

        final clientName = loan['partner_id'] is List
            ? loan['partner_id'][1]
            : 'Cliente sin nombre';
        final loanName = loan['name'] ?? 'Préstamo sin nombre';
        final amount = loan['loan_amount'] ?? 0.0;
        final paymentParts = loan['payment_parts'] ?? 0;
        final paymentPeriod = loan['payment_period'] ?? 'unknown';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle de préstamo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLoanPayments,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del préstamo
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.colorScheme.primaryContainer.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              AppTheme.colorScheme.primaryContainer,
                          child: Text(
                            clientName.isNotEmpty
                                ? clientName[0].toUpperCase()
                                : 'C',
                            style: TextStyle(
                              color: AppTheme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Préstamo #$loanName',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Monto',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'S/. $amount',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tipo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      paymentPeriod == 'monthly'
                                          ? 'Mensual'
                                          : 'Diario',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cuotas Pendientes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${loanProvider.loanPayments.where((p) => p['payment_status'] != 'paid').length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cuotas Pagadas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${loanProvider.loanPayments.where((p) => p['payment_status'] == 'paid').length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Título de sección de cuotas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Cuotas del préstamo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${loanProvider.loanPayments.length} cuotas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Lista de cuotas
              Expanded(
                child: loanProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : loanProvider.loanPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay cuotas disponibles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: loanProvider.loanPayments.length,
                            itemBuilder: (context, index) {
                              final payment = loanProvider.loanPayments[index];
                              return _buildPaymentCard(
                                context,
                                payment,
                                paymentPeriod,
                                authProvider.user?.uid,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    dynamic payment,
    String paymentPeriod,
    int? uid,
  ) {
    final paymentId = payment['id'];
    final paymentDate = payment['payment_date'] ?? 'Sin fecha';
    final paymentAmount = payment['payment_amount'] ?? 0.0;
    final status = payment['payment_status'] ?? 'pending';
    final isPaid = status == 'paid';

    // Convertir status a texto y color
    String statusText;
    Color statusColor;
    switch (status) {
      case 'paid':
        statusText = 'Pagado';
        statusColor = Colors.green;
        break;
      case 'on_time':
        statusText = 'Pendiente';
        statusColor = Colors.orange;
        break;
      case 'late':
        statusText = 'Atrasado';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Pendiente';
        statusColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Círculo con check o número
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
              child: Center(
                child: isPaid
                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                    : Text(
                        (payment['name'] ?? '').toString().split('/').last,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Información de la cuota
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha: $paymentDate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\S/.${paymentAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de cobrar
            if (!isPaid)
              ElevatedButton(
                onPressed: () {
                  _showPaymentModal(context, payment, paymentPeriod, uid);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cobrar'),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentModal(
    BuildContext context,
    dynamic payment,
    String paymentPeriod,
    int? uid,
  ) {
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        payment: payment,
        paymentPeriod: paymentPeriod,
        uid: uid,
        onPaymentComplete: () {
          // Recargar pagos después de registrar uno
          _loadLoanPayments();
        },
      ),
    );
  }
}
