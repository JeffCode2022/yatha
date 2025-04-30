import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatha_app/src/providers/supervisor_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../utils/theme/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// Cliente HTTP global persistente para toda la aplicación
final http.Client _globalHttpClient = http.Client();

class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(-12.0464, -77.0428); // Lima, Perú
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentTileProvider = 0;
  bool _mapLoadError = false;
  bool _isMapReady = false;
  int _failedTileCount = 0;
  static const int _maxFailedTiles = 5;

  // Lista de proveedores de tiles más confiables
  final List<String> _tileProviders = [
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://a.tile.opentopomap.org/{z}/{x}/{y}.png', // Alternativa más confiable
    'https://b.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    'https://c.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  ];

  String get currentTileProvider => _tileProviders[_currentTileProvider];

  void _switchTileProvider() {
    if (!mounted) return;

    setState(() {
      _currentTileProvider = (_currentTileProvider + 1) % _tileProviders.length;
      _mapLoadError = false;
      _failedTileCount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Cambiando proveedor de mapas...',
          style: TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _checkConnectivityAndSwitchTileProvider() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoConnectionError();
    } else {
      _switchTileProvider();
    }
  }

  void _showNoConnectionError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No hay conexión a internet. Verifica tu conexión.',
          style: TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

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
    _animationController.dispose();
    // NO cerramos el cliente HTTP global aquí
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    await supervisorProvider.loadGestores();
  }

  Future<void> _loadMapData() async {
    final supervisorProvider =
        Provider.of<SupervisorProvider>(context, listen: false);
    if (supervisorProvider.selectedGestor != null) {
      await supervisorProvider.loadMapPendingClients(
        supervisorProvider.selectedGestor!.id,
        _selectedDate,
      );
      if (supervisorProvider.clientLocations.isNotEmpty) {
        _centerMapOnLocations(supervisorProvider.clientLocations);
      }

      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    }
  }

  void _centerMapOnLocations(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return;

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

    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final maxSpan = math.max(latSpan, lngSpan);

    double zoom = 13.0;
    if (maxSpan > 0.1) zoom = 12.0;
    if (maxSpan > 0.5) zoom = 11.0;
    if (maxSpan > 1.0) zoom = 10.0;

    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupervisorProvider>(
      builder: (context, supervisorProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildControlsSection(supervisorProvider),
                  if (supervisorProvider.selectedGestor != null)
                    _buildDateDisplay(),
                  Expanded(
                    child: _buildMapSection(supervisorProvider),
                  ),
                ],
              ),
            ),
          ),
          // Botón flotante para cambiar proveedor de tiles si hay error
          floatingActionButton: _mapLoadError
              ? FloatingActionButton.small(
                  onPressed: _checkConnectivityAndSwitchTileProvider,
                  backgroundColor: AppTheme.colorScheme.primary,
                  child: const Icon(Icons.refresh, size: 20),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMapSection(SupervisorProvider supervisorProvider) {
    if (supervisorProvider.isLoading) {
      return _buildLoadingState();
    }

    if (supervisorProvider.selectedGestor == null) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 13.0,
            maxZoom: 18.0,
            minZoom: 3.0,
            keepAlive: true,
            onMapEvent: (event) {
              if (!_isMapReady) {
                setState(() {
                  _isMapReady = true;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: currentTileProvider,
              userAgentPackageName: 'com.yatha.app',
              maxZoom: 18,
              minZoom: 3,
              // Usar nuestro proveedor de tiles personalizado
              tileProvider: _CustomTileProvider(),
              // Reducir el número de tiles en caché para evitar sobrecarga
              maxNativeZoom: 18,
              keepBuffer: 5,
              // Manejar errores de carga de tiles
              errorTileCallback: (tile, error, stackTrace) {
                if (mounted) {
                  _failedTileCount++;
                  if (_failedTileCount >= _maxFailedTiles && !_mapLoadError) {
                    setState(() {
                      _mapLoadError = true;
                    });
                  }
                }
              },
              tileBuilder: (context, child, tile) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: child,
                );
              },
            ),
            MarkerLayer(
              markers: _buildMarkers(supervisorProvider.clientLocations),
            ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _buildMapLegend(),
        ),
        if (_mapLoadError)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Error al cargar el mapa. Toca el botón para cambiar de proveedor.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        if (supervisorProvider.clientLocations.isEmpty &&
            !supervisorProvider.isLoading &&
            _isMapReady)
          _buildNoLocationsOverlay(),
      ],
    );
  }

  // Resto del código se mantiene igual...
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
      await _loadMapData();
    }
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> locations) {
    return locations.map((location) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      final clientName = location['client_name'] as String?;
      final amount = location['amount'] as double?;
      final status = location['status'] as String?;
      final isGestor = location['is_gestor'] as bool?;

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 70,
        child: GestureDetector(
          onTap: () {
            _showLocationDetails(clientName, amount, status, isGestor);
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  isGestor == true
                      ? 'Gestor'
                      : 'S/ ${amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                isGestor == true ? Icons.person_pin : Icons.location_on,
                color: isGestor == true
                    ? AppTheme.colorScheme.primary
                    : _getStatusColor(status),
                size: 30,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showLocationDetails(
      String? name, double? amount, String? status, bool? isGestor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isGestor == true ? Icons.person : Icons.person_outline,
                color: AppTheme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isGestor == true ? 'Detalle del Gestor' : 'Detalle del Cliente',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                isGestor == true ? 'Gestor:' : 'Cliente:',
                name ?? 'No disponible',
                isGestor == true ? Icons.person : Icons.person_outline,
              ),
              if (isGestor != true) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Monto:',
                  'S/ ${amount?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.attach_money,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Estado:',
                  _getStatusText(status),
                  Icons.info_outline,
                  valueColor: _getStatusColor(status),
                ),
              ],
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.colorScheme.primary,
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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

  Widget _buildControlsSection(SupervisorProvider supervisorProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  Icons.map,
                  color: AppTheme.colorScheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mapa de Gestores y Clientes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Gestor',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: supervisorProvider.selectedGestor?.id,
                    items: supervisorProvider.gestores.map((gestor) {
                      return DropdownMenuItem<String>(
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
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selectedGestor = supervisorProvider.gestores
                            .firstWhere((g) => g.id == newValue);
                        supervisorProvider.setSelectedGestor(selectedGestor);
                        _loadMapData();
                      }
                    },
                    hint: Text(
                      'Seleccione un gestor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  color: AppTheme.colorScheme.primary,
                  tooltip: 'Seleccionar fecha',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Fecha seleccionada:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Leyenda',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem('Gestor', AppTheme.colorScheme.primary),
          const SizedBox(height: 4),
          _buildLegendItem('Cliente Pendiente', Colors.red),
          const SizedBox(height: 4),
          _buildLegendItem('Cliente Pagado', Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label == 'Gestor' ? Icons.person_pin : Icons.location_on,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Text(
            'Cargando mapa...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                size: 48,
                color: Colors.blue[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione un gestor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seleccione un gestor para ver la ubicación de sus clientes en el mapa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationsOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No hay ubicaciones disponibles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron ubicaciones de clientes para este gestor en la fecha seleccionada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Proveedor de tiles personalizado que usa el cliente HTTP global
class _CustomTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);

    return NetworkImage(
      url,
      headers: {
        'User-Agent': 'YathaApp/1.0 (https://yatha.app)',
        'Accept': 'image/png,image/*;q=0.9',
        'Connection': 'keep-alive',
      },
    );
  }

  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final template = options.urlTemplate ?? '';
    return template
        .replaceAll('{z}', '${coordinates.z}')
        .replaceAll('{x}', '${coordinates.x}')
        .replaceAll('{y}', '${coordinates.y}');
  }
}
