import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/base_screen.dart';

class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  final MapController _mapController = MapController();
  int? _selectedVendedorId;
  String _selectedFilter = 'todos';
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/.',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().loadClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Mapa de Clientes',
      body: Consumer2<ClienteProvider, AuthProvider>(
        builder: (context, clienteProvider, authProvider, _) {
          if (clienteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (clienteProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${clienteProvider.error}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontSize: 14,
                    ),
              ),
            );
          }

          return Column(
            children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedVendedorId,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los vendedores'),
                          ),
                          // Aquí deberías agregar los vendedores disponibles
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedVendedorId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filtro',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'activos',
                            child: Text('Activos'),
                          ),
                          DropdownMenuItem(
                            value: 'inactivos',
                            child: Text('Inactivos'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Mapa
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-12.0464, -77.0428),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.yatha.app',
                    ),
                    MarkerLayer(markers: _buildMarkers(clienteProvider)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(ClienteProvider provider) {
    List<Map<String, dynamic>> clientesFiltrados = provider.loans;

    // Aplicar filtro de vendedor
    if (_selectedVendedorId != null) {
      clientesFiltrados = provider.filtrarPorVendedor(_selectedVendedorId!);
    }

    // Aplicar filtro de estado
    if (_selectedFilter != 'todos') {
      clientesFiltrados = clientesFiltrados.where((cliente) {
        return _selectedFilter == 'activos'
            ? cliente['estado'] == 'activo'
            : cliente['estado'] == 'inactivo';
      }).toList();
    }

    return clientesFiltrados.map((cliente) {
      final lat = cliente['partner_latitude'] as double?;
      final lng = cliente['partner_longitude'] as double?;
      final monto = cliente['payment_amount'] as double?;

      if (lat == null || lng == null) {
        return Marker(
          point: const LatLng(0, 0),
          child: const Icon(Icons.location_off, color: Colors.grey),
        );
      }

      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                monto != null ? _currencyFormat.format(monto) : 'S/.0.00',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                  height: 1.4,
                  color: const Color(0xFF4CAF50),
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.location_on,
              color: _selectedFilter == 'activos' ? Colors.green : Colors.red,
              size: 40,
            ),
          ],
        ),
      );
    }).toList();
  }
}
