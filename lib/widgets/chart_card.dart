import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final Map<String, double> data;

  const ChartCard({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        'No hay datos disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : BarChart(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class BarChart extends StatelessWidget {
  final Map<String, double> data;

  const BarChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.entries.map((entry) {
        final day = entry.key;
        final value = entry.value;
        final percentage = value / maxValue;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 150 * percentage,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
