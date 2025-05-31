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
  final String? due_date;
  final int? days_overdue;
  final List<dynamic>? create_uid;
  final List<dynamic>? write_uid;
  final bool? prestamo_anterior;
  final String? payment_frequency;
  final String? start_date;
  final String? first_payment_date;
  final String? create_date;
  final String? write_date;
  final double? total_interest_paid;
  final double? interest_rate;
  final double? real_interest_rate;
  final double? profit;
  final double? current_due;
  final double? payment_amount;
  final double? total_cash_payments;
  final double? total_transfer_payments;

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
    this.due_date,
    this.days_overdue,
    this.create_uid,
    this.write_uid,
    this.prestamo_anterior,
    this.payment_frequency,
    this.start_date,
    this.first_payment_date,
    this.create_date,
    this.write_date,
    this.total_interest_paid,
    this.interest_rate,
    this.real_interest_rate,
    this.profit,
    this.current_due,
    this.payment_amount,
    this.total_cash_payments,
    this.total_transfer_payments,
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
        due_date: json['due_date']?.toString(),
        days_overdue: json['days_overdue'] as int?,
        create_uid: json['create_uid'] as List<dynamic>?,
        write_uid: json['write_uid'] as List<dynamic>?,
        prestamo_anterior: json['prestamo_anterior'] as bool?,
        payment_frequency: json['payment_frequency']?.toString(),
        start_date: json['start_date']?.toString(),
        first_payment_date: json['first_payment_date']?.toString(),
        create_date: json['create_date']?.toString(),
        write_date: json['write_date']?.toString(),
        total_interest_paid:
            _parseDouble(json['total_interest_paid'], 'total_interest_paid'),
        interest_rate: _parseDouble(json['interest_rate'], 'interest_rate'),
        real_interest_rate:
            _parseDouble(json['real_interest_rate'], 'real_interest_rate'),
        profit: _parseDouble(json['profit'], 'profit'),
        current_due: _parseDouble(json['current_due'], 'current_due'),
        payment_amount: _parseDouble(json['payment_amount'], 'payment_amount'),
        total_cash_payments:
            _parseDouble(json['total_cash_payments'], 'total_cash_payments'),
        total_transfer_payments: _parseDouble(
            json['total_transfer_payments'], 'total_transfer_payments'),
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
      'due_date': due_date,
      'days_overdue': days_overdue,
      'create_uid': create_uid,
      'write_uid': write_uid,
      'prestamo_anterior': prestamo_anterior,
      'payment_frequency': payment_frequency,
      'start_date': start_date,
      'first_payment_date': first_payment_date,
      'create_date': create_date,
      'write_date': write_date,
      'total_interest_paid': total_interest_paid,
      'interest_rate': interest_rate,
      'real_interest_rate': real_interest_rate,
      'profit': profit,
      'current_due': current_due,
      'payment_amount': payment_amount,
      'total_cash_payments': total_cash_payments,
      'total_transfer_payments': total_transfer_payments,
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
