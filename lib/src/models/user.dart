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
    this.role = 'gestor',
    this.avatarUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'gestor',
      avatarUrl: json['avatar_url'],
      token: json['token'] as String?,
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
