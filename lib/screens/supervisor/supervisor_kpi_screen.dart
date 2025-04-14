import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/providers/supervisor_provider.dart';
import 'package:yatha_app/widgets/glass_container.dart';
import 'package:intl/intl.dart';

class SupervisorKpiScreen extends StatefulWidget {
  const SupervisorKpiScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorKpiScreen> createState() => _SupervisorKpiScreenState();
}

class _SupervisorKpiScreenState extends State<SupervisorKpiScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGestorId;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    await supervisorProvider.loadGestores();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadKpiData() async {
    if (_selectedGestorId != null) {
      final supervisorProvider =
          Provider.of<SupervisorProvider>(context, listen: false);
      await supervisorProvider.loadGestorKPIs(
          _selectedGestorId!, _selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year, 12, 31);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(lastDate) ? lastDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadKpiData();
    }
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    String? subtitle,
    bool showProgress = false,
    double? progressValue,
  }) {
    return GlassContainer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                if (showProgress && progressValue != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(progressValue * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
            if (showProgress && progressValue != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownGestor(SupervisorProvider supervisorProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Seleccionar Gestor',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: _selectedGestorId,
        items: supervisorProvider.gestores.map((gestor) {
          return DropdownMenuItem<String>(
            value: gestor['id'].toString(),
            child: Text(gestor['name'] ?? 'Sin nombre'),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGestorId = newValue;
          });
          _loadKpiData();
        },
        hint: const Text('Seleccione un gestor'),
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<SupervisorProvider>(
          builder: (context, supervisorProvider, _) {
            if (supervisorProvider.error != null) {
              return _buildErrorWidget(supervisorProvider.error!);
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: supervisorProvider.isLoading &&
                                    !supervisorProvider.isInitialized
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _buildDropdownGestor(supervisorProvider),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.calendar_today),
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedGestorId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (supervisorProvider.isLoading &&
                    supervisorProvider.isInitialized)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_selectedGestorId == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Seleccione un gestor para ver sus KPIs',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: _loadKpiData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              _buildKpiCard(
                                title: 'Progreso General',
                                value:
                                    '${(supervisorProvider.progressPercentage * 100).toStringAsFixed(1)}%',
                                icon: Icons.trending_up,
                                gradientColors: [
                                  Colors.blue,
                                  Colors.blue.shade800,
                                ],
                                showProgress: true,
                                progressValue:
                                    supervisorProvider.progressPercentage,
                                subtitle: 'Meta diaria',
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Pagos Pendientes',
                                      value:
                                          '${supervisorProvider.getPendingPaymentsCount()}',
                                      icon: Icons.pending_actions,
                                      gradientColors: [
                                        Colors.orange,
                                        Colors.deepOrange,
                                      ],
                                      subtitle: 'Por cobrar',
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Pagos Completados',
                                      value:
                                          '${supervisorProvider.getCompletedPaymentsCount()}',
                                      icon: Icons.check_circle,
                                      gradientColors: [
                                        Colors.green,
                                        Colors.green.shade800,
                                      ],
                                      subtitle: 'Al día',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildKpiCard(
                                title: 'Monto Total Cobrado',
                                value:
                                    'S/ ${supervisorProvider.getCollectedAmount().toStringAsFixed(2)}',
                                icon: Icons.monetization_on,
                                gradientColors: [
                                  Colors.purple,
                                  Colors.deepPurple,
                                ],
                                subtitle:
                                    'De S/ ${supervisorProvider.getTotalAmount().toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
