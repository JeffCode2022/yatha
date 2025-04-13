class LoanLocation {
  final int id;
  final double latitude;
  final double longitude;
  final String name;
  final List<dynamic> partnerId;

  LoanLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.partnerId,
  });

  factory LoanLocation.fromJson(Map<String, dynamic> json) {
    return LoanLocation(
      id: json['id'] ?? 0,
      latitude: (json['partner_latitude'] ?? 0.0).toDouble(),
      longitude: (json['partner_longitude'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
      partnerId: json['partner_id'] ?? [],
    );
  }

  String get clientName =>
      partnerId.length > 1 ? partnerId[1].toString() : 'Sin nombre';
}
