import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../../../src/providers/supervisor_provider.dart';
import '../../utils/widgets/custom_dropdown.dart';
import '../../utils/widgets/date_picker.dart';
import '../../models/gestor.dart';
import 'package:intl/intl.dart';
import '../../utils/theme/app_theme.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui';

class SupervisorKpiScreen extends StatefulWidget {
  const SupervisorKpiScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorKpiScreen> createState() => _SupervisorKpiScreenState();
}

class _SupervisorKpiScreenState extends State<SupervisorKpiScreen>
    with SingleTickerProviderStateMixin {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  Gestor? _selectedGestor;
  bool _isMounted = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
  void dispose() {
    _isMounted = false;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!_isMounted) return;

    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);

    await supervisorProvider.loadGestores();

    if (!_isMounted) return;

    if (supervisorProvider.gestores.isNotEmpty) {
      final initialGestor = supervisorProvider.gestores.first;
      setState(() {
        _selectedGestor = initialGestor;
      });

      // Establecer el gestor seleccionado y cargar datos
      if (_selectedGestor != null) {
        supervisorProvider.setSelectedGestor(_selectedGestor!);
        // Establecer el rango de fechas inicial
        supervisorProvider.setDateRange(_startDate, _endDate);
      }
    }
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyBar(double efficiency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Iconsax.chart, // Iconsax para insights
                  color: AppTheme.colorScheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Eficiencia del Periodo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
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
                child: Text(
                  '${(efficiency * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getEfficiencyColor(efficiency),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: efficiency,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getEfficiencyColor(efficiency)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEfficiencyLabel('Bajo', Colors.red),
              _buildEfficiencyLabel('Medio', Colors.orange),
              _buildEfficiencyLabel('Alto', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 0.8) return Colors.green;
    if (efficiency >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final supervisorProvider = Provider.of<SupervisorProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await supervisorProvider.loadKpis();
            await supervisorProvider.loadDailyLoans();
          },
          color: AppTheme.colorScheme.primary,
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGestorSelector(supervisorProvider),
                      const SizedBox(height: 20),
                      _buildDateRangeSelector(supervisorProvider),
                      const SizedBox(height: 20),
                      _buildDailySection(supervisorProvider),
                      const SizedBox(height: 20),
                      _buildDateRangeKPIs(supervisorProvider),
                      // Agregar espacio extra al final para asegurar que el último widget sea visible
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.timer, // Iconsax para cargando
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Cargando datos...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestorSelector(SupervisorProvider supervisorProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Iconsax.people, // Iconsax para personas
                  color: AppTheme.colorScheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Seleccionar Gestor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomDropdown(
            value: _selectedGestor?.id,
            items: supervisorProvider.gestores.map((gestor) {
              return DropdownMenuItem(
                value: gestor.id,
                child: Text(
                  gestor.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _isLoading =
                      true; // Mostrar loading mientras se actualizan los datos
                });

                try {
                  final selectedGestor = supervisorProvider.gestores
                      .firstWhere((g) => g.id == value);

                  // Actualizar el gestor seleccionado
                  setState(() {
                    _selectedGestor = selectedGestor;
                  });

                  // Establecer el nuevo gestor
                  supervisorProvider.setSelectedGestor(selectedGestor);

                  // Recargar todos los datos
                  await Future.wait([
                    supervisorProvider.loadKpis(),
                    supervisorProvider.loadDailyLoans(),
                    supervisorProvider.loadRangeKpis(_startDate, _endDate),
                  ]);

                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Iconsax.danger,
                                color: Colors.white,
                                size: 16), // Iconsax para error
                            const SizedBox(width: 8),
                            const Text('Error al cargar los datos del gestor'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
            hint: 'Seleccionar Gestor',
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(SupervisorProvider supervisorProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Iconsax.calendar, // Iconsax para calendario
                  color: AppTheme.colorScheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rango de Fechas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DatePicker(
                  selectedDate: _startDate,
                  onDateChanged: (date) {
                    setState(() {
                      _startDate = date;
                    });
                    supervisorProvider.setDateRange(_startDate, _endDate);
                  },
                  label: 'Fecha Inicial',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DatePicker(
                  selectedDate: _endDate,
                  onDateChanged: (date) {
                    setState(() {
                      _endDate = date;
                    });
                    supervisorProvider.setDateRange(_startDate, _endDate);
                  },
                  label: 'Fecha Final',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySection(SupervisorProvider supervisorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDailyLoansSection(supervisorProvider),
      ],
    );
  }

  Widget _buildDateRangeKPIs(SupervisorProvider supervisorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.chart_2, // Iconsax para estadísticas
              size: 18,
              color: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            Text(
              'KPIs por Rango de Fechas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (supervisorProvider.isLoadingRange)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          _buildDateRangeIndicators(supervisorProvider),
      ],
    );
  }

  Widget _buildDateRangeIndicators(SupervisorProvider supervisorProvider) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'S/',
      decimalDigits: 2,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Iconsax.chart, // Iconsax para insights
                      color: AppTheme.colorScheme.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Eficiencia del Periodo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getEfficiencyColor(
                              supervisorProvider.rangeEfficiencyPercentage)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getEfficiencyColor(
                                supervisorProvider.rangeEfficiencyPercentage)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${(supervisorProvider.rangeEfficiencyPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getEfficiencyColor(
                            supervisorProvider.rangeEfficiencyPercentage),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: supervisorProvider.rangeEfficiencyPercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getEfficiencyColor(
                      supervisorProvider.rangeEfficiencyPercentage)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(0),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currencyFormat
                        .format(supervisorProvider.rangeExpectedAmount),
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
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            GestureDetector(
              onTap: () =>
                  _showClientsDialog(context, supervisorProvider, 'pending'),
              child: _buildKpiCard(
                'Pendientes',
                supervisorProvider.rangePendingCount.toString(),
                Colors.orange,
                Iconsax.timer, // Iconsax para pendientes
              ),
            ),
            GestureDetector(
              onTap: () =>
                  _showClientsDialog(context, supervisorProvider, 'paid'),
              child: _buildKpiCard(
                'Completados',
                supervisorProvider.rangeCompletedCount.toString(),
                Colors.green,
                Iconsax.tick_circle, // Iconsax para completados
              ),
            ),
            _buildKpiCard(
              'Recaudado',
              currencyFormat.format(supervisorProvider.rangeCollectedAmount),
              Colors.blue,
              Iconsax.money, // Iconsax para pagos
            ),
            _buildKpiCard(
              'Total',
              currencyFormat.format(supervisorProvider.rangeTotalAmount),
              Colors.purple,
              Iconsax.chart_21, // Iconsax para tendencia
            ),
          ],
        ),
      ],
    );
  }

  double _calcularTotalPagadoPorPrestamo(int loanId, List<dynamic> payments) {
    double totalPagado = 0.0;
    for (var pago in payments) {
      if (pago['loan_id'] is List && pago['loan_id'][0] == loanId) {
        if (pago['payment_met'] == 'mixto') {
          totalPagado += (pago['paid_amount_cash'] ?? 0.0) +
              (pago['paid_amount_transferencia'] ?? 0.0);
        } else {
          totalPagado += (pago['paid_amount'] ?? 0.0);
        }
      }
    }
    return totalPagado;
  }

  Widget _buildDailyLoansSection(SupervisorProvider supervisorProvider) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'S/',
      decimalDigits: 2,
    );

    final payments = supervisorProvider.rangeKpis['payments'] ?? [];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  Icon(
                    Iconsax.activity, // Iconsax para eficiencia
                    size: 14,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Eficiencia de Desembolsos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${(supervisorProvider.efficiencyPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getEfficiencyColor(
                      supervisorProvider.efficiencyPercentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: supervisorProvider.efficiencyPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getEfficiencyColor(supervisorProvider.efficiencyPercentage)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.money_send, // Iconsax para desembolso
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Desemb: ${currencyFormat.format(supervisorProvider.totalDisbursed)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Iconsax.money_recive, // Iconsax para esperado
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Esp: ${currencyFormat.format(supervisorProvider.expectedAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Iconsax.document_text, // Iconsax para documentos
                size: 16,
                color: Colors.grey[800],
              ),
              const SizedBox(width: 8),
              Text(
                'Detalle de Préstamos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (supervisorProvider.dailyLoans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.document_1, // Iconsax para documento vacío
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay préstamos para mostrar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: supervisorProvider.dailyLoans.length,
              itemBuilder: (context, index) {
                final loan = supervisorProvider.dailyLoans[index];
                final loanId = loan['id'];
                final totalPagado =
                    _calcularTotalPagadoPorPrestamo(loanId, payments);
                final saldoActual = loan['current_due'] ?? 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8, right: 8, left: 8, bottom: 8),
                        child: ExpansionTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AutoSizeText(
                                    loan['name'] ?? 'Sin código',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 8),
                                  AutoSizeText(
                                    currencyFormat
                                        .format(loan['loan_amount'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax
                                        .profile_circle, // Iconsax para cliente
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      loan['partner_id'] != null
                                          ? loan['partner_id'][1]
                                          : 'Cliente sin nombre',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.calendar, // Iconsax para fecha
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        loan['create_date'] != null
                                            ? 'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['create_date']))}'
                                            : 'Fecha: No disponible',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildLoanDetailRow(
                                    'Monto del Préstamo',
                                    currencyFormat
                                        .format(loan['loan_amount'] ?? 0),
                                    icon: Iconsax.money, // Iconsax para monto
                                  ),
                                  const SizedBox(height: 4),
                                  _buildLoanDetailRow(
                                    'Interés',
                                    currencyFormat.format(loan['profit'] ?? 0),
                                    icon: Iconsax
                                        .money_recive, // Iconsax para interés
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLoanDetailRow(
                                    'Total a Pagar',
                                    currencyFormat
                                        .format(loan['total_amount'] ?? 0),
                                    isTotal: true,
                                    icon:
                                        Iconsax.money_add, // Iconsax para total
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLoanDetailRow(
                                    'Total Pagado',
                                    currencyFormat.format(
                                        (loan['total_amount'] ?? 0) -
                                            (loan['current_due'] ?? 0)),
                                    icon: Iconsax
                                        .money_tick, // Iconsax para pagado
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLoanDetailRow(
                                    'Saldo actual',
                                    currencyFormat.format(saldoActual),
                                    isTotal: true,
                                    isOverdue: true,
                                    icon: Iconsax
                                        .money_time, // Iconsax para saldo
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge glassmorphic encima de todo
                      Positioned(
                        top: 8,
                        right: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Builder(
                              builder: (context) {
                                final status = loan['loan_status'] ?? 'pending';
                                final color = getLoanStatusColor(status);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: color.withOpacity(0.7),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.10),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getLoanStatusIcon(status),
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        getLoanStatusLabel(status),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailRow(String label, String value,
      {bool isTotal = false, bool isOverdue = false, IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isOverdue
                      ? Colors.orange
                      : (isTotal
                          ? AppTheme.colorScheme.primary
                          : Colors.grey[600]),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isTotal || isOverdue ? FontWeight.bold : FontWeight.normal,
              color: isOverdue
                  ? Colors.orange
                  : (isTotal ? AppTheme.colorScheme.primary : Colors.grey[800]),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showClientsDialog(BuildContext context,
      SupervisorProvider supervisorProvider, String status) async {
    final payments = supervisorProvider.rangeKpis['payments'] ?? [];
    final clientes = payments
        .where((p) =>
            (status == 'pending' && p['payment_status'] == 'pending') ||
            (status == 'paid' &&
                (p['payment_status'] == 'paid' ||
                    p['payment_status'] == 'overpaid' ||
                    p['payment_status'] == 'partial')))
        .toList();

    // Obtener los IDs de los préstamos únicos
    final loanIds = clientes
        .map((c) => c['loan_id'] is List ? c['loan_id'][0] : c['loan_id'])
        .toSet()
        .toList();

    // Obtener los préstamos completos
    final loans = await supervisorProvider.getLoansByIds(loanIds);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(status == 'pending'
              ? 'Clientes Pendientes'
              : 'Clientes Completados'),
          content: clientes.isEmpty
              ? const Text('No hay clientes para mostrar.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: clientes.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      final nombre = (cliente['partner_id'] is List &&
                              cliente['partner_id'].length > 1)
                          ? cliente['partner_id'][1]
                          : (cliente['name'] ?? 'Sin nombre');
                      final montoEsperado = cliente['payment_amount'] ?? 0.0;
                      final montoPagado = (cliente['payment_met'] == 'mixto')
                          ? ((cliente['paid_amount_cash'] ?? 0.0) +
                              (cliente['paid_amount_transferencia'] ?? 0.0))
                          : (cliente['paid_amount'] ?? 0.0);

                      // Obtener el préstamo completo para acceder al current_due y due_date
                      final loanId = cliente['loan_id'] is List
                          ? cliente['loan_id'][0]
                          : cliente['loan_id'];
                      final prestamo = loans.firstWhere(
                        (loan) => loan['id'] == loanId,
                        orElse: () => {'current_due': 0.0, 'due_date': null},
                      );
                      final saldoActual = prestamo['current_due'] ?? 0.0;
                      final fechaVencimiento = prestamo['due_date'] != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(prestamo['due_date']))
                          : 'No disponible';

                      return ListTile(
                        leading: Icon(Iconsax.user_square,
                            color: status == 'pending'
                                ? Colors.orange
                                : Colors.green),
                        title: Text(nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Monto: S/ ${montoEsperado.toStringAsFixed(2)}'),
                            if (status == 'paid')
                              Text(
                                  'Pagado: S/ ${montoPagado.toStringAsFixed(2)}'),
                            Text(
                              'Saldo actual: S/ ${saldoActual.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: saldoActual > 0
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'F. Venc.: $fechaVencimiento',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Funciones auxiliares para el badge de estado del préstamo
  String getLoanStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'renewed':
        return 'Renovado';
      case 'refinanced':
        return 'Refinanciado';
      case 'paid':
        return 'Pagado';
      default:
        return 'Desconocido';
    }
  }

  Color getLoanStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'renewed':
        return Colors.blue;
      case 'refinanced':
        return Colors.purple;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getLoanStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Iconsax.timer;
      case 'renewed':
        return Iconsax.repeat;
      case 'refinanced':
        return Iconsax.refresh_square_2;
      case 'paid':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }
}
