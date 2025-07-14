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

  Future<List<Map<String, dynamic>>> obtenerClientes({
    DateTime? fecha,
  }) async {
    try {
      final credentials = await _getCredentials();
      final uid = credentials['uid'];
      final formattedDate = fecha != null
          ? '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}'
          : '';

      // Primero obtenemos los pagos filtrando por gestor y fecha, sin filtrar por payment_status
      final response = await executeOdooMethod(
        model: 'loan.payment',
        method: 'search_read',
        args: [
          [
            ['payment_date', '=', formattedDate],
            ['loan_id.partner_salesperson', '=', uid],
          ],
          [
            'id',
            'name',
            'payment_date',
            'payment_status',
            'payment_amount',
            'paid_amount',
            'paid_amount_cash',
            'paid_amount_transferencia',
            'partner_id',
            'loan_id',
            'payment_met',
          ]
        ],
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      final List<Map<String, dynamic>> pagos =
          List<Map<String, dynamic>>.from(response['result'] ?? []);

      // Filtrar solo los pagos pendientes (no pagados ni overpaid), con saldo pendiente > 0 y sin duplicados por loan_id
      final Set<dynamic> processedLoans = {};
      final pagosPendientes = pagos.where((pago) {
        final status = (pago['payment_status'] ?? '').toLowerCase();
        final paymentAmount = (pago['payment_amount'] ?? 0.0) is num
            ? (pago['payment_amount'] ?? 0.0).toDouble()
            : double.tryParse(pago['payment_amount']?.toString() ?? '0') ?? 0.0;
        double paidAmount = 0.0;
        if (pago['payment_met'] == 'mixto') {
          paidAmount = (pago['paid_amount_cash'] ?? 0.0).toDouble() +
              (pago['paid_amount_transferencia'] ?? 0.0).toDouble();
        } else {
          paidAmount = (pago['paid_amount'] ?? 0.0).toDouble();
        }
        final loanId = pago['loan_id']?[0];
        final pendiente = (status == 'pending' || status == 'late') &&
            (paymentAmount - paidAmount) > 0.0 &&
            loanId != null &&
            !processedLoans.contains(loanId);
        if (pendiente) processedLoans.add(loanId);
        return pendiente;
      }).toList();

      if (pagosPendientes.isEmpty) {
        return [];
      }

      // Obtenemos los IDs de los préstamos
      final loanIds = pagosPendientes
          .map((pago) => pago['loan_id'][0])
          .where((id) => id != null)
          .toSet()
          .toList();

      // Obtenemos los datos de los préstamos
      final prestamosResponse = await executeOdooMethod(
        model: 'loan.management',
        method: 'search_read',
        args: [
          [
            ['id', 'in', loanIds]
          ],
          [
            'id',
            'partner_latitude',
            'partner_longitude',
            'partner_address',
            'loan_status'
          ]
        ],
      );

      if (prestamosResponse.containsKey('error')) {
        throw Exception(prestamosResponse['error']);
      }

      final prestamos = Map<int, Map<String, dynamic>>.fromIterable(
        List<Map<String, dynamic>>.from(prestamosResponse['result'] ?? []),
        key: (prestamo) => prestamo['id'],
        value: (prestamo) => prestamo,
      );

      // Obtener préstamos vigentes del usuario para filtrar solo los pagos de préstamos vigentes
      final prestamosVigentes =
          await obtenerPrestamos(uid.toString(), formattedDate);
      final prestamosVigentesIds =
          prestamosVigentes.map((p) => p['id']).toSet();

      // Combinamos la información y excluimos préstamos refinanciados, renovados o cancelados,
      // y solo prestamos vigentes
      final clientes = pagosPendientes
          .map((pago) {
            final loanId = pago['loan_id'][0];
            final prestamo = prestamos[loanId] ?? {};
            final loanStatus =
                (prestamo['loan_status'] ?? '').toString().toLowerCase();
            if (loanStatus == 'refinanced' ||
                loanStatus == 'renewed' ||
                loanStatus == 'cancelled') {
              return null; // Excluir
            }
            if (!prestamosVigentesIds.contains(loanId)) {
              return null; // Excluir si no es préstamo vigente
            }

            // Obtener y validar el monto
            var montoRaw = pago['payment_amount'];
            double monto;
            if (montoRaw is int) {
              monto = montoRaw.toDouble();
            } else if (montoRaw is double) {
              monto = montoRaw;
            } else {
              monto = double.tryParse(montoRaw?.toString() ?? '0') ?? 0.0;
            }

            // Redondear a 2 decimales
            monto = (monto * 100).round() / 100;

            return {
              'id': pago['id'],
              'name': pago['name'],
              'payment_date': pago['payment_date'],
              'partner_id': pago['partner_id'],
              'amount': monto,
              'partner_latitude': prestamo['partner_latitude'] ?? 0.0,
              'partner_longitude': prestamo['partner_longitude'] ?? 0.0,
              'partner_address': prestamo['partner_address'],
            };
          })
          .where((cliente) => cliente != null)
          .cast<Map<String, dynamic>>()
          .toList();

      return clientes;
    } catch (e) {
      print('Error al obtener clientes: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPrestamos(
      String uid, String date) async {
    try {
      // Se elimina el filtro de fecha para mostrar todos los préstamos pendientes
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
        final allLoans = List<Map<String, dynamic>>.from(response['result']);

        // Lógica para eliminar duplicados
        final uniqueLoans = <int, Map<String, dynamic>>{};
        for (final loan in allLoans) {
          final loanId = loan['id'] as int?;
          if (loanId != null) {
            uniqueLoans[loanId] = loan;
          }
        }

        final loans = uniqueLoans.values.toList();
        Logger.info(
            'Préstamos originales: ${allLoans.length}, Préstamos únicos: ${loans.length}');

        return loans.map((loan) {
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
            'due_date': loan['due_date'],
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
      'due_date',
    ];
  }
}
