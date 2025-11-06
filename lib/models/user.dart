class User {
  final int id;
  final String phone;
  final String? name;
  final String? role;

  User({required this.id, required this.phone, this.name, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      role: json['role'],
    );
  }
}
