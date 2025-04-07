import 'package:flutter/material.dart';
import '../../services/mock_data.dart';
import '../../models/loan.dart';

class LoanDetailScreen extends StatelessWidget {
  const LoanDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loanId = ModalRoute.of(context)!.settings.arguments as String? ?? "1";
    final loan = MockData.loansData[loanId];

    if (loan == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Préstamo'),
        ),
        body: const Center(
          child: Text('Préstamo no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Préstamo'),
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
            // Client information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Cliente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person, loan.clientName),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, loan.clientPhone),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'Ver ubicación'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loan details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Préstamo #${loan.loanNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monto total: \$${loan.amount.toStringAsFixed(2)} - ${loan.term} cuotas',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Installments table
                    _buildInstallmentsTable(loan.installments),
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Historial de pagos'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Registrar pago'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildInstallmentsTable(List<Installment> installments) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 1, child: Text('Cuota', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        ),
        
        // Table rows
        ...installments.map((installment) {
          Color statusColor;
          switch (installment.status) {
            case 'Pagada':
              statusColor = Colors.green;
              break;
            case 'Vencida':
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
                Expanded(flex: 1, child: Text('${installment.id}')),
                Expanded(flex: 2, child: Text(installment.dueDate)),
                Expanded(flex: 2, child: Text('\$${installment.amount.toStringAsFixed(2)}')),
                Expanded(
                  flex: 2, 
                  child: Text(
                    installment.status,
                    style: TextStyle(color: statusColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: installment.status != 'Pagada'
                      ? ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 32),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, size: 16),
                              SizedBox(width: 4),
                              Text('Cobrar'),
                            ],
                          ),
                        )
                      : const SizedBox(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

