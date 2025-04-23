
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

  factory Loan.fromJson(Map<String, dynamic> json) {
    // Extraer el nombre del cliente del campo partner_id si es una lista
    String clientName = '';
    if (json['partner_id'] is List && json['partner_id'].length > 1) {
      clientName = json['partner_id'][1];
    }

    // Crear lista de cuotas si existe el campo
    List<Installment> installments = [];
    if (json['installments'] is List) {
      installments = (json['installments'] as List)
          .map((item) => Installment.fromJson(item))
          .toList();
    }

    return Loan(
      id: json['id'] ?? 0,
      partnerId: json['partner_id'] is List ? json['partner_id'][0] : 0,
      name: json['name'] ?? '',
      loanNumber: json['name'] ?? '', // Usar el mismo campo para loanNumber
      clientName: clientName,
      amount: (json['loan_amount'] ?? 0.0).toDouble(),
      term: json['payment_parts'] ?? 0,
      paymentPeriod: json['payment_period'] ?? 'monthly',
      amountDueToday: (json['amount_due_today'] ?? 0.0).toDouble(),
      partnerLatitude: (json['partner_latitude'] ?? 0.0).toDouble(),
      partnerLongitude: (json['partner_longitude'] ?? 0.0).toDouble(),
      status: json['loan_status'] ?? 'pending',
      installments: installments,
      clientPhone: json['partner_phone'],
      clientAddress: json['partner_address'],
    );
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
        return 'Pagado';
      case 'pending':
        return 'Pendiente';
      case 'late':
        return 'Atrasado';
      default:
        return 'Desconocido';
    }
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
      default:
        return 'Pendiente';
    }
  }
}
