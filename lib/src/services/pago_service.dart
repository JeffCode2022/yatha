import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:yatha_app/src/config/environment.dart';
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/logger.dart';

class PagoService extends BaseService {
  // URL para emulador Android y dispositivos físicos
  String get _baseUrl => Environment.apiUrl;

  // Pago diario simple (cash o transfer)
  Future<Map<String, dynamic>> realizarPagoDiario(
    int paymentId,
    double monto,
    String metodo,
  ) async {
    try {
      Logger.info('=== INICIO DEL PROCESO DE PAGO SIMPLE ===');
      Logger.info('ID del pago: $paymentId');
      Logger.info('Monto a pagar: S/ $monto');
      Logger.info('Método de pago: $metodo');

      final body = {
        "jsonrpc": "2.0",
        "params": {"id": paymentId, "paid_amount": monto, "payment_met": metodo}
      };

      final response = await post('/api/payment/daily/update', body: body);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      Logger.error('Error en realizarPagoDiario', e);
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
      Logger.info('=== INICIO DEL PROCESO DE PAGO MIXTO ===');
      Logger.info('ID del pago: $paymentId');
      Logger.info('Monto efectivo: S/ $montoEfectivo');
      Logger.info('Monto transferencia: S/ $montoTransferencia');

      final body = {
        "jsonrpc": "2.0",
        "params": {
          "id": paymentId,
          "paid_amount_cash": montoEfectivo,
          "paid_amount_transferencia": montoTransferencia,
          "payment_met": "mixto"
        }
      };

      final response = await post('/api/payment/daily/update', body: body);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      Logger.error('Error en realizarPagoMixto', e);
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
      Logger.info('=== INICIO DEL PROCESO DE PAGO MENSUAL ===');
      Logger.info('ID del pago: $paymentId');
      Logger.info('Interés a pagar: S/ $interes');
      Logger.info('Capital a pagar: S/ $capital');
      Logger.info('Método de pago: $metodo');

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

      final response = await post(
        '/api/payment/monthly/update',
        body: body,
      );

      if (response['result'] != null) {
        Logger.info('=== PAGO EXITOSO ===');
        return {
          'success': true,
          'message':
              response['result']['message'] ?? 'Pago realizado con éxito',
          'data': response['result'],
        };
      } else if (response['error'] != null) {
        Logger.error('=== ERROR EN EL PAGO ===');
        return {
          'success': false,
          'message':
              response['error']['message'] ?? 'Error al realizar el pago',
          'data': response['error'],
        };
      }

      return {
        'success': true,
        'message': 'Pago realizado con éxito',
        'data': response,
      };
    } catch (e) {
      Logger.error('Error en realizarPagoMensual', e);
      return {
        'success': false,
        'message': 'Error inesperado: $e',
        'data': null,
      };
    }
  }
}
