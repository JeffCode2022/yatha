import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/src/config/environment.dart';

class SupervisorMapService {
  String get _baseUrl => Environment.apiUrl;

  Future<List<Map<String, dynamic>>> getPendingClientsForGestorAndDate({
    required String gestorId,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final response = await http.post(
        Uri.parse('$_baseUrl/jsonrpc'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "service": "object",
            "method": "execute",
            "args": [
              database,
              uid,
              password,
              "loan.payment",
              "search_read",
              [
                ["loan_id", "!=", false],
                ["loan_id.partner_salesperson", "=", int.parse(gestorId)],
                ["payment_date", "=", formattedDate],
                ["payment_status", "=", "pending"],
                ["loan_id.partner_latitude", "!=", false],
                ["loan_id.partner_longitude", "!=", false]
              ],
              [
                "id",
                "loan_id",
                "payment_amount",
                "payment_status",
                "loan_id/partner_latitude",
                "loan_id/partner_longitude",
                "loan_id/partner_id",
                "loan_id/partner_salesperson",
                "loan_id/partner_street",
                "loan_id/partner_street2",
                "loan_id/partner_city",
                "loan_id/partner_state_id",
                "loan_id/partner_country_id",
                "loan_id/partner_zip"
              ]
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == null) {
          return [];
        }
        final List<dynamic> payments = data['result'];
        return payments.map((payment) {
          final lat = payment['loan_id/partner_latitude'];
          final lng = payment['loan_id/partner_longitude'];
          final street = payment['loan_id/partner_street'];
          final street2 = payment['loan_id/partner_street2'];
          final city = payment['loan_id/partner_city'];
          final state = payment['loan_id/partner_state_id'];
          final country = payment['loan_id/partner_country_id'];
          final zip = payment['loan_id/partner_zip'];

          // Construir la dirección completa
          final addressParts = [
            street,
            street2,
            city,
            state != null ? state[1] : null,
            country != null ? country[1] : null,
            zip
          ]
              .where((part) => part != null && part.toString().isNotEmpty)
              .toList();

          final fullAddress = addressParts.join(', ');

          return {
            'latitude': double.tryParse(lat.toString()) ?? 0.0,
            'longitude': double.tryParse(lng.toString()) ?? 0.0,
            'client_name': payment['loan_id/partner_id'] != null
                ? payment['loan_id/partner_id'][1]
                : 'Sin nombre',
            'amount': payment['payment_amount'] as double? ?? 0.0,
            'status': payment['payment_status'] as String? ?? 'pending',
            'gestor_name': payment['loan_id/partner_salesperson'] != null
                ? payment['loan_id/partner_salesperson'][1]
                : 'Sin gestor',
            'gestor_id': payment['loan_id/partner_salesperson'] != null
                ? payment['loan_id/partner_salesperson'][0].toString()
                : '0',
            'address': fullAddress,
            'street': street,
            'street2': street2,
            'city': city,
            'state': state != null ? state[1] : null,
            'country': country != null ? country[1] : null,
            'zip': zip,
            'is_gestor':
                false, // Agregar campo para identificar que es un cliente
          };
        }).toList();
      }
      throw Exception('Error al obtener los clientes pendientes para el mapa');
    } catch (e) {
      print('Error en getPendingClientsForGestorAndDate: $e');
      throw Exception(
          'Error al obtener los clientes pendientes para el mapa: $e');
    }
  }

  // Nuevo método para obtener la ubicación del gestor
  Future<Map<String, dynamic>?> getGestorLocation(String gestorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      final response = await http.post(
        Uri.parse('$_baseUrl/jsonrpc'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "service": "object",
            "method": "execute",
            "args": [
              database,
              uid,
              password,
              "res.users",
              "search_read",
              [
                ["id", "=", int.parse(gestorId)],
                ["partner_id.latitude", "!=", false],
                ["partner_id.longitude", "!=", false]
              ],
              [
                "id",
                "name",
                "partner_id/name",
                "partner_id/latitude",
                "partner_id/longitude",
                "partner_id/street",
                "partner_id/city",
                "partner_id/state_id",
                "partner_id/country_id"
              ]
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final gestor = data['result'][0];
          final lat = gestor['partner_id/latitude'];
          final lng = gestor['partner_id/longitude'];

          if (lat != null && lng != null) {
            return {
              'latitude': double.tryParse(lat.toString()) ?? 0.0,
              'longitude': double.tryParse(lng.toString()) ?? 0.0,
              'gestor_name': gestor['name'] ?? 'Sin nombre',
              'gestor_id': gestor['id'].toString(),
              'address': gestor['partner_id/street'] ?? '',
              'city': gestor['partner_id/city'] ?? '',
              'state': gestor['partner_id/state_id'] != null
                  ? gestor['partner_id/state_id'][1]
                  : null,
              'country': gestor['partner_id/country_id'] != null
                  ? gestor['partner_id/country_id'][1]
                  : null,
              'is_gestor': true, // Identificar que es un gestor
            };
          }
        }
      }
      return null; // No se encontró ubicación del gestor
    } catch (e) {
      print('Error en getGestorLocation: $e');
      return null;
    }
  }
}
