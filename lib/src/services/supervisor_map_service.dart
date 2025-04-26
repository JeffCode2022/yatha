import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yatha_app/config/environment.dart';

class SupervisorMapService {
  static const String _baseUrl = Environment.apiUrl;

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
                "loan_id/partner_salesperson"
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
}
