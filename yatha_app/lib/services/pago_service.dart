import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PagoService {
  // URL para emulador Android y dispositivos físicos
  static const String _baseUrl =
      'https://cda7-38-25-28-10.ngrok-free.app/api/payment/daily/update';

  Future<Map<String, dynamic>> realizarPagoDiario(
    int id,
    double monto,
    String metodo,
  ) async {
    try {
      debugPrint('=== INICIO DEL PROCESO DE PAGO ===');
      debugPrint('ID del cliente: $id');
      debugPrint('Monto a pagar: S/ $monto');
      debugPrint('Método de pago: $metodo');

      if (monto <= 0) {
        throw Exception('El monto debe ser mayor a 0');
      }

      if (metodo.isEmpty) {
        throw Exception('Debe seleccionar un método de pago');
      }

      final body = {
        "jsonrpc": "2.0",
        "method": "make_payment",
        "params": {
          "id": id,
          "paid_amount": monto,
          "payment_met": metodo.toLowerCase(),
        },
        "id": DateTime.now().millisecondsSinceEpoch,
      };

      debugPrint('=== DATOS ENVIADOS ===');
      debugPrint('URL: $_baseUrl');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'La conexión ha tardado demasiado. Por favor, inténtelo de nuevo.',
              );
            },
          );

      debugPrint('=== RESPUESTA DEL SERVIDOR ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] != null) {
          debugPrint('=== PAGO EXITOSO ===');
          debugPrint('Resultado: ${data['result']}');
          return {
            'success': true,
            'message': data['result']['message'] ?? 'Pago realizado con éxito',
            'data': data['result'],
          };
        } else if (data['error'] != null) {
          debugPrint('=== ERROR EN EL PAGO ===');
          debugPrint('Error: ${data['error']}');
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error al realizar el pago',
            'data': data['error'],
          };
        }

        return {
          'success': true,
          'message': 'Pago realizado con éxito',
          'data': data,
        };
      } else {
        debugPrint('=== ERROR HTTP ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return {
          'success': false,
          'message': 'Error al realizar el pago: ${response.statusCode}',
          'data': null,
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('=== ERROR DE TIMEOUT ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'message':
            'La conexión ha tardado demasiado. Por favor, inténtelo de nuevo.',
        'data': null,
      };
    } on http.ClientException catch (e) {
      debugPrint('=== ERROR DE CONEXIÓN ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifique su conexión a internet.',
        'data': null,
      };
    } on FormatException catch (e) {
      debugPrint('=== ERROR DE FORMATO ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'message': 'Error al procesar la respuesta del servidor.',
        'data': null,
      };
    } catch (e) {
      debugPrint('=== ERROR INESPERADO ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'message': 'Error inesperado: $e',
        'data': null,
      };
    }
  }
}
