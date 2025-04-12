import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/providers/auth_provider.dart';
import 'package:yatha_app/providers/payment_provider.dart';
import 'package:yatha_app/theme/app_theme.dart';
import 'package:yatha_app/widgets/glass_container.dart';
import 'package:yatha_app/widgets/progress_indicator_widget.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({Key? key}) : super(key: key);

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKpis();
    });
  }

  void _loadKpis() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    if (authProvider.user?.uid != null) {
      await paymentProvider.fetchDailyKPIs(authProvider.user!.uid);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Cargar KPIs para la fecha seleccionada
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );

      if (authProvider.user?.uid != null) {
        await paymentProvider.fetchDailyKPIs(authProvider.user!.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PaymentProvider, AuthProvider>(
      builder: (context, paymentProvider, authProvider, _) {
        return RefreshIndicator(
          onRefresh: () async => _loadKpis(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de fecha
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha seleccionada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tarjeta de progreso
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progreso del día',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ProgressIndicatorWidget(
                        value: paymentProvider.getProgressPercentage(),
                        height: 10,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recaudado',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${paymentProvider.getTotalPaidAmount().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppTheme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Meta',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${paymentProvider.getTotalExpectedAmount().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Avance: ${(paymentProvider.getProgressPercentage() * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tarjetas de estadísticas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pagos a Tiempo',
                        value:
                            paymentProvider.getOnTimePaymentsCount().toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pagos Tardíos',
                        value:
                            paymentProvider.getLatePaymentsCount().toString(),
                        icon: Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total de Pagos',
                        value:
                            paymentProvider.getTotalPaymentsCount().toString(),
                        icon: Icons.assignment,
                        color: AppTheme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Eficiencia',
                        value:
                            '${paymentProvider.getTotalPaymentsCount() > 0 ? (paymentProvider.getOnTimePaymentsCount() / paymentProvider.getTotalPaymentsCount() * 100).toStringAsFixed(0) : '0'}%',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Lista de resumen de pagos
                const Text(
                  'Desglose de Pagos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                _buildPaymentsList(paymentProvider),
                const SizedBox(height: 12), // Espacio adicional al final
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(PaymentProvider provider) {
    final onTimePayments = provider.kpiData['onTime'];
    final latePayments = provider.kpiData['late'];

    if ((onTimePayments?.isEmpty ?? true) && (latePayments?.isEmpty ?? true)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.info, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay pagos registrados para esta fecha',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onTimePayments != null && onTimePayments.isNotEmpty) ...[
          _buildPaymentSection('Pagos a Tiempo', onTimePayments, Colors.green),
          const SizedBox(height: 16),
        ],

        if (latePayments != null && latePayments.isNotEmpty) ...[
          _buildPaymentSection('Pagos Tardíos', latePayments, Colors.orange),
        ],
      ],
    );
  }

  Widget _buildPaymentSection(
    String title,
    List<dynamic> payments,
    Color color,
  ) {
    double totalAmount = 0;
    for (var payment in payments) {
      totalAmount += payment['paid_amount'] ?? 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text(
              '\$${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: payments.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: color.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                dense: true,
                title: Text(
                  'Pago #${payment['name'] ?? 'Sin nombre'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Fecha: ${payment['payment_date'] ?? 'Sin fecha'}',
                ),
                trailing: Text(
                  '\$${(payment['paid_amount'] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
