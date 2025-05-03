class User {
  final int uid;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? token;
  final List<dynamic>? partnerId;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'gestor',
    this.avatarUrl,
    this.token,
    this.partnerId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String name = '';
    List<dynamic>? partnerId = json['partner_id'] as List<dynamic>?;

    if (partnerId != null && partnerId.length > 1) {
      name = partnerId[1].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      name = json['name'].toString();
    } else if (json['email'] != null) {
      name = json['email'].toString().split('@')[0];
    }

    return User(
      uid: json['uid'] as int,
      name: name,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'gestor',
      avatarUrl: json['avatar_url'],
      token: json['token'] as String?,
      partnerId: partnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'token': token,
      'partner_id': partnerId,
    };
  }

  // Obtener el nombre para mostrar
  String get displayName {
    if (partnerId != null && partnerId!.length > 1) {
      return partnerId![1].toString();
    }
    return name;
  }
}
