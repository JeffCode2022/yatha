import 'package:flutter/material.dart';
import '../../services/mock_data.dart';

class GestorDetailScreen extends StatelessWidget {
  const GestorDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gestorId = ModalRoute.of(context)!.settings.arguments as String? ?? "1";
    final gestor = MockData.gestoresData[gestorId];

    if (gestor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Gestor'),
        ),
        body: const Center(
          child: Text('Gestor no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Gestor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gestor information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Gestor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          gestor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Cobros realizados', '${gestor.cobrosRealizados}/${gestor.totalCobros}'),
                        _buildStatColumn('Porcentaje', '${gestor.porcentajeAvance}%'),
                        _buildStatColumn('Clientes', '${gestor.clientes.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Clients table card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clientes Asignados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lista de clientes asignados a ${gestor.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Préstamos', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Cobros Hoy', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    
                    // Table rows
                    ...gestor.clientes.map((cliente) {
                      Color statusColor;
                      switch (cliente.estado) {
                        case 'Al día':
                          statusColor = Colors.green;
                          break;
                        case 'Vencido':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(cliente.name)),
                            Expanded(flex: 2, child: Text('${cliente.prestamos}')),
                            Expanded(flex: 2, child: Text('${cliente.cobrosHoy}')),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                cliente.estado,
                                style: TextStyle(color: statusColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: const Text('Ver detalle'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

