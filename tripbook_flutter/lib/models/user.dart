class User {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String avatarColor;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.avatarColor,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? 'User',
      email: json['email'],
      phone: json['phone'],
      avatarColor: json['avatar_color'] ?? '#2563eb',
      isAdmin: (json['is_admin'] == 1 || json['is_admin'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_color': avatarColor,
      'is_admin': isAdmin ? 1 : 0,
    };
  }
}
