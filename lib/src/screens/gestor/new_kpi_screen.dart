import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import 'dart:ui';
import 'package:yatha_app/src/providers/auth_provider.dart';
import 'package:yatha_app/src/providers/kpi_provider.dart';
import 'package:yatha_app/src/utils/theme/app_theme.dart';
import 'package:yatha_app/src/utils/widgets/progress_indicator_widget.dart';

class NewKpiScreen extends StatefulWidget {
  const NewKpiScreen({Key? key}) : super(key: key);

  @override
  State<NewKpiScreen> createState() => _NewKpiScreenState();
}

class _NewKpiScreenState extends State<NewKpiScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPayments = [];
  String? _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isMonthly = false;

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

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
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
              payment['partnerId'] != null && payment['partnerId'] is List
                  ? payment['partnerId'][1].toString().toLowerCase()
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'KPI Diario',
              style: TextStyle(
                color: AppTheme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Iconsax.calendar_1, // Iconsax en lugar de Material Icons
                  color: AppTheme.colorScheme.primary,
                ),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          body: SafeArea(
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
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateDisplay(),
                              const SizedBox(height: 20),
                              _buildProgressCard(kpiProvider),
                              const SizedBox(height: 20),
                              _buildPaymentsList(kpiProvider),
                              const SizedBox(
                                  height: 80), // Espacio adicional al final
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (kpiProvider.isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: FloatingActionButton(
                  onPressed: _loadKpis,
                  backgroundColor: AppTheme.colorScheme.primary,
                  elevation: 2,
                  child: Icon(Iconsax.refresh,
                      color:
                          Colors.white), // Iconsax en lugar de Material Icons
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppTheme.colorScheme.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.timer, // Iconsax en lugar de Material Icons
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cargando datos...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    // Determinar el mensaje amigable basado en el error
    String userFriendlyMessage = 'Error al cargar los datos.';
    String title = 'Error al cargar datos';
    IconData icon = Iconsax.danger;
    Color iconColor = Colors.red[400]!;

    if (error.contains('MissingError')) {
      title = 'Sin datos disponibles';
      userFriendlyMessage =
          'No se encontraron préstamos asignados para la fecha seleccionada.';
      icon = Iconsax.document_text;
      iconColor = Colors.orange[400]!;
    } else if (error.contains('AccessDenied')) {
      title = 'Sesión expirada';
      userFriendlyMessage =
          'Su sesión ha expirado. Por favor, inicie sesión nuevamente.';
      icon = Iconsax.logout;
      iconColor = Colors.red[400]!;
    } else if (error.contains('Odoo Server Error')) {
      title = 'Error del servidor';
      userFriendlyMessage =
          'El servidor está experimentando problemas. Intente nuevamente en unos minutos.';
      icon = Iconsax.warning_2;
      iconColor = Colors.red[400]!;
    } else if (error.contains('Error de conexión')) {
      title = 'Error de conexión';
      userFriendlyMessage =
          'Verifique su conexión a internet e intente nuevamente.';
      icon = Iconsax.wifi_square;
      iconColor = Colors.blue[400]!;
    } else if (error.contains('No se encontraron datos')) {
      title = 'Sin datos';
      userFriendlyMessage =
          'No hay información disponible para la fecha seleccionada.';
      icon = Iconsax.document_text;
      iconColor = Colors.grey[400]!;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
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
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                userFriendlyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadKpis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Iconsax.refresh, size: 16),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (error.contains('MissingError') ||
                    error.contains('No se encontraron datos'))
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Iconsax.calendar_1, size: 16),
                    label: const Text(
                      'Cambiar fecha',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (error.contains('AccessDenied'))
                  ElevatedButton.icon(
                    onPressed: () => _handleLogout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Iconsax.logout, size: 16),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.calendar, // Iconsax en lugar de Material Icons
            size: 16,
            color: AppTheme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(KpiProvider provider) {
    final efficiency = provider.eficiencia;
    final progressValue = provider.totalExpected > 0
        ? (provider.totalPaid / provider.totalExpected)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.chart, // Iconsax en lugar de Material Icons
                      color: AppTheme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Progreso del día',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEfficiencyColor(efficiency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getEfficiencyColor(efficiency).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEfficiencyIcon(efficiency),
                      size: 14,
                      color: _getEfficiencyColor(efficiency),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Eficiencia: ${efficiency.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getEfficiencyColor(efficiency),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[100]!,
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
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getProgressColor(progressValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recaudado',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/.${provider.totalExpected.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Meta',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildKpiMetricsGrid(provider),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 100) return const Color.fromARGB(255, 26, 206, 50);
    if (efficiency >= 70) return const Color.fromARGB(255, 31, 179, 199);
    if (efficiency >= 50) return Colors.orange;
    return const Color.fromARGB(255, 234, 71, 38);
  }

  IconData _getEfficiencyIcon(double efficiency) {
    if (efficiency >= 100)
      return Iconsax.medal; // Iconsax en lugar de Material Icons
    if (efficiency >= 70)
      return Iconsax.trend_up; // Iconsax en lugar de Material Icons
    if (efficiency >= 50)
      return Iconsax.arrow_right_3; // Iconsax en lugar de Material Icons
    return Iconsax.trend_down; // Iconsax en lugar de Material Icons
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color.fromARGB(255, 26, 206, 50);
    if (progress >= 0.7) return const Color.fromARGB(255, 31, 179, 199);
    if (progress >= 0.5) return Colors.orange;
    return const Color.fromARGB(255, 234, 71, 38);
  }

  Widget _buildKpiMetricsGrid(KpiProvider provider) {
    final totalPagos = (provider.statusCounts['ontime'] ?? 0) +
        (provider.statusCounts['late'] ?? 0) +
        (provider.statusCounts['pending'] ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Indicadores del día',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModernMetricCard(
              label: 'A tiempo',
              value: provider.statusCounts['ontime'] ?? 0,
              color: const Color(0xFF00C853), // Verde fuerte
              icon: Iconsax.tick_circle,
              subtitle: 'Pagos realizados',
            ),
            _buildModernMetricCard(
              label: 'Tardíos',
              value: provider.statusCounts['late'] ?? 0,
              color: const Color(0xFF2979FF), // Azul fuerte
              icon: Iconsax.warning_2,
              subtitle: 'Pagos fuera de fecha',
            ),
            _buildModernMetricCard(
              label: 'Pendientes',
              value: provider.statusCounts['pending'] ?? 0,
              color: const Color(0xFFFF6D00), // Naranja fuerte
              icon: Iconsax.timer,
              subtitle: 'Pagos sin realizar',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernMetricCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
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
                'Desglose de Pagos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        _buildSearchBar(),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredPayments.length,
          itemBuilder: (context, index) =>
              _buildPaymentCard(provider, _filteredPayments[index], index),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.clipboard_tick, // Iconsax en lugar de Material Icons
              size: 32,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin pagos para mostrar',
            style: TextStyle(
              fontSize: 14,
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
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _selectDate(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Iconsax.calendar_1,
                size: 14,
                color: Colors.blue[700]), // Iconsax en lugar de Material Icons
            label: Text(
              'Cambiar fecha',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar pago...',
          prefixIcon: Icon(Iconsax.search_normal,
              color: Colors.grey[600],
              size: 16), // Iconsax en lugar de Material Icons
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: _filterPayments,
      ),
    );
  }

  Widget _buildPaymentCard(
      KpiProvider provider, Map<dynamic, dynamic> payment, int index) {
    final paymentStatus = payment['timeStatus'] ?? 'pending';
    final statusInfo = _getTimeStatusInfo(paymentStatus);
    final clientName = provider.getClientName(payment);
    final paymentDetails = provider.getPaymentDetails(payment);

    // Animación de entrada escalonada
    final delay = Duration(milliseconds: 50 * index);

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 246, 250, 246),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.colorScheme.primary,
                      width: 6.0,
                    ),
                    top: BorderSide(color: Colors.grey[200]!),
                    right: BorderSide(color: Colors.grey[200]!),
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 8),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusInfo['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusInfo['color'].withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            clientName.isNotEmpty
                                ? clientName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: statusInfo['color'],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pago #${payment['name'] ?? 'Sin número'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusInfo['color'].withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo['icon'],
                            size: 12, color: statusInfo['color']),
                        const SizedBox(width: 4),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            color: statusInfo['color'],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          ...paymentDetails.map((detail) => _buildPaymentDetail(
                                detail['label'],
                                detail['value'],
                              )),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTimeStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'ontime':
        return {
          'color': Colors.green,
          'icon': Iconsax.tick_circle, // Iconsax en lugar de Material Icons
          'text': 'A tiempo'
        };
      case 'late':
        return {
          'color': Colors.orange,
          'icon': Iconsax.warning_2, // Iconsax en lugar de Material Icons
          'text': 'Tardío'
        };
      case 'pending':
      default:
        return {
          'color': Colors.grey,
          'icon': Iconsax.timer, // Iconsax en lugar de Material Icons
          'text': 'Pendiente'
        };
    }
  }

  Future<void> _handleLogout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final kpiProvider = Provider.of<KpiProvider>(context, listen: false);

      // Limpiar datos
      kpiProvider.changeUser(null);

      // Cerrar sesión
      await authProvider.logout();

      // Navegar a la pantalla de login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
