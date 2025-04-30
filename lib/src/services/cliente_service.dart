import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/date_utils.dart';
import 'package:yatha_app/src/utils/logger.dart';

class ClienteService extends BaseService {
  Future<Map<String, dynamic>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid');

    developer.log('Obteniendo credenciales - UID: $uid');

    if (uid == null) {
      throw Exception('No hay credenciales almacenadas');
    }

    return {
      'uid': uid,
      'password': '1234', // Contraseña fija como en Postman
    };
  }

  Future<List<String>> obtenerPrestamosPorFecha(DateTime fecha) async {
    try {
      final queryFilters = [
        ["loan_id", "!=", false],
        ["loan_id.partner_salesperson", "=", (await getCredentials())['uid']],
        ["payment_date", "=", DateUtils.formatDate(fecha)],
        ["payment_status", "=", "pending"]
      ];

      final response = await executeOdooMethod(
        model: "loan.payment",
        method: "search_read",
        args: [queryFilters, _getPaymentFields()],
      );

      if (response['result'] != null) {
        final prestamos = response['result'] as List<dynamic>;
        final loanIds = prestamos
            .map((prestamo) => prestamo['loan_id'][1].toString())
            .toList();
        Logger.info('Préstamos encontrados: ${loanIds.length}');
        return loanIds;
      }
      return [];
    } catch (e) {
      Logger.error('Error en obtenerPrestamosPorFecha', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerCoordenadas(
      List<String> prestamos) async {
    try {
      if (prestamos.isEmpty) {
        return [];
      }

      final queryFilters = [
        ["loan_status", "=", "pending"],
        ["partner_salesperson.id", "=", (await getCredentials())['uid']],
        ["name", "in", prestamos]
      ];

      final response = await executeOdooMethod(
        model: "loan.management",
        method: "search_read",
        args: [queryFilters, _getCoordinateFields()],
      );

      if (response['result'] != null) {
        return List<Map<String, dynamic>>.from(response['result']);
      }
      return [];
    } catch (e) {
      Logger.error('Error en obtenerCoordenadas', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerClientes({DateTime? fecha}) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      Logger.info(
          'Iniciando consulta para fecha: ${DateUtils.formatDate(fechaConsulta)}');

      final prestamos = await obtenerPrestamosPorFecha(fechaConsulta);
      if (prestamos.isEmpty) {
        Logger.info('No se encontraron préstamos para la fecha');
        return [];
      }

      final coordenadas = await obtenerCoordenadas(prestamos);
      Logger.info('Coordenadas obtenidas: ${coordenadas.length}');
      return coordenadas;
    } catch (e) {
      Logger.error('Error en obtenerClientes', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPrestamos(
      String uid, String date) async {
    try {
      final queryFilters = [
        ['partner_salesperson', '=', int.parse(uid)],
        ['loan_status', '=', 'pending']
      ];

      final response = await executeOdooMethod(
        model: "loan.management",
        method: "search_read",
        args: [queryFilters, _getLoanFields()],
      );

      if (response['result'] != null) {
        return List<Map<String, dynamic>>.from(response['result']).map((loan) {
          final partnerInfo = loan['partner_id'] ?? [0, 'Sin nombre'];
          return {
            'id': loan['id'] ?? 0,
            'name': loan['name'] ?? '',
            'partner_id': partnerInfo,
            'loan_amount': loan['loan_amount'] ?? 0.0,
            'payment_period': loan['payment_period'] ?? 'monthly',
            'payment_parts': loan['payment_parts'] ?? 0,
            'amount_due_today': loan['amount_due_today'] ?? 0.0,
            'partner_latitude': loan['partner_latitude'] ?? 0.0,
            'partner_longitude': loan['partner_longitude'] ?? 0.0,
            'loan_status': loan['loan_status'] ?? 'pending',
            'total_amount': loan['total_amount'] ?? 0.0,
            'current_due': loan['current_due'] ?? 0.0,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Error en obtenerPrestamos', e);
      rethrow;
    }
  }

  List<String> _getPaymentFields() {
    return [
      "id",
      "name",
      "payment_date",
      "actual_payment_date",
      "payment_status",
      "payment_amount",
      "paid_amount",
      "partner_id",
      "loan_id",
      "payment_met"
    ];
  }

  List<String> _getCoordinateFields() {
    return [
      "id",
      "name",
      "partner_id",
      "partner_latitude",
      "partner_longitude"
    ];
  }

  List<String> _getLoanFields() {
    return [
      'id',
      'name',
      'partner_id',
      'loan_amount',
      'payment_period',
      'payment_parts',
      'amount_due_today',
      'partner_latitude',
      'partner_longitude',
      'loan_status',
      'total_amount',
      'current_due'
    ];
  }
}
