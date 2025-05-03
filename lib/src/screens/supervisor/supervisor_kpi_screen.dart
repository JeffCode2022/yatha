import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/supervisor_provider.dart';
import '../../utils/widgets/custom_dropdown.dart';
import '../../utils/widgets/date_picker.dart';
import '../../models/gestor.dart';
import 'package:intl/intl.dart';
import '../../utils/theme/app_theme.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
                  Icons.insights,
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
                    child: const Center(
                      child: CircularProgressIndicator(),
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
                  Icons.people,
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
                      const SnackBar(
                        content: Text('Error al cargar los datos del gestor'),
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
                  Icons.calendar_today,
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
        Text(
          'KPIs por Rango de Fechas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
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
                      Icons.insights,
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
            _buildKpiCard(
              'Pendientes',
              supervisorProvider.rangePendingCount.toString(),
              Colors.orange,
              Icons.pending_actions,
            ),
            _buildKpiCard(
              'Completados',
              supervisorProvider.rangeCompletedCount.toString(),
              Colors.green,
              Icons.check_circle,
            ),
            _buildKpiCard(
              'Recaudado',
              currencyFormat.format(supervisorProvider.rangeCollectedAmount),
              Colors.blue,
              Icons.payments,
            ),
            _buildKpiCard(
              'Total',
              currencyFormat.format(supervisorProvider.rangeTotalAmount),
              Colors.purple,
              Icons.trending_up,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eficiencia de Desembolsos',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
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
              Text(
                'Desemb: ${currencyFormat.format(supervisorProvider.totalDisbursed)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Esp: ${currencyFormat.format(supervisorProvider.expectedAmount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Detalle de Préstamos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          if (supervisorProvider.dailyLoans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No hay préstamos para mostrar',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
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
                final saldoActual = (loan['total_amount'] ?? 0.0) - totalPagado;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            AutoSizeText(
                              currencyFormat.format(loan['loan_amount'] ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              minFontSize: 9,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loan['partner_id'] != null
                              ? loan['partner_id'][1]
                              : 'Cliente sin nombre',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loan['create_date'] != null
                                  ? 'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['create_date']))}'
                                  : 'Fecha: No disponible',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange[300]!,
                        ),
                      ),
                      child: Text(
                        loan['state'] ?? 'Pendiente',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildLoanDetailRow(
                              'Monto del Préstamo',
                              currencyFormat.format(loan['loan_amount'] ?? 0),
                            ),
                            const SizedBox(height: 8),
                            _buildLoanDetailRow(
                              'Interés',
                              currencyFormat.format(loan['profit'] ?? 0),
                            ),
                            const SizedBox(height: 8),
                            _buildLoanDetailRow(
                              'Total a Pagar',
                              currencyFormat.format(loan['total_amount'] ?? 0),
                              isTotal: true,
                            ),
                            const SizedBox(height: 8),
                            _buildLoanDetailRow(
                              'Total Pagado',
                              currencyFormat.format(totalPagado),
                            ),
                            const SizedBox(height: 8),
                            _buildLoanDetailRow(
                              'Saldo actual',
                              currencyFormat.format(saldoActual),
                              isTotal: true,
                              isOverdue: true,
                            ),
                          ],
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
      {bool isTotal = false, bool isOverdue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isTotal || isOverdue ? FontWeight.bold : FontWeight.normal,
            color: isOverdue
                ? Colors.orange
                : (isTotal ? AppTheme.colorScheme.primary : Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
