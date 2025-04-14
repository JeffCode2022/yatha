import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/cliente_service.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;

class CustomTileProvider extends TileProvider {
  final http.Client _client = http.Client();
  bool _disposed = false;

  @override
  void dispose() {
    if (!_disposed) {
      _client.close();
      _disposed = true;
    }
    super.dispose();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return NetworkImage(
      url,
      headers: const {
        'User-Agent': 'yatha_app/1.0',
      },
    );
  }

  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    return 'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
  }
}

class MapaGestorWidget extends StatefulWidget {
  final DateTime selectedDate;

  const MapaGestorWidget({
    super.key,
    required this.selectedDate,
  });

  @override
  State<MapaGestorWidget> createState() => _MapaGestorWidgetState();
}

class _MapaGestorWidgetState extends State<MapaGestorWidget> {
  final ClienteService _clienteService = ClienteService();
  late final MapController _mapController;
  final List<Marker> _markers = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _retryingTiles = false;
  int _retryCount = 0;
  final CustomTileProvider _tileProvider = CustomTileProvider();
  static const LatLng _defaultLocation =
      LatLng(-12.0464, -77.0428); // Lima, Perú
  List<Map<String, dynamic>> _prestamos = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _tileProvider.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor activa el GPS')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;

        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se necesitan permisos de ubicación')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoading = true;
      });

      _addCurrentLocationMarker();
      await _loadPrestamos();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print('Error al obtener ubicación: $e');
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      final marker = Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 120,
        height: 120,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[600]!,
                    Colors.blue[400]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Mi ubicación',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      );

      setState(() {
        _markers.clear();
        _markers.add(marker);
      });
    }
  }

  Future<void> _loadPrestamos() async {
    if (!mounted) return;

    try {
      print('Obteniendo préstamos para la fecha: ${widget.selectedDate}');
      final prestamos =
          await _clienteService.obtenerClientes(fecha: widget.selectedDate);
      print('Préstamos obtenidos: ${prestamos.length}');

      if (!mounted) return;

      setState(() {
        _prestamos = prestamos;
        _markers.clear();
        if (_currentPosition != null) {
          _addCurrentLocationMarker();
        }
      });

      for (var prestamo in prestamos) {
        if (!mounted) return;

        final double lat =
            double.tryParse(prestamo['partner_latitude'].toString()) ?? 0;
        final double lng =
            double.tryParse(prestamo['partner_longitude'].toString()) ?? 0;

        if (lat != 0 && lng != 0) {
          final marker = Marker(
            point: LatLng(lat, lng),
            width: 120,
            height: 120,
            child: GestureDetector(
              onTap: () => _showPrestamoDetails(prestamo),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[600]!,
                          Colors.green[400]!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.green[600],
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      prestamo['partner_id'] != null &&
                              prestamo['partner_id'] is List
                          ? prestamo['partner_id'][1]
                          : 'Sin nombre',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (mounted) {
            setState(() {
              _markers.add(marker);
            });
          }
        }
      }

      if (mounted) {
        _centerMap();
      }
    } catch (e) {
      print('Error al cargar préstamos: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los préstamos')),
      );
    }
  }

  void _centerMap() {
    if (_markers.isEmpty) return;

    if (_markers.length == 1) {
      _mapController.move(_markers[0].point, 15);
      return;
    }

    double minLat = _markers[0].point.latitude;
    double maxLat = _markers[0].point.latitude;
    double minLng = _markers[0].point.longitude;
    double maxLng = _markers[0].point.longitude;

    for (var marker in _markers) {
      minLat = marker.point.latitude < minLat ? marker.point.latitude : minLat;
      maxLat = marker.point.latitude > maxLat ? marker.point.latitude : maxLat;
      minLng =
          marker.point.longitude < minLng ? marker.point.longitude : minLng;
      maxLng =
          marker.point.longitude > maxLng ? marker.point.longitude : maxLng;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 12);
  }

  void _showPrestamoDetails(Map<String, dynamic> prestamo) {
    final LatLng position = LatLng(
      double.parse(prestamo['partner_latitude'].toString()),
      double.parse(prestamo['partner_longitude'].toString()),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prestamo['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${prestamo['partner_id'][1]}'),
            const SizedBox(height: 8),
            Text(
              'Fecha de cobro: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInMaps(position),
              icon: const Icon(Icons.directions),
              label: const Text('Abrir en Maps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(LatLng position) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}';
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'No se pudo abrir el mapa';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa')),
        );
      }
    }
  }

  void _handleTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    developer.log('Error cargando tile: $error');
    if (_retryCount < 3 && mounted && !_retryingTiles) {
      setState(() {
        _retryingTiles = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _retryCount++;
            _retryingTiles = false;
          });
        }
      });
    }
  }

  Widget _buildErrorTile(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.map_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)
                : _defaultLocation,
            zoom: 13.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.yatha.app',
              tileProvider: _tileProvider,
              errorImage: const AssetImage('assets/map_placeholder.png'),
              errorTileCallback: (tile, error, stackTrace) {
                developer.log(
                  'Error loading tile',
                  error: error,
                  stackTrace: stackTrace,
                );
              },
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (_retryingTiles)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Recargando mapa...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Cobros del ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF34C759).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_prestamos.length} clientes',
                            style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_prestamos.isNotEmpty) ...[
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE5E5EA),
                      ),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _prestamos.length,
                          itemBuilder: (context, index) {
                            final prestamo = _prestamos[index];
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E5EA),
                                  width: 1,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: Text(
                                        prestamo['partner_id'] != null &&
                                                prestamo['partner_id'] is List
                                            ? prestamo['partner_id'][1]
                                            : 'Sin nombre',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: Text(
                                        'Préstamo: ${prestamo['name']}',
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 13,
                                          letterSpacing: -0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
