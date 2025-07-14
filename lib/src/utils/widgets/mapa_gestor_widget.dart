import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../../services/cliente_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../utils/theme/app_theme.dart';
import 'package:lottie/lottie.dart' as lottie;

class CustomTileProvider extends TileProvider {
  final http.Client _client = http.Client();
  bool _disposed = false;
  final Map<String, Uint8List> _cache = {};
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  @override
  void dispose() {
    if (!_disposed) {
      _client.close();
      _disposed = true;
    }
    super.dispose();
  }

  Future<Uint8List?> _fetchTileWithRetry(String url, int retryCount) async {
    try {
      // Verificar si está en caché
      if (_cache.containsKey(url)) {
        return _cache[url];
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'yatha_app/1.0',
          'Accept': 'image/png',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Guardar en caché
        _cache[url] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
        return _fetchTileWithRetry(url, retryCount + 1);
      }
    }
    return null;
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return ResizeImage(
      NetworkImage(
        url,
        headers: const {
          'User-Agent': 'yatha_app/1.0',
          'Accept': 'image/png',
        },
      ),
      width: 256,
      height: 256,
    );
  }

  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final servers = ['a', 'b', 'c'];
    final server = servers[coordinates.x % servers.length];
    return 'https://$server.tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
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
  bool _isMapReady = false;
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
          SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.location_slash,
                    color: Colors.white,
                    size: 16), // Iconsax para ubicación desactivada
                const SizedBox(width: 8),
                const Text('Por favor activa el GPS'),
              ],
            ),
          ),
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
            SnackBar(
              content: Row(
                children: [
                  Icon(Iconsax.location_slash,
                      color: Colors.white,
                      size: 16), // Iconsax para ubicación desactivada
                  const SizedBox(width: 8),
                  const Text('Se necesitan permisos de ubicación'),
                ],
              ),
            ),
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
        width: 28,
        height: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo con punto (verde)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Línea vertical
            Container(
              width: 2,
              height: 16,
              color: Colors.green,
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

      // Agrupar préstamos por lat/lng SOLO si tienen lat/lng válidos
      Map<String, List<Map<String, dynamic>>> prestamosPorUbicacion = {};
      for (var prestamo in prestamos) {
        final latRaw = prestamo['partner_latitude'];
        final lngRaw = prestamo['partner_longitude'];
        if (latRaw == null || lngRaw == null) continue;
        final lat = double.tryParse(latRaw.toString()) ?? 0.0;
        final lng = double.tryParse(lngRaw.toString()) ?? 0.0;
        if (lat == 0.0 && lng == 0.0) continue;
        final key = '$lat,$lng';
        if (!prestamosPorUbicacion.containsKey(key)) {
          prestamosPorUbicacion[key] = [];
        }
        prestamosPorUbicacion[key]!.add(prestamo);
      }

      // Crear un marcador por ubicación
      prestamosPorUbicacion.forEach((key, prestamosEnUbicacion) {
        final double lat = double.tryParse(
                prestamosEnUbicacion[0]['partner_latitude'].toString()) ??
            0;
        final double lng = double.tryParse(
                prestamosEnUbicacion[0]['partner_longitude'].toString()) ??
            0;
        if (lat != 0 && lng != 0) {
          final marker = Marker(
            point: LatLng(lat, lng),
            width: 28,
            height: 44,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Iconsax.wallet,
                            color: Colors
                                .green), // Iconsax en lugar de Material Icons
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Préstamos en esta ubicación',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: double.maxFinite,
                      height: MediaQuery.of(context).size.height *
                          0.5, // Altura máxima del modal
                      child: ListView.builder(
                        itemCount: prestamosEnUbicacion.length,
                        itemBuilder: (context, index) {
                          final prestamo = prestamosEnUbicacion[index];
                          return ListTile(
                            leading: Icon(Iconsax.profile_circle,
                                color: Colors.green),
                            title: Text(
                              prestamo['partner_id'] != null &&
                                      prestamo['partner_id'] is List
                                  ? prestamo['partner_id'][1]
                                  : 'Sin nombre',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Préstamo: ${prestamo['name'] ?? ''}'),
                                Text(
                                    'Monto: S/. ${(prestamo['amount'] ?? 0.0).toStringAsFixed(2)}'),
                                Text(
                                    'Dirección: ${prestamo['partner_address'] ?? 'No disponible'}'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () {
                          final double lat = double.tryParse(
                                  prestamosEnUbicacion[0]['partner_latitude']
                                      .toString()) ??
                              0.0;
                          final double lng = double.tryParse(
                                  prestamosEnUbicacion[0]['partner_longitude']
                                      .toString()) ??
                              0.0;
                          final url =
                              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                          launchUrl(Uri.parse(url));
                        },
                        icon: Icon(Iconsax.routing, size: 16),
                        label: const Text('Abrir en Maps'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Iconsax.close_circle, size: 16),
                        label: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Círculo con punto
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Línea vertical
                  Container(
                    width: 2,
                    height: 16,
                    color: Colors.black,
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
      });

      if (mounted) {
        _centerMap();
      }
    } catch (e) {
      print('Error al cargar préstamos: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.danger,
                  color: Colors.white, size: 16), // Iconsax para error
              const SizedBox(width: 8),
              const Text('Error al cargar los préstamos'),
            ],
          ),
        ),
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
        title: Row(
          children: [
            Icon(Iconsax.profile_circle,
                color: Colors.green), // Iconsax en lugar de Material Icons
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prestamo['partner_id'] != null && prestamo['partner_id'] is List
                    ? prestamo['partner_id'][1]
                    : 'Sin nombre',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.document,
                    size: 16,
                    color:
                        Colors.grey[700]), // Iconsax en lugar de Material Icons
                const SizedBox(width: 8),
                Text(
                  'Préstamo: ${prestamo['name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.money,
                    size: 16,
                    color: Colors.green), // Iconsax en lugar de Material Icons
                const SizedBox(width: 8),
                Text(
                  'Monto a cobrar: S/. ${(prestamo['amount'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.calendar,
                    size: 16,
                    color:
                        Colors.grey[700]), // Iconsax en lugar de Material Icons
                const SizedBox(width: 8),
                Text(
                  'Fecha de cobro: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Iconsax.location,
                    size: 16,
                    color:
                        Colors.grey[700]), // Iconsax en lugar de Material Icons
                const SizedBox(width: 8),
                const Text(
                  'Dirección:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Text(prestamo['partner_address'] ?? 'No disponible'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(position),
                icon:
                    Icon(Iconsax.routing), // Iconsax en lugar de Material Icons
                label: const Text('Abrir en Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Iconsax.close_circle,
                size: 16), // Iconsax en lugar de Material Icons
            label: const Text('Cerrar'),
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
          SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.danger,
                    color: Colors.white, size: 16), // Iconsax para error
                const SizedBox(width: 8),
                const Text('No se pudo abrir el mapa'),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)
                : _defaultLocation,
            initialZoom: 13.0,
            maxZoom: 18.0,
            keepAlive: true,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
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
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              tileProvider: _tileProvider,
              maxZoom: 18.0,
              tileBuilder: (context, child, tile) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: child,
                );
              },
              errorImage:
                  Image.asset('assets/images/map_placeholder.png').image,
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        // Botones de zoom
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              Container(
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
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.search_zoom_in,
                        color: AppTheme.colorScheme.primary,
                      ), // Iconsax en lugar de Material Icons
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom + 1,
                        );
                      },
                      tooltip: 'Acercar',
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    IconButton(
                      icon: Icon(
                        Iconsax.search_zoom_out,
                        color: AppTheme.colorScheme.primary,
                      ), // Iconsax en lugar de Material Icons
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom - 1,
                        );
                      },
                      tooltip: 'Alejar',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoading || !_isMapReady)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child:
                          lottie.Lottie.asset('assets/animations/loading.json'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cargando mapa...',
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
                  color: Colors.white
                      .withOpacity(0.25), // Más transparente para glass
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
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
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.calendar,
                                size: 16,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.5),
                                child: Text(
                                  'Cobros del ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Badge de cantidad de cobros
                              if (_prestamos.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.green.shade600.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.shade200
                                            .withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.money,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_prestamos.length} ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _prestamos.length == 1
                                            ? 'cobro'
                                            : 'cobros',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                                    Row(
                                      children: [
                                        Icon(
                                          Iconsax
                                              .profile_circle, // Iconsax en lugar de Material Icons
                                          size: 14,
                                          color: Colors.black87,
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: constraints.maxWidth - 18,
                                          child: Text(
                                            prestamo['partner_id'] != null &&
                                                    prestamo['partner_id']
                                                        is List
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
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Iconsax
                                              .document, // Iconsax en lugar de Material Icons
                                          size: 12,
                                          color: Color(0xFF8E8E93),
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: constraints.maxWidth - 16,
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
