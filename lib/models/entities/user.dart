class UserModel {
  final String id;
  final String email;
  final String role; // admin, dairy, bmc, society, farmer
  final String name;
  final String? token;
  final String? refreshToken;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.token,
    this.refreshToken,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  // Method to convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  // CopyWith method for creating modified copies
  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role, name: $name)';
  }
}
