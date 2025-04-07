import 'package:flutter/material.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/profile_drawer.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/status_badge.dart';

class GestorDashboard extends StatefulWidget {
  const GestorDashboard({Key? key}) : super(key: key);

  @override
  State<GestorDashboard> createState() => _GestorDashboardState();
}

class _GestorDashboardState extends State<GestorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mock data
  final int totalCobros = 15;
  final int cobrosRealizados = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final porcentajeAvance = (cobrosRealizados / totalCobros) * 100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Panel Gestor'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Mostrar notificaciones
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No tienes notificaciones nuevas'),
                  backgroundColor: AppTheme.colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      drawer: ProfileDrawer(
        userName: 'Roberto Gómez',
        userRole: 'Gestor',
        userEmail: 'gestor@yatha.com',
        menuItems: [
          DrawerMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          DrawerMenuItem(
            title: 'Préstamos',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
          DrawerMenuItem(
            title: 'Mapa de Clientes',
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          DrawerMenuItem(
            title: 'Clientes',
            icon: Icons.people_outline,
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(2);
            },
          ),
          DrawerMenuItem(
            title: 'Reportes',
            icon: Icons.bar_chart_outlined,
            onTap: () {
              Navigator.pop(context);
              // Navegar a reportes
            },
          ),
          DrawerMenuItem(
            title: 'Configuración',
            icon: Icons.settings_outlined,
            onTap: () {
              Navigator.pop(context);
              // Navegar a configuración
            },
          ),
        ],
        onLogout: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
      body: Column(
        children: [
          // Dashboard summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
              child: GlassContainer(
                blur: 10,
                backgroundColor: AppTheme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cobros de Hoy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: AppTheme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$cobrosRealizados/$totalCobros',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${porcentajeAvance.toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProgressIndicatorWidget(
                      value: porcentajeAvance / 100,
                      height: 12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completado: ${porcentajeAvance.toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: AppTheme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.colorScheme.primary,
              unselectedLabelColor: AppTheme.colorScheme.onSurfaceVariant,
              indicatorColor: AppTheme.colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  text: 'Préstamos',
                ),
                Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
                Tab(icon: Icon(Icons.people_outline), text: 'Clientes'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Préstamos tab
                _buildLoansTab(),

                // Mapa tab
                _buildMapTab(),

                // Clientes tab
                _buildClientsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción según la pestaña activa
          switch (_tabController.index) {
            case 0:
              // Registrar nuevo préstamo
              _showSnackBar('Registrar nuevo préstamo');
              break;
            case 1:
              // Actualizar mapa
              _showSnackBar('Actualizando mapa...');
              break;
            case 2:
              // Agregar nuevo cliente
              _showSnackBar('Agregar nuevo cliente');
              break;
          }
        },
        backgroundColor: AppTheme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.colorScheme.primary,
      ),
    );
  }

  Widget _buildLoansTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Préstamos Pendientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Lista de préstamos con cobros programados para hoy',
            style: TextStyle(
              color: AppTheme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: MockData.loansData.length,
              itemBuilder: (context, index) {
                final loan = MockData.loansData.values.elementAt(index);
                return _buildLoanItem(
                  loan.id,
                  loan.clientName,
                  loan.loanNumber,
                  loan.installments.first.amount,
                  loan.status,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(
    String id,
    String name,
    String loanNumber,
    double amount,
    String status,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/gestor/loan-detail', arguments: id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar del cliente
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.colorScheme.primaryContainer,
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del préstamo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Préstamo #$loanNumber',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Monto y estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        // Fondo del mapa (simulado)
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.imgur.com/JIgMdnQ.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Overlay con efecto de vidrio
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: GlassContainer(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clientes Cercanos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se encontraron 5 clientes en un radio de 2 km',
                  style: TextStyle(
                    color: AppTheme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedButton(
                      onPressed: () {
                        _showSnackBar('Actualizando ubicación...');
                      },
                      height: 40,
                      width: 150,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.my_location, size: 16),
                          SizedBox(width: 8),
                          Text('Mi Ubicación'),
                        ],
                      ),
                    ),
                    AnimatedButton(
                      onPressed: () {
                        _showSnackBar('Optimizando ruta...');
                      },
                      height: 40,
                      width: 150,
                      color: AppTheme.colorScheme.secondary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.route, size: 16),
                          SizedBox(width: 8),
                          Text('Optimizar Ruta'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientsTab() {
    // Flatten all clients from all gestores for demo purposes
    final allClients =
        MockData.gestoresData.values
            .expand((gestor) => gestor.clientes)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Clientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Lista de clientes asignados',
            style: TextStyle(
              color: AppTheme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.colorScheme.primary,
              ),
              filled: true,
              fillColor: AppTheme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: allClients.length,
              itemBuilder: (context, index) {
                final client = allClients[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar del cliente
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppTheme.colorScheme.secondaryContainer,
                          child: Text(
                            client.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Información del cliente
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${client.prestamos} préstamos activos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Estado y botón
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: client.estado),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Text('Ver detalle'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
