class User {
  final int uid;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? token;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'gestor',
      avatarUrl: json['avatar_url'],
      token: json['token'],
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
    };
  }
}
