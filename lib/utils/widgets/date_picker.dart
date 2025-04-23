import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const DatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year, 12, 31);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(lastDate) ? lastDate : selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IconButton(
        onPressed: () => _selectDate(context),
        icon: const Icon(Icons.calendar_today),
        color: const Color(0xFF0DB774),
        tooltip: 'Seleccionar fecha',
      ),
    );
  }
}
