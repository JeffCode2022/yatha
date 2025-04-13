import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/cliente_service.dart';

class MapaGestorWidget extends StatefulWidget {
  const MapaGestorWidget({Key? key}) : super(key: key);

  @override
  State<MapaGestorWidget> createState() => _MapaGestorWidgetState();
}

class _MapaGestorWidgetState extends State<MapaGestorWidget> {
  final _clienteService = ClienteService();
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;

  static const LatLng _centroInicial = LatLng(-12.046374, -77.042793); // Lima

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    if (!mounted) return;

    try {
      final clientes = await _clienteService.obtenerClientes();

      if (!mounted) return;

      setState(() {
        _markers.clear();
        for (var cliente in clientes) {
          if (cliente['partner_latitude'] != null &&
              cliente['partner_longitude'] != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(cliente['id'].toString()),
                position: LatLng(
                  double.parse(cliente['partner_latitude'].toString()),
                  double.parse(cliente['partner_longitude'].toString()),
                ),
                infoWindow: InfoWindow(
                  title: cliente['name'],
                  snippet: 'Tel: ${cliente['mobile']}',
                ),
              ),
            );
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Puedes ajustar la altura según tu diseño
      child: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _centroInicial,
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _cargarClientes,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
