import 'package:flutter/material.dart';

class Gestor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int clientCount;
  final int loanCount;
  final double collectionRate;
  final double totalPortfolio;
  final String? avatarUrl;

  Gestor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.clientCount,
    required this.loanCount,
    required this.collectionRate,
    required this.totalPortfolio,
    this.avatarUrl,
  });

  factory Gestor.fromJson(Map<String, dynamic> json) {
    return Gestor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      clientCount: json['clientCount'] ?? 0,
      loanCount: json['loanCount'] ?? 0,
      collectionRate: (json['collectionRate'] ?? 0).toDouble(),
      totalPortfolio: (json['totalPortfolio'] ?? 0).toDouble(),
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'clientCount': clientCount,
      'loanCount': loanCount,
      'collectionRate': collectionRate,
      'totalPortfolio': totalPortfolio,
      'avatarUrl': avatarUrl,
    };
  }
  
  // Método para obtener el color según la tasa de cobro
  Color getCollectionRateColor() {
    if (collectionRate >= 0.9) {
      return Colors.green;
    } else if (collectionRate >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Método para obtener las iniciales del nombre
  String getInitials() {
    if (name.isEmpty) return '';
    
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
}
