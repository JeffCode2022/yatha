import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/loan_location.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<LoanLocation>> getLoanLocations(int gestorId, String? loanName,
      {DateTime? selectedDate}) async {
    try {
      final token = await _getToken();
      if (token == null)
        throw Exception('No se encontró token de autenticación');

      debugPrint(
          'LocationService - Obteniendo ubicaciones para gestor: $gestorId');

      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "loan.management",
            "method": "search_read",
            "args": [],
            "kwargs": {
              "domain": [
                ["loan_status", "=", "pending"],
                ["partner_salesperson.id", "=", gestorId],
                if (loanName != null && loanName.isNotEmpty)
                  ["name", "=", loanName],
                if (selectedDate != null)
                  [
                    "payment_date",
                    "=",
                    selectedDate.toIso8601String().split('T')[0]
                  ],
              ],
              "fields": [
                "id",
                "partner_latitude",
                "partner_longitude",
                "name",
                "partner_id"
              ]
            }
          }
        }),
      );

      debugPrint('LocationService - Status code: ${response.statusCode}');
      debugPrint('LocationService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('result')) {
          final List<dynamic> results = jsonResponse['result'];
          final locations =
              results.map((data) => LoanLocation.fromJson(data)).toList();
          debugPrint(
              'LocationService - Ubicaciones encontradas: ${locations.length}');
          return locations;
        }
      }

      throw Exception('Error al obtener ubicaciones: ${response.statusCode}');
    } catch (e) {
      debugPrint('LocationService - Error: $e');
      throw Exception('Error al obtener ubicaciones: $e');
    }
  }
}
