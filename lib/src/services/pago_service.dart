import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PagoService {
  // URL para emulador Android y dispositivos físicos
  static const String _baseUrl = 'https://8d5b-38-25-28-10.ngrok-free.app';

  // Pago diario simple (cash o transfer)
  Future<Map<String, dynamic>> realizarPagoDiario(
    int paymentId,
    double monto,
    String metodo,
  ) async {
    try {
      debugPrint('=== INICIO DEL PROCESO DE PAGO SIMPLE ===');
      debugPrint('ID del pago: $paymentId');
      debugPrint('Monto a pagar: S/ $monto');
      debugPrint('Método de pago: $metodo');

      final body = {
        "jsonrpc": "2.0",
        "params": {"id": paymentId, "paid_amount": monto, "payment_met": metodo}
      };

      final url = '$_baseUrl/api/payment/daily/update';

      debugPrint('=== DATOS ENVIADOS ===');
      debugPrint('URL: $url');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('=== RESPUESTA DEL SERVIDOR ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al realizar el pago: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('=== ERROR ===');
      debugPrint('$e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Pago diario mixto (efectivo + transferencia)
  Future<Map<String, dynamic>> realizarPagoMixto(
    int paymentId,
    double montoEfectivo,
    double montoTransferencia,
  ) async {
    try {
      debugPrint('=== INICIO DEL PROCESO DE PAGO MIXTO ===');
      debugPrint('ID del pago: $paymentId');
      debugPrint('Monto efectivo: S/ $montoEfectivo');
      debugPrint('Monto transferencia: S/ $montoTransferencia');

      final body = {
        "jsonrpc": "2.0",
        "params": {
          "id": paymentId,
          "paid_amount_cash": montoEfectivo,
          "paid_amount_transferencia": montoTransferencia,
          "payment_met": "mixto"
        }
      };

      final url = '$_baseUrl/api/payment/daily/update';

      debugPrint('=== DATOS ENVIADOS ===');
      debugPrint('URL: $url');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('=== RESPUESTA DEL SERVIDOR ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al realizar el pago: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('=== ERROR ===');
      debugPrint('$e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> realizarPagoMensual(
    int paymentId,
    double interes,
    double capital,
    String metodo,
  ) async {
    try {
      debugPrint('=== INICIO DEL PROCESO DE PAGO MENSUAL ===');
      debugPrint('ID del pago: $paymentId');
      debugPrint('Interés a pagar: S/ $interes');
      debugPrint('Capital a pagar: S/ $capital');
      debugPrint('Método de pago: $metodo');

      if (interes < 0 || capital < 0) {
        throw Exception('Los montos no pueden ser negativos');
      }

      if (metodo.isEmpty) {
        throw Exception('Debe seleccionar un método de pago');
      }

      final body = {
        "jsonrpc": "2.0",
        "params": {
          "id": paymentId,
          "payment_met": metodo.toLowerCase(),
          "interest_paid": interes,
          "capital_paid": capital,
        }
      };

      final url = '$_baseUrl/api/payment/monthly/update';

      debugPrint('=== DATOS ENVIADOS ===');
      debugPrint('URL: $url');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http
          .post(
        Uri.parse(url),
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
