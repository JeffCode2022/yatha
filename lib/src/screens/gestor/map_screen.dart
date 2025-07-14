import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../../utils/widgets/mapa_gestor_widget.dart';
import '../../utils/theme/app_theme.dart'; // Importamos el tema de la aplicación

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme
                  .colorScheme.primary, // Color primario para el calendario
              onPrimary:
                  Colors.white, // Color del texto sobre el color primario
              surface: Colors.white, // Color de fondo
              onSurface: Colors.black, // Color del texto sobre el fondo
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme
                    .colorScheme.primary, // Color de los botones de texto
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Nombres de los meses en español
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapaGestorWidget(
            key: ValueKey(_selectedDate.toString()),
            selectedDate: _selectedDate,
          ),
          // Indicador de carga del mapa (overlay en la parte inferior izquierda)
         
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectDate(context),
        backgroundColor: AppTheme.colorScheme.primary,
        child: const Icon(
          Iconsax.calendar_1, // Iconsax para calendario
          color: Colors.white,
        ),
      ),
    );
  }
}
