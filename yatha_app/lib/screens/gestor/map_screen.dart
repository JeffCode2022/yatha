import 'package:flutter/material.dart';
import 'package:yatha_app/widgets/mapa_gestor_widget.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simulación de pantalla de mapa
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Mapa de Cobros',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta funcionalidad requiere implementación\ncon servicios de mapas y geolocalización.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          MapaGestorWidget(),
        ],
      ),
    );
  }
}
