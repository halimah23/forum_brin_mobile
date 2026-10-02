import 'user_role.dart';

class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? role;
  final String? unit;
  final String? tim;
  final String? lksdm;
  final String? jabatan;
  final String? token;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.unit,
    this.tim,
    this.lksdm,
    this.jabatan,
    this.token,
  });

  /// Helper untuk mendapatkan enum role yang terstandarisasi
  UserRole get userRole => UserRole.fromString(role);

  /// Helper penanda peran pengguna
  bool get isPegawai => userRole == UserRole.member;
  bool get isMember => userRole == UserRole.member;
  bool get isEksekutif => userRole == UserRole.eksekutif;
  bool get isAdminLksdm =>
      role == 'admin_lksdm' ||
      (userRole == UserRole.admin &&
          (lksdm != null || (unit != null && unit!.toLowerCase().contains('lksdm'))));
  bool get isAdminPusat =>
      role == 'admin_pusat' || (userRole == UserRole.admin && !isAdminLksdm);

  String get effectiveLksdm =>
      lksdm ??
      (unit != null && unit!.toLowerCase().contains('lksdm')
          ? unit!
          : (tim != null && tim!.toLowerCase().contains('lksdm') ? tim! : 'LKSDM 1'));

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      role: json['role']?.toString(),
      unit: json['unit']?.toString(),
      tim: json['tim']?.toString(),
      lksdm: json['lksdm']?.toString() ?? json['wilayah_lksdm']?.toString(),
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
      'lksdm': lksdm,
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
    String? lksdm,
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
      lksdm: lksdm ?? this.lksdm,
      jabatan: jabatan ?? this.jabatan,
      token: token ?? this.token,
    );
  }
}
