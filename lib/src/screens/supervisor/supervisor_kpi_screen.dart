import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../src/providers/supervisor_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../utils/theme/app_theme.dart';
import '../../../utils/widgets/custom_dropdown.dart';
import '../../../utils/widgets/date_picker.dart';
import '../../models/gestor.dart';

class SupervisorKpiScreen extends StatefulWidget {
  const SupervisorKpiScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorKpiScreen> createState() => _SupervisorKpiScreenState();
}

class _SupervisorKpiScreenState extends State<SupervisorKpiScreen> {
  DateTime _selectedDate = DateTime.now();
  Gestor? _selectedGestor;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!_mounted) return;

    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    await supervisorProvider.loadGestores();

    if (!_mounted) return;

    if (supervisorProvider.gestores.isNotEmpty) {
      setState(() {
        _selectedGestor = supervisorProvider.gestores.first;
      });
      await _loadKpis();
    }
  }

  Future<void> _loadKpis() async {
    if (!_mounted || _selectedGestor == null) return;

    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    supervisorProvider.setSelectedGestor(_selectedGestor);
    supervisorProvider.setSelectedDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final supervisorProvider = Provider.of<SupervisorProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con selector de gestor y fecha
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown(
                      value: _selectedGestor?.id,
                      items: supervisorProvider.gestores.map((gestor) {
                        return DropdownMenuItem(
                          value: gestor.id,
                          child: Text(gestor.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (!mounted) return;
                        setState(() {
                          _selectedGestor = supervisorProvider.gestores
                              .firstWhere((g) => g.id == value);
                        });
                        _loadKpis();
                      },
                      hint: 'Seleccionar Gestor',
                    ),
                  ),
                  const SizedBox(width: 16),
                  DatePicker(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) {
                      if (!mounted) return;
                      setState(() {
                        _selectedDate = date;
                      });
                      _loadKpis();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Indicador de carga
              if (supervisorProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (supervisorProvider.errorMessage != null)
                Center(
                  child: Text(
                    supervisorProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de KPIs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de Pagos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  'Pendientes',
                                  supervisorProvider
                                      .getPendingPaymentsCount()
                                      .toString(),
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildKpiCard(
                                  'Completados',
                                  supervisorProvider
                                      .getCompletedPaymentsCount()
                                      .toString(),
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de pagos
                    if (supervisorProvider.kpiData['payments'] != null &&
                        (supervisorProvider.kpiData['payments'] as List)
                            .isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalle de Pagos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                (supervisorProvider.kpiData['payments'] as List)
                                    .length,
                            itemBuilder: (context, index) {
                              final payment =
                                  supervisorProvider.kpiData['payments'][index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(payment['partner_id'][1]),
                                  subtitle: Text(
                                    'Monto: \$${payment['payment_amount']}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: payment['payment_status'] == 'paid'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      payment['payment_status'] == 'paid'
                                          ? 'Completado'
                                          : 'Pendiente',
                                      style: TextStyle(
                                        color:
                                            payment['payment_status'] == 'paid'
                                                ? Colors.green
                                                : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      const Center(
                        child: Text('No hay pagos para mostrar'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
