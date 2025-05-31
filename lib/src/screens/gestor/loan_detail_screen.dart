import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
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
                    Iconsax.wallet_minus, // Iconsax en lugar de Material Icons
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
                  Iconsax.refresh, // Iconsax en lugar de Material Icons
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

                _buildLoanInfoCard(loanProvider, amount,
                    loanProvider.loanPayments, paymentPeriod),

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

  Widget _buildLoanInfoCard(LoanProvider loanProvider, double amount,
      List<dynamic> payments, String paymentPeriod) {
    print('\n=== Información del préstamo ===');
    print('Monto total del préstamo: $amount');

    // Obtener el total_amount del primer pago (todos tienen el mismo valor)
    final totalAmount = payments.isNotEmpty
        ? (payments[0]['total_amount'] ?? amount).toDouble()
        : amount;
    final totalCollected = _calculateTotalCollected(payments);
    final remainingAmount = totalAmount - totalCollected;

    print('Monto total a pagar (total_amount): $totalAmount');
    print('Monto recaudado calculado: $totalCollected');
    print('Monto pendiente calculado: $remainingAmount');

    // Contar pagos según su estado
    final pendingInstallments = payments
        .where(
            (p) => p['payment_status']?.toString().toLowerCase() == 'pending')
        .length;

    // Contar pagos completados (paid), excedidos (overpaid) y parciales (partial)
    final paidInstallments = payments.where((p) {
      final status = p['payment_status']?.toString().toLowerCase() ?? 'pending';
      return status == 'paid' || status == 'overpaid' || status == 'partial';
    }).length;

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
                    Iconsax.money, // Iconsax en lugar de texto
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
                    Iconsax.money_recive, // Iconsax en lugar de texto
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
                    Iconsax.money_send, // Iconsax en lugar de texto
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
                    paymentPeriod == 'monthly'
                        ? Iconsax.calendar
                        : Iconsax.clock, // Iconsax según el tipo
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Fecha de Vencimiento
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildInfoItem(
              'Fecha de Vencimiento',
              loanProvider.selectedLoan?.due_date ??
                  'No disponible', // Access due_date here
              Colors.orange, // You can choose a color
              Iconsax.calendar_add, // Choose an appropriate icon
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
                    Iconsax.timer, // Iconsax en lugar de texto
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
                    Iconsax.tick_circle, // Iconsax en lugar de texto
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, Color valueColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItemWithFraction(String label, int numerator,
      int denominator, Color valueColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
                  Iconsax.receipt_2, // Iconsax en lugar de Material Icons
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
            Iconsax.calendar_1, // Iconsax en lugar de Material Icons
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
            icon: Icon(Iconsax.refresh,
                size: 14), // Iconsax en lugar de Material Icons
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
    final paymentAmount =
        ((payment['payment_amount'] ?? 0.0) * 100).round() / 100;
    final status = payment['payment_status'] ?? 'pending';
    final paymentMethod = payment['payment_met'] ?? '';
    final isPaid =
        status == 'paid' || status == 'overpaid' || status == 'partial';

    // Calcular el monto pagado total y el estado
    double paidAmount = 0.0;
    String paymentStatus = status;

    if (isPaid) {
      if (paymentMethod == 'mixto') {
        final cashAmount =
            ((payment['paid_amount_cash'] ?? 0.0) * 100).round() / 100;
        final transferAmount =
            ((payment['paid_amount_transferencia'] ?? 0.0) * 100).round() / 100;
        paidAmount = ((cashAmount + transferAmount) * 100).round() / 100;
      } else {
        paidAmount = ((payment['paid_amount'] ?? 0.0) * 100).round() / 100;
      }

      // Recalcular el estado basado en el monto pagado
      if ((paidAmount - paymentAmount).abs() <= 0.01) {
        paymentStatus = 'paid';
      } else if (paidAmount > paymentAmount) {
        paymentStatus = 'overpaid';
      } else {
        paymentStatus = 'partial';
      }
    }

    // Convertir status a texto, color e icono
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        statusText = 'Pagado';
        statusColor = Colors.green;
        statusIcon = Iconsax.tick_circle; // Iconsax en lugar de Material Icons
        break;
      case 'overpaid':
        statusText = 'Pago Excedido';
        statusColor = Colors.blue;
        statusIcon = Iconsax.money_add; // Iconsax en lugar de Material Icons
        break;
      case 'partial':
        statusText = 'Pago Parcial';
        statusColor = Colors.orange;
        statusIcon = Iconsax.timer_1; // Iconsax en lugar de Material Icons
        break;
      case 'on_time':
        statusText = 'Pendiente';
        statusColor = Colors.orange;
        statusIcon = Iconsax.timer; // Iconsax en lugar de Material Icons
        break;
      case 'late':
        statusText = 'Atrasado';
        statusColor = Colors.red;
        statusIcon = Iconsax.danger; // Iconsax en lugar de Material Icons
        break;
      default:
        statusText = 'Pendiente';
        statusColor = Colors.orange;
        statusIcon = Iconsax.timer; // Iconsax en lugar de Material Icons
    }

    // Construir el texto del monto pagado para pagos mixtos
    List<Widget> paymentInfo = [];
    if (paymentMethod == 'mixto') {
      if (isPaid) {
        final cashAmount =
            ((payment['paid_amount_cash'] ?? 0.0) * 100).round() / 100;
        final transferAmount =
            ((payment['paid_amount_transferencia'] ?? 0.0) * 100).round() / 100;
        paymentInfo = [
          Row(
            children: [
              Icon(Iconsax.money,
                  size: 10, color: Colors.grey[600]), // Iconsax para efectivo
              const SizedBox(width: 4),
              Text(
                'Efectivo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'S/.${cashAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Iconsax.card,
                  size: 10,
                  color: Colors.grey[600]), // Iconsax para transferencia
              const SizedBox(width: 4),
              Text(
                'Transferencia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'S/.${transferAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ];
      } else {
        final expectedAmount =
            ((payment['payment_amount'] ?? 0.0) * 100).round() / 100;
        paymentInfo = [
          Text(
            'S/.${expectedAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ];
      }
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
                    ? statusColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: isPaid
                      ? statusColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: isPaid
                    ? Icon(Iconsax.tick_circle,
                        color: statusColor,
                        size: 16) // Iconsax en lugar de Material Icons
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
                  Row(
                    children: [
                      Icon(Iconsax.calendar,
                          size: 12,
                          color: Colors.grey[600]), // Iconsax para fecha
                      const SizedBox(width: 4),
                      Text(
                        'Fecha: $paymentDate',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 10,
                                color: statusColor), // Iconsax según estado
                            const SizedBox(width: 2),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPaid && paymentMethod == 'mixto') ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: paymentInfo,
                          ),
                        ),
                      ] else if (isPaid) ...[
                        Icon(Iconsax.money_tick,
                            size: 12,
                            color: statusColor), // Iconsax para dinero
                        const SizedBox(width: 4),
                        Text(
                          'S/.${paidAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Icon(Iconsax.money,
                            size: 12,
                            color: Colors.grey[700]), // Iconsax para dinero
                        const SizedBox(width: 4),
                        Text(
                          'S/.${((payment['payment_amount'] ?? 0.0) * 100).round() / 100.0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                icon: Icon(Iconsax.money_send,
                    size: 14), // Iconsax en lugar de Material Icons
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
      builder: (BuildContext modalContext) => PaymentModal(
        payment: payment,
        paymentPeriod: paymentPeriod,
        uid: uid,
        onPaymentComplete: (double paidAmount, String status) {
          // Cerrar el modal de pago primero
          Navigator.pop(modalContext);

          if (!modalContext.mounted) return;

          // Mostrar mensaje de éxito
          _showSuccessMessage(
            modalContext,
            paidAmount.toStringAsFixed(2),
            payment['payment_amount']?.toStringAsFixed(2) ?? '0.00',
            payment['name'] ?? '',
            status,
          );

          // Recargar pagos después de registrar uno
          _loadLoanPayments();
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String paidAmount,
      String expectedAmount, String cuota, String status) {
    OverlayEntry overlayEntry;

    // Determinar el color y mensaje según el estado
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        statusText = '¡Pago Completo!';
        statusIcon = Iconsax.tick_circle; // Iconsax en lugar de Material Icons
        break;
      case 'overpaid':
        statusColor = Colors.green;
        statusText = '¡Pago Excedido!';
        statusIcon = Iconsax.money_add; // Iconsax en lugar de Material Icons
        break;
      case 'partial':
        statusColor = Colors.orange;
        statusText = 'Pago Parcial';
        statusIcon = Iconsax.timer_1; // Iconsax en lugar de Material Icons
        break;
      default:
        statusColor = Colors.green;
        statusText = '¡Pago Exitoso!';
        statusIcon = Iconsax.tick_circle; // Iconsax en lugar de Material Icons
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.2),
          child: Center(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPaymentInfoRow(
                        'Monto esperado:', 'S/. $expectedAmount'),
                    const SizedBox(height: 8),
                    _buildPaymentInfoRow('Monto pagado:', 'S/. $paidAmount',
                        valueColor: double.parse(paidAmount) >
                                double.parse(expectedAmount)
                            ? Colors.blue
                            : double.parse(paidAmount) <
                                    double.parse(expectedAmount)
                                ? Colors.orange
                                : Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Cuota: $cuota',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remover el mensaje después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Widget _buildPaymentInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Método para calcular el total recaudado
  double _calculateTotalCollected(List<dynamic> payments) {
    double total = 0.0;

    print('\n=== Inicio de cálculo de total recaudado ===');
    print('Número total de pagos: ${payments.length}');

    for (var payment in payments) {
      final status =
          payment['payment_status']?.toString().toLowerCase() ?? 'pending';
      double paidAmount = 0.0;

      if (status == 'paid' || status == 'overpaid' || status == 'partial') {
        // Si es pago mixto, sumar ambos montos
        if (payment['payment_met'] == 'mixto') {
          final cashAmount =
              ((payment['paid_amount_cash'] ?? 0.0) * 100).round() / 100;
          final transferAmount =
              ((payment['paid_amount_transferencia'] ?? 0.0) * 100).round() /
                  100;
          paidAmount = cashAmount + transferAmount;
        } else {
          paidAmount = ((payment['paid_amount'] ?? 0.0) * 100).round() / 100;
        }

        total = ((total + paidAmount) * 100).round() / 100;
      } else {}
    }

    return total;
  }
}
