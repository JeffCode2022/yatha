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
  late DateTime _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    await _loadKpis();
  }

  Future<void> _loadKpis() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );

      if (authProvider.user?.uid != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        print('KpiScreen - Cargando KPIs para fecha: $formattedDate');
        print('KpiScreen - Usuario ID: ${authProvider.user?.uid}');

        await paymentProvider.fetchDailyKPIs(
          authProvider.user!.uid,
          formattedDate,
        );

        // Verificar si los datos se cargaron correctamente
        if (paymentProvider.kpiData.isEmpty) {
          setState(() {
            _errorMessage =
                'No se encontraron datos para la fecha seleccionada';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No hay usuario autenticado';
        });
      }
    } catch (e) {
      print('KpiScreen - Error al cargar KPIs: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        locale: const Locale('es', ''),
      );

      if (picked != null && picked != _selectedDate && mounted) {
        setState(() {
          _selectedDate = picked;
          _errorMessage = null;
        });
        await _loadKpis();
      }
    } catch (e) {
      print('KpiScreen - Error al seleccionar fecha: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar fecha: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<PaymentProvider, AuthProvider>(
        builder: (context, paymentProvider, authProvider, _) {
          return RefreshIndicator(
            onRefresh: _loadKpis,
            child: Stack(
              children: [
                if (_errorMessage != null ||
                    paymentProvider.errorMessage != null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? paymentProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadKpis,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                else
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate),
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
                              _buildProgressStats(paymentProvider),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tarjetas de estadísticas
                        _buildStatCards(paymentProvider),

                        const SizedBox(height: 24),

                        // Lista de pagos
                        const Text(
                          'Desglose de Pagos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentsList(paymentProvider),
                      ],
                    ),
                  ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressStats(PaymentProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recaudado',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '\$${provider.getTotalPaidAmount().toStringAsFixed(2)}',
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '\$${provider.getTotalExpectedAmount().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards(PaymentProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pagos a Tiempo',
                value: provider.getOnTimePaymentsCount().toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Pagos Tardíos',
                value: provider.getLatePaymentsCount().toString(),
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
                value: provider.getTotalPaymentsCount().toString(),
                icon: Icons.assignment,
                color: AppTheme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Eficiencia',
                value:
                    '${provider.getTotalPaymentsCount() > 0 ? (provider.getOnTimePaymentsCount() / provider.getTotalPaymentsCount() * 100).toStringAsFixed(0) : '0'}%',
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(PaymentProvider provider) {
    final payments = provider.kpiData['payments'] as List<dynamic>? ?? [];

    if (payments.isEmpty) {
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

    final onTimePayments =
        payments.where((p) => p['payment_status'] == 'on_time').toList();
    final latePayments =
        payments.where((p) => p['payment_status'] == 'late').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onTimePayments.isNotEmpty) ...[
          _buildPaymentSection('Pagos a Tiempo', onTimePayments, Colors.green),
          const SizedBox(height: 16),
        ],
        if (latePayments.isNotEmpty)
          _buildPaymentSection('Pagos Tardíos', latePayments, Colors.orange),
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
            separatorBuilder: (context, index) =>
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
