import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/providers/auth_provider.dart';
import 'package:yatha_app/providers/kpi_provider.dart';
import 'package:yatha_app/theme/app_theme.dart';
import 'package:yatha_app/widgets/glass_container.dart';
import 'package:yatha_app/widgets/progress_indicator_widget.dart';

class NewKpiScreen extends StatefulWidget {
  const NewKpiScreen({Key? key}) : super(key: key);

  @override
  State<NewKpiScreen> createState() => _NewKpiScreenState();
}

class _NewKpiScreenState extends State<NewKpiScreen> {
  late DateTime _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPayments = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newUserId = authProvider.user?.uid.toString();

    // Si el ID de usuario ha cambiado, recargar los datos
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Limpiar datos existentes
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);
    kpiProvider.changeUser(null);

    await _loadKpis();
  }

  Future<void> _loadKpis() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);

    if (authProvider.user?.uid != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await kpiProvider.fetchDailyKPIs(
        authProvider.user!.uid.toString(),
        formattedDate,
      );

      if (mounted) {
        setState(() {
          _filteredPayments = List.from(kpiProvider.payments);
        });
      }
    }
  }

  void _filterPayments(String query) {
    final kpiProvider = Provider.of<KpiProvider>(context, listen: false);

    setState(() {
      if (query.isEmpty) {
        _filteredPayments = List.from(kpiProvider.payments);
      } else {
        _filteredPayments = kpiProvider.payments.where((payment) {
          final clientName =
              payment['partner_id'] != null && payment['partner_id'] is List
                  ? payment['partner_id'][1].toString().toLowerCase()
                  : '';
          final paymentNumber = payment['name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return clientName.contains(searchLower) ||
              paymentNumber.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
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
      });
      await _loadKpis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KpiProvider>(
      builder: (context, kpiProvider, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _loadKpis,
            child: Stack(
              children: [
                if (kpiProvider.error != null)
                  _buildErrorState(kpiProvider.error!)
                else
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateSelector(),
                        const SizedBox(height: 24),
                        _buildProgressCard(kpiProvider),
                        const SizedBox(height: 24),
                        _buildPaymentsList(kpiProvider),
                      ],
                    ),
                  ),
                if (kpiProvider.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadKpis,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.colorScheme.primary),
            const SizedBox(width: 16),
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
    );
  }

  Widget _buildProgressCard(KpiProvider provider) {
    final efficiency = ((provider.totalPaid / provider.totalExpected) * 100)
        .toStringAsFixed(0);
    final progressValue = provider.totalPaid / provider.totalExpected;

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso del día',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEfficiencyColor(double.parse(efficiency))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEfficiencyIcon(double.parse(efficiency)),
                      size: 16,
                      color: _getEfficiencyColor(double.parse(efficiency)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Eficiencia: $efficiency%',
                      style: TextStyle(
                        color: _getEfficiencyColor(double.parse(efficiency)),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'S/.${provider.totalPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const Text(
                    'Recaudado',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/.${provider.totalExpected.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const Text(
                    'Meta',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressIndicatorWidget(
            value: progressValue.clamp(0.0, 1.0),
            height: 8,
            color: _getProgressColor(progressValue),
            backgroundColor: Colors.grey[200]!,
          ),
          const SizedBox(height: 24),
          _buildPaymentStatusIndicators(provider),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 100) return Colors.green;
    if (efficiency >= 70) return Colors.blue;
    if (efficiency >= 50) return Colors.orange;
    return Colors.red;
  }

  IconData _getEfficiencyIcon(double efficiency) {
    if (efficiency >= 100) return Icons.emoji_events;
    if (efficiency >= 70) return Icons.trending_up;
    if (efficiency >= 50) return Icons.trending_flat;
    return Icons.trending_down;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPaymentStatusIndicators(KpiProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusIndicator(
          'A tiempo',
          provider.statusCounts['completed'] ?? 0,
          Colors.green,
          Icons.check_circle_outline,
        ),
        _buildStatusIndicator(
          'Tardíos',
          provider.statusCounts['late'] ?? 0,
          Colors.orange,
          Icons.warning_amber_outlined,
        ),
        _buildStatusIndicator(
          'Pendientes',
          provider.statusCounts['pending'] ?? 0,
          Colors.grey,
          Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(KpiProvider provider) {
    if (provider.payments.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose de Pagos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredPayments.length,
          itemBuilder: (context, index) =>
              _buildPaymentCard(_filteredPayments[index]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.blue[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin pagos para mostrar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay pagos registrados para la fecha seleccionada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar pago...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: _filterPayments,
      ),
    );
  }

  Widget _buildPaymentCard(Map<dynamic, dynamic> payment) {
    final paymentStatus = payment['status'] ?? 'pending';
    final statusInfo =
        Provider.of<KpiProvider>(context).getPaymentStatusInfo(paymentStatus);
    final clientName = Provider.of<KpiProvider>(context).getClientName(payment);
    final paymentDetails =
        Provider.of<KpiProvider>(context).getPaymentDetails(payment);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusInfo['color'].withOpacity(0.1),
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: statusInfo['color'],
                  fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Pago #${payment['name'] ?? 'Sin número'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusInfo['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusInfo['icon'], size: 16, color: statusInfo['color']),
              const SizedBox(width: 4),
              Text(
                statusInfo['text'],
                style: TextStyle(
                  color: statusInfo['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: paymentDetails
                  .map((detail) => _buildPaymentDetail(
                        detail['label'],
                        detail['value'].toString().startsWith('\$')
                            ? detail['value']
                                .toString()
                                .replaceFirst('\$', 'S/.')
                            : detail['value'],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
