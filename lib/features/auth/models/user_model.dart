import 'user_role.dart';

class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? role;
  final String? unit;
  final String? tim;
  final String? jabatan;
  final String? token;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.unit,
    this.tim,
    this.jabatan,
    this.token,
  });

  /// Helper untuk mendapatkan enum role yang terstandarisasi
  UserRole get userRole => UserRole.fromString(role);

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      role: json['role']?.toString(),
      unit: json['unit']?.toString(),
      tim: json['tim']?.toString(),
      jabatan: json['jabatan']?.toString(),
      token: token ?? json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'unit': unit,
      'tim': tim,
      'jabatan': jabatan,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? unit,
    String? tim,
    String? jabatan,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      unit: unit ?? this.unit,
      tim: tim ?? this.tim,
      jabatan: jabatan ?? this.jabatan,
      token: token ?? this.token,
    );
  }
}
