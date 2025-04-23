import 'package:flutter/material.dart';

class PrestamoCard extends StatelessWidget {
  final Map<String, dynamic> prestamo;

  const PrestamoCard({Key? key, required this.prestamo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clientName =
        prestamo['partner_id'] is List
            ? prestamo['partner_id'][1]
            : 'Cliente sin nombre';
    final amount = prestamo['loan_amount'] ?? 0.0;
    final status = prestamo['loan_status'] ?? 'pending';
    final paymentPeriod = prestamo['payment_period'] ?? 'unknown';

    // Determinar color y texto del estado
    Color statusColor;
    String statusText;
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Pagado';
        break;
      case 'on_time':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'late':
        statusColor = Colors.red;
        statusText = 'Vencido';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pendiente';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'S/. ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              paymentPeriod == 'monthly'
                  ? 'Préstamo Mensual'
                  : 'Préstamo Diario',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
