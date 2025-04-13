import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ClientLocation {
  final int id;
  final String name;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final double paymentAmount;
  final String loanId;
  final bool hasPaymentToday;
  final bool hasOverduePayment;

  ClientLocation({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.paymentAmount,
    required this.loanId,
    required this.hasPaymentToday,
    required this.hasOverduePayment,
  });

  factory ClientLocation.fromJson(Map<String, dynamic> json) {
    return ClientLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      paymentAmount: (json['payment_amount'] ?? 0).toDouble(),
      loanId: json['loan_id'] ?? '',
      hasPaymentToday: json['has_payment_today'] ?? false,
      hasOverduePayment: json['has_overdue_payment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'payment_amount': paymentAmount,
      'loan_id': loanId,
      'has_payment_today': hasPaymentToday,
      'has_overdue_payment': hasOverduePayment,
    };
  }
  

  
  // Método para obtener el estado como texto
  String getStatusText() {
    if (hasOverduePayment) {
      return 'Pago atrasado';
    } else if (hasPaymentToday) {
      return 'Pago hoy';
    } else {
      return 'Al día';
    }
  }
}
