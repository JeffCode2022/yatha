import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/providers/supervisor_provider.dart';
import 'package:yatha_app/widgets/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(-12.0464, -77.0428); // Lima, Perú

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    await supervisorProvider.loadGestores();
  }

  Future<void> _loadMapData() async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    if (supervisorProvider.selectedGestorId != null) {
      await supervisorProvider.loadGestorClientLocations(
        supervisorProvider.selectedGestorId!,
        supervisorProvider.selectedDate,
      );

      // Centrar el mapa en las ubicaciones del gestor
      if (supervisorProvider.clientLocations.isNotEmpty) {
        _centerMapOnLocations(supervisorProvider.clientLocations);
      }
    }
  }

  void _centerMapOnLocations(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return;

    // Calcular el centro de todas las ubicaciones
    double sumLat = 0;
    double sumLng = 0;
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final location in locations) {
      final lat = location['latitude'] as double;
      final lng = location['longitude'] as double;

      sumLat += lat;
      sumLng += lng;

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    final centerLat = sumLat / locations.length;
    final centerLng = sumLng / locations.length;

    // Calcular el zoom apropiado basado en la dispersión de los puntos
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final maxSpan = math.max(latSpan, lngSpan);

    // Ajustar el zoom según la dispersión (valores ajustados empíricamente)
    double zoom = 13.0;
    if (maxSpan > 0.1) zoom = 12.0;
    if (maxSpan > 0.5) zoom = 11.0;
    if (maxSpan > 1.0) zoom = 10.0;

    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  Future<void> _selectDate(BuildContext context) async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year, 12, 31);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: supervisorProvider.selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != supervisorProvider.selectedDate) {
      supervisorProvider.selectedDate = picked;
      _loadMapData();
    }
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> locations) {
    print('Building markers for ${locations.length} locations');
    return locations.map((location) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      final clientName = location['client_name'] as String?;
      final amount = location['amount'] as double?;
      final status = location['status'] as String?;

      print('Creating marker for client: $clientName at ($lat, $lng)');

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 70,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Detalle del Cliente'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente: ${clientName ?? 'No disponible'}'),
                      Text('Monto: S/ ${amount?.toStringAsFixed(2) ?? '0.00'}'),
                      Text('Estado: ${_getStatusText(status)}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                );
              },
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  'S/ ${amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.location_on,
                color: _getStatusColor(status),
                size: 30,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'pending':
        return 'Pendiente';
      default:
        return 'No disponible';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupervisorProvider>(
      builder: (context, supervisorProvider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        value: supervisorProvider.selectedGestorId,
                        items: supervisorProvider.gestores.map((gestor) {
                          return DropdownMenuItem<String>(
                            value: gestor['id'].toString(),
                            child: Text(gestor['name'] ?? 'Sin nombre'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            supervisorProvider.selectedGestorId = newValue;
                            _loadMapData();
                          }
                        },
                        hint: const Text('Seleccione un gestor'),
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
            ),
            if (supervisorProvider.selectedGestorId != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(supervisorProvider.selectedDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            Expanded(
              child: supervisorProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : supervisorProvider.selectedGestorId == null
                      ? const Center(
                          child: Text(
                              'Seleccione un gestor para ver el mapa de clientes'),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _defaultCenter,
                            initialZoom: 13.0,
                            maxZoom: 18.0,
                            minZoom: 3.0,
                            keepAlive: true,
                            interactionOptions: const InteractionOptions(
                              enableScrollWheel: true,
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.yatha.app',
                              maxZoom: 18,
                              minZoom: 3,
                              keepBuffer: 2,
                              backgroundColor: Colors.grey[200],
                              tileBuilder: (context, widget, tile) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: widget,
                                );
                              },
                            ),
                            MarkerLayer(
                              markers: _buildMarkers(
                                  supervisorProvider.clientLocations),
                            ),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}
