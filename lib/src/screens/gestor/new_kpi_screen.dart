import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:yatha_app/src/providers/auth_provider.dart';
import 'package:yatha_app/src/providers/kpi_provider.dart';
import 'package:yatha_app/utils/theme/app_theme.dart';
import 'package:yatha_app/utils/widgets/glass_container.dart';
import 'package:yatha_app/utils/widgets/progress_indicator_widget.dart';

class NewKpiScreen extends StatefulWidget {
  const NewKpiScreen({Key? key}) : super(key: key);

  @override
  State<NewKpiScreen> createState() => _NewKpiScreenState();
}

class _NewKpiScreenState extends State<NewKpiScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPayments = [];
  String? _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    
    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
    
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
    _animationController.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
          body: Container(
            decoration: BoxDecoration(
              color: AppTheme.colorScheme.primary.withOpacity(0.8),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadKpis,
                color: AppTheme.colorScheme.primary,
                child: Stack(
                  children: [
                    if (kpiProvider.error != null)
                      _buildErrorState(kpiProvider.error!)
                    else
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
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
                              const SizedBox(height: 80), // Espacio adicional al final
                            ],
                          ),
                        ),
                      ),
                    if (kpiProvider.isLoading)
                      _buildLoadingOverlay(),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _loadKpis,
            backgroundColor: AppTheme.colorScheme.primary,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cargando datos...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error al cargar datos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadKpis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha seleccionada',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(KpiProvider provider) {
    final efficiency = ((provider.totalPaid / provider.totalExpected) * 100)
        .toStringAsFixed(0);
    final progressValue = provider.totalPaid / provider.totalExpected;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getEfficiencyColor(double.parse(efficiency))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getEfficiencyColor(double.parse(efficiency))
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEfficiencyIcon(double.parse(efficiency)),
                          size: 16,
                          color: _getEfficiencyColor(double.parse(efficiency)),
                        ),
                        const SizedBox(width: 6),
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
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
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
                                fontSize: 28,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getProgressColor(progressValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Recaudado',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/.${provider.totalExpected.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Meta',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProgressIndicatorWidget(
                      value: progressValue.clamp(0.0, 1.0),
                      height: 10,
                      color: _getProgressColor(progressValue),
                      backgroundColor: Colors.grey[200]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildPaymentStatusIndicators(provider),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
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
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Desglose de Pagos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
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
              _buildPaymentCard(_filteredPayments[index], index),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.blue[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin pagos para mostrar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No hay pagos registrados para la fecha seleccionada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
                label: const Text(
                  'Cambiar fecha',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar pago...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            onChanged: _filterPayments,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<dynamic, dynamic> payment, int index) {
    final paymentStatus = payment['status'] ?? 'pending';
    final statusInfo =
        Provider.of<KpiProvider>(context).getPaymentStatusInfo(paymentStatus);
    final clientName = Provider.of<KpiProvider>(context).getClientName(payment);
    final paymentDetails =
        Provider.of<KpiProvider>(context).getPaymentDetails(payment);

    // Animación de entrada escalonada
    final delay = Duration(milliseconds: 100 * index);
    
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: AnimatedPadding(
            padding: snapshot.connectionState == ConnectionState.done 
              ? const EdgeInsets.only(bottom: 12, left: 0, right: 0) 
              : const EdgeInsets.only(bottom: 12, left: 20, right: 0),
            duration: const Duration(milliseconds: 500),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: statusInfo['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusInfo['color'].withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: statusInfo['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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
                        border: Border.all(
                          color: statusInfo['color'].withOpacity(0.3),
                        ),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            ...paymentDetails.map((detail) => _buildPaymentDetail(
                                  detail['label'],
                                  detail['value'].toString().startsWith('\$')
                                      ? detail['value']
                                          .toString()
                                          .replaceFirst('\$', 'S/.')
                                      : detail['value'],
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
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
