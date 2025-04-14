import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SupervisorService {
  static const String _baseUrl = 'https://cda7-38-25-28-10.ngrok-free.app';

  Future<List<Map<String, dynamic>>> getGestores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print('Fetching gestores with uid: $uid, database: $database');

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
                ["active", "=", true],
                ["x_role", "=", "gestor"]
              ],
              ["id", "partner_id", "x_role"]
            ]
          }
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final List<dynamic> result = data['result'];
          return result
              .map((gestor) => {
                    'id': gestor['id'].toString(),
                    'name': gestor['partner_id'] != null
                        ? gestor['partner_id'][1] ?? 'Sin nombre'
                        : 'Sin nombre',
                    'role': gestor['x_role'] ?? 'gestor'
                  })
              .toList();
        }
        throw Exception('No se encontraron gestores');
      }
      throw Exception('Error al obtener gestores: ${response.statusCode}');
    } catch (e) {
      print('Error en getGestores: $e');
      throw Exception('Error al obtener gestores: $e');
    }
  }

  Future<Map<String, dynamic>> getGestorKPIs(
      String gestorId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching KPIs for gestor: $gestorId, date: ${DateFormat('yyyy-MM-dd').format(date)}');

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
                ["payment_date", "=", DateFormat('yyyy-MM-dd').format(date)]
              ],
              ["payment_status", "payment_amount", "paid_amount"]
            ]
          }
        }),
      );

      print('KPI Response status: ${response.statusCode}');
      print('KPI Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Si result es null o una lista vacía, retornamos valores por defecto
        if (data['result'] == null || (data['result'] as List).isEmpty) {
          print(
              'No se encontraron pagos para el gestor en la fecha especificada');
          return {
            'pending_count': 0,
            'completed_count': 0,
            'total_amount': 0.0,
            'collected_amount': 0.0,
            'efficiency': 0.0,
          };
        }

        final payments = List<Map<String, dynamic>>.from(data['result']);
        print('Procesando ${payments.length} pagos encontrados');

        int pendingCount = 0;
        int completedCount = 0;
        double totalAmount = 0;
        double collectedAmount = 0;

        for (var payment in payments) {
          if (payment['payment_status'] == 'pending') {
            pendingCount++;
            totalAmount += payment['payment_amount'] ?? 0;
          } else if (payment['payment_status'] == 'paid') {
            completedCount++;
            collectedAmount += payment['paid_amount'] ?? 0;
          }
        }

        print(
            'Resumen KPIs: Pendientes: $pendingCount, Completados: $completedCount');
        return {
          'pending_count': pendingCount,
          'completed_count': completedCount,
          'total_amount': totalAmount,
          'collected_amount': collectedAmount,
          'efficiency':
              payments.isEmpty ? 0.0 : completedCount / payments.length,
        };
      }
      throw Exception(
          'Error en la respuesta del servidor: ${response.statusCode}');
    } catch (e) {
      print('Error en getGestorKPIs: $e');
      throw Exception('Error al obtener KPIs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGestorClientLocations(
      String gestorId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching client locations for gestor: $gestorId, date: ${DateFormat('yyyy-MM-dd').format(date)}');

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
                ["payment_date", "=", DateFormat('yyyy-MM-dd').format(date)],
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

      print('Location Response status: ${response.statusCode}');
      print('Location Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == null) {
          print('No se encontraron ubicaciones para el gestor');
          return [];
        }

        final List<dynamic> payments = data['result'];
        print('Encontrados ${payments.length} pagos con ubicación');

        final List<Map<String, dynamic>> locations = [];

        for (var payment in payments) {
          print('Procesando pago: ${payment['id']}');
          print('Datos del pago:');
          print('- Latitud: ${payment['loan_id/partner_latitude']}');
          print('- Longitud: ${payment['loan_id/partner_longitude']}');
          print('- Cliente: ${payment['loan_id/partner_id']}');
          print('- Monto: ${payment['payment_amount']}');
          print('- Estado: ${payment['payment_status']}');
          print('- Gestor: ${payment['loan_id/partner_salesperson']}');

          // Convertir las coordenadas a double
          final lat =
              double.tryParse(payment['loan_id/partner_latitude'].toString()) ??
                  0.0;
          final lng = double.tryParse(
                  payment['loan_id/partner_longitude'].toString()) ??
              0.0;

          if (lat == 0.0 || lng == 0.0) {
            print('Coordenadas inválidas para el pago ${payment['id']}');
            continue;
          }

          locations.add({
            'latitude': lat,
            'longitude': lng,
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
          });
        }

        print('Ubicaciones procesadas: ${locations.length}');
        return locations;
      }

      throw Exception('Error al obtener las ubicaciones de los clientes');
    } catch (e) {
      print('Error en getGestorClientLocations: $e');
      throw Exception('Error al obtener las ubicaciones de los clientes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllGestorsClientLocations(
      DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 0;
      final password = prefs.getString('password') ?? '';
      final database = prefs.getString('database') ?? 'prestamovf';

      print(
          'Fetching all client locations for date: ${DateFormat('yyyy-MM-dd').format(date)}');

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
              "loan.management",
              "search_read",
              [
                ["loan_status", "=", "pending"],
                ["name", "!=", false]
              ],
              [
                "id",
                "name",
                "partner_id",
                "partner_latitude",
                "partner_longitude",
                "payment_amount",
                "loan_status",
                "partner_salesperson"
              ]
            ]
          }
        }),
      );

      print('Location Response status: ${response.statusCode}');
      print('Location Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == null) {
          return [];
        }

        final List<dynamic> loans = data['result'];
        return loans.where((loan) {
          final lat = loan['partner_latitude'];
          final lng = loan['partner_longitude'];
          return lat != null && lng != null;
        }).map((loan) {
          return {
            'latitude': loan['partner_latitude'] as double,
            'longitude': loan['partner_longitude'] as double,
            'client_name': loan['partner_id'] != null
                ? loan['partner_id'][1]
                : 'Sin nombre',
            'amount': loan['payment_amount'] as double? ?? 0.0,
            'status': loan['loan_status'] as String? ?? 'pending',
            'gestor_name': loan['partner_salesperson'] != null
                ? loan['partner_salesperson'][1]
                : 'Sin gestor',
            'gestor_id': loan['partner_salesperson'] != null
                ? loan['partner_salesperson'][0].toString()
                : '0',
          };
        }).toList();
      }

      throw Exception('Error al obtener las ubicaciones de los clientes');
    } catch (e) {
      print('Error en getAllGestorsClientLocations: $e');
      throw Exception('Error al obtener las ubicaciones de los clientes: $e');
    }
  }
}
