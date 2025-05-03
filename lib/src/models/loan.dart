/// Representa un préstamo en el sistema
class Loan {
  final int id;
  final int partnerId;
  final String name;
  final String loanNumber;
  final String clientName;
  final double amount;
  final int term;
  final String paymentPeriod;
  final double amountDueToday;
  final double partnerLatitude;
  final double partnerLongitude;
  final String status;
  final List<Installment> installments;
  final String? clientPhone;
  final String? clientAddress;

  Loan({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.loanNumber,
    required this.clientName,
    required this.amount,
    required this.term,
    required this.paymentPeriod,
    required this.amountDueToday,
    required this.partnerLatitude,
    required this.partnerLongitude,
    required this.status,
    required this.installments,
    this.clientPhone,
    this.clientAddress,
  });

  /// Crea una instancia de Loan desde un mapa JSON
  factory Loan.fromJson(Map<String, dynamic> json) {
    try {
      // Validar que el JSON no sea nulo
      if (json.isEmpty) {
        throw FormatException('JSON vacío al crear Loan');
      }

      // Extraer el nombre del cliente del campo partner_id si es una lista
      String clientName = '';
      if (json['partner_id'] is List && json['partner_id'].length > 1) {
        clientName = json['partner_id'][1]?.toString() ?? '';
      }

      // Crear lista de cuotas si existe el campo
      List<Installment> installments = [];
      if (json['installments'] is List) {
        installments = (json['installments'] as List)
            .where((item) => item != null)
            .map((item) => Installment.fromJson(item))
            .toList();
      }

      // Asegurar que los valores numéricos sean válidos usando una función helper
      double loanAmount = _parseDouble(json['loan_amount'], 'loan_amount');
      double amountDueToday =
          _parseDouble(json['amount_due_today'], 'amount_due_today');
      double latitude =
          _parseDouble(json['partner_latitude'], 'partner_latitude');
      double longitude =
          _parseDouble(json['partner_longitude'], 'partner_longitude');

      // Validar el estado del préstamo
      String status =
          json['loan_status']?.toString()?.toLowerCase() ?? 'pending';
      if (!['paid', 'pending', 'late', 'overpaid', 'partial']
          .contains(status)) {
        status = 'pending';
      }

      return Loan(
        id: json['id'] ?? 0,
        partnerId: json['partner_id'] is List ? json['partner_id'][0] ?? 0 : 0,
        name: json['name']?.toString() ?? '',
        loanNumber: json['name']?.toString() ?? '',
        clientName: clientName,
        amount: loanAmount,
        term: json['payment_parts'] ?? 0,
        paymentPeriod:
            json['payment_period']?.toString()?.toLowerCase() ?? 'monthly',
        amountDueToday: amountDueToday,
        partnerLatitude: latitude,
        partnerLongitude: longitude,
        status: status,
        installments: installments,
        clientPhone: _sanitizeString(json['partner_phone']),
        clientAddress: _sanitizeString(json['partner_address']),
      );
    } catch (e) {
      print('Error al crear Loan desde JSON: $e');
      rethrow;
    }
  }

  /// Convierte un valor a double de forma segura
  static double _parseDouble(dynamic value, String fieldName) {
    if (value == null) return 0.0;
    try {
      return (value as num).toDouble();
    } catch (e) {
      print('Error al convertir $fieldName: $e');
      return 0.0;
    }
  }

  /// Sanitiza un string, removiendo espacios extras y caracteres no deseados
  static String? _sanitizeString(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': [partnerId, clientName],
      'name': name,
      'loan_amount': amount,
      'payment_parts': term,
      'payment_period': paymentPeriod,
      'amount_due_today': amountDueToday,
      'partner_latitude': partnerLatitude,
      'partner_longitude': partnerLongitude,
      'loan_status': status,
      'partner_phone': clientPhone,
      'partner_address': clientAddress,
    };
  }

  // Método para obtener el texto del estado en español
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Pagado Completamente';
      case 'on_time':
        return 'Pendiente de Pago';
      case 'late':
        return 'Pago Atrasado';
      case 'overpaid':
        return 'Pago Excedido';
      case 'partial':
        return 'Pago Parcial';
      case 'pending':
        return 'Pendiente de Pago';
      default:
        return 'Estado Desconocido';
    }
  }
}

class PaymentMethod {
  static const String cash = 'cash';
  static const String bbva = 'bbva';
  static const String interbank = 'interbank';
  static const String bcn = 'bcn';
  static const String plin = 'plin';
  static const String yape = 'yape';
  static const String mixto = 'mixto';

  static String getDisplayName(String? method) {
    switch (method?.toLowerCase()) {
      case cash:
        return 'Efectivo';
      case bbva:
        return 'BBVA';
      case interbank:
        return 'INTERBANK';
      case bcn:
        return 'Banco de la Nación';
      case plin:
        return 'PLIN';
      case yape:
        return 'YAPE';
      case mixto:
        return 'Mixto';
      default:
        return 'No especificado';
    }
  }

  static bool isValid(String? method) {
    if (method == null) return false;
    final validMethods = [cash, bbva, interbank, bcn, plin, yape, mixto];
    return validMethods.contains(method.toLowerCase());
  }

  static bool isTransfer(String? method) {
    if (method == null) return false;
    final transferMethods = [bbva, interbank, bcn, plin, yape];
    return transferMethods.contains(method.toLowerCase());
  }

  static bool isDigitalTransfer(String? method) {
    if (method == null) return false;
    return [plin, yape].contains(method.toLowerCase());
  }
}

class Installment {
  final int id;
  final String dueDate;
  final double amount;
  final String status;
  final double? paidAmount;
  final String? paymentMethod;

  Installment({
    required this.id,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAmount,
    this.paymentMethod,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] ?? 0,
      dueDate: json['payment_date'] ?? '',
      amount: (json['payment_amount'] ?? 0.0).toDouble(),
      status: json['payment_status'] ?? 'pending',
      paidAmount: json['paid_amount'] != null
          ? (json['paid_amount'] as num).toDouble()
          : null,
      paymentMethod: json['payment_met'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_date': dueDate,
      'payment_amount': amount,
      'payment_status': status,
      'paid_amount': paidAmount,
      'payment_met': paymentMethod,
    };
  }

  // Método para obtener el texto del estado en español
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'on_time':
        return 'Pendiente';
      case 'late':
        return 'Atrasado';
      case 'overpaid':
        return 'Pago Excedido';
      case 'partial':
        return 'Pago Parcial';
      default:
        return 'Pendiente';
    }
  }

  // Método para obtener el nombre del método de pago
  String getPaymentMethodText() {
    return PaymentMethod.getDisplayName(paymentMethod);
  }
}
