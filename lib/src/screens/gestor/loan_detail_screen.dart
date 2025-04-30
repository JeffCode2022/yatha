import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/loan_provider.dart';
import '../../utils/theme/app_theme.dart';
import '../../utils/widgets/payment_modal.dart';

class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({Key? key}) : super(key: key);

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
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

    // Cargar pagos del préstamo al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoanPayments();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadLoanPayments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.user?.uid != null && loanProvider.selectedLoan != null) {
      await loanProvider.fetchLoanPayments(
        authProvider.user!.uid,
        loanProvider.selectedLoan!.name,
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
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Detalle de préstamo',
                style: TextStyle(
                  color: AppTheme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: IconThemeData(
                color: AppTheme.colorScheme.primary,
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se ha seleccionado ningún préstamo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final clientName = loan.clientName;
        final loanName = loan.name;
        final amount = loan.amount;
        final paymentPeriod = loan.paymentPeriod;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Detalle de préstamo',
              style: TextStyle(
                color: AppTheme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(
              color: AppTheme.colorScheme.primary,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: _loadLoanPayments,
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del préstamo
                _buildLoanHeader(clientName, loanName),

                _buildLoanInfoCard(
                    amount, loanProvider.loanPayments, paymentPeriod),

                // Título de sección de cuotas
                _buildInstallmentsHeader(loanProvider.loanPayments.length),

                // Lista de cuotas
                Expanded(
                  child: loanProvider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.colorScheme.primary,
                            strokeWidth: 3,
                          ),
                        )
                      : loanProvider.loanPayments.isEmpty
                          ? _buildEmptyInstallmentsList()
                          : _buildInstallmentsList(
                              loanProvider.loanPayments,
                              paymentPeriod,
                              authProvider.user?.uid,
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanHeader(String clientName, String loanName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: AppTheme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: AppTheme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Préstamo #$loanName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanInfoCard(
      double amount, List<dynamic> payments, String paymentPeriod) {
    print('\n=== Información del préstamo ===');
    print('Monto total del préstamo: $amount');

    final totalCollected = _calculateTotalCollected(payments);
    final remainingAmount = amount - totalCollected;

    // Contar solo pagos realmente pendientes o atrasados
    final pendingInstallments = payments
        .where((p) =>
            p['payment_status'] == 'pending' || p['payment_status'] == 'late')
        .length;

    // Contar solo pagos completados
    final paidInstallments =
        payments.where((p) => p['payment_status'] == 'paid').length;

    print('Monto recaudado calculado: $totalCollected');
    print('Monto pendiente calculado: $remainingAmount');
    print('Cuotas pendientes: $pendingInstallments');
    print('Cuotas pagadas: $paidInstallments');
    print('=== Fin información ===\n');

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Monto y Recaudado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Monto',
                    'S/. ${amount.toStringAsFixed(2)}',
                    Colors.grey[800]!,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Recaudado',
                    'S/. ${totalCollected.toStringAsFixed(2)}',
                    AppTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Por Cobrar y Tipo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Por Cobrar',
                    'S/. ${remainingAmount.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tipo',
                    paymentPeriod == 'monthly' ? 'Mensual' : 'Diario',
                    Colors.grey[800]!,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Cuotas Pendientes y Pagadas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItemWithFraction(
                    'Cuotas Pendientes',
                    pendingInstallments,
                    payments.length,
                    Colors.red,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildInfoItemWithFraction(
                    'Cuotas Pagadas',
                    paidInstallments,
                    payments.length,
                    AppTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItemWithFraction(
      String label, int numerator, int denominator, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$numerator',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              Text(
                ' / $denominator',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppTheme.colorScheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cuotas del préstamo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count cuotas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInstallmentsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cuotas disponibles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadLoanPayments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorScheme.primary.withOpacity(0.1),
              foregroundColor: AppTheme.colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppTheme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
            icon: Icon(Icons.refresh, size: 14),
            label: Text(
              'Recargar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsList(
    List<dynamic> payments,
    String paymentPeriod,
    int? uid,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(
          context,
          payment,
          paymentPeriod,
          uid,
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Círculo con check o número
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: isPaid
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: isPaid
                    ? const Icon(Icons.check, color: Colors.green, size: 16)
                    : Text(
                        (payment['name'] ?? '').toString().split('/').last,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'S/.${paymentAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de cobrar
            if (!isPaid)
              TextButton.icon(
                onPressed: () {
                  _showPaymentModal(context, payment, paymentPeriod, uid);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.payment, size: 14),
                label: const Text(
                  'Cobrar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  // Método para calcular el total recaudado
  double _calculateTotalCollected(List<dynamic> payments) {
    double total = 0.0;

    print('\n=== Inicio de cálculo de total recaudado ===');
    print('Número total de pagos: ${payments.length}');

    for (var payment in payments) {
      final status = payment['payment_status'] ?? 'pending';
      final paymentAmount = (payment['payment_amount'] ?? 0.0).toDouble();

      print('\nPago ID: ${payment['name']}');
      print('Estado: $status');
      print('Monto de cuota: $paymentAmount');

      // Solo contar pagos completados
      if (status == 'paid') {
        total += paymentAmount;
        print('Sumando al total: $paymentAmount');
        print('Total acumulado: $total');
      }
    }

    print('\nTotal final recaudado: $total');
    print('=== Fin de cálculo ===\n');
    return total;
  }
}
