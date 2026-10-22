import 'user_role.dart';

class UserModel {
  final String? id;
  final String? username;
  final String name;
  final String email;
  final String? externalEmail;
  final String? phone;
  final String? sex;
  final String? role;
  final String? unit;
  final String? idTim;
  final String? tim;
  final String? eskalasi;
  final String? lksdm;
  final String? kawasan;
  final String? jabatan;
  final String? token;
  final String? photoUrl;

  const UserModel({
    this.id,
    this.username,
    required this.name,
    required this.email,
    this.externalEmail,
    this.phone,
    this.sex,
    this.role,
    this.unit,
    this.idTim,
    this.tim,
    this.eskalasi,
    this.lksdm,
    this.kawasan,
    this.jabatan,
    this.token,
    this.photoUrl,
  });

  /// Helper untuk mendapatkan enum role yang terstandarisasi dengan hierarki eskalasi tim
  UserRole get userRole => UserRole.fromString(role, eskalasi: eskalasi);

  /// Helper penanda peran pengguna
  bool get isPegawai => userRole == UserRole.member;
  bool get isMember => userRole == UserRole.member;
  bool get isEksekutif => userRole == UserRole.eksekutif;
  bool get isKetuaTim => userRole == UserRole.ketuaTim;
  bool get isSuperAdmin => userRole == UserRole.superAdmin;

  bool get isKetuaTimPusat =>
      isKetuaTim && (eskalasi == 'PUSAT' || (tim != null && !tim!.toUpperCase().contains('LKSDM')));
  bool get isKetuaTimLksdm =>
      isKetuaTim && (eskalasi == 'LKSDM' || (tim != null && tim!.toUpperCase().contains('LKSDM')));

  bool get isAdminLksdm {
    if (userRole == UserRole.adminLksdm || role == 'admin_lksdm') return true;
    if (eskalasi == 'LKSDM') return true;
    if (userRole == UserRole.admin || role == 'Staff Admin' || role == 'admin') {
      if (tim != null && tim!.toUpperCase().contains('LKSDM')) return true;
      if (unit != null && unit!.toUpperCase().contains('LKSDM')) return true;
      if (eskalasi == 'PUSAT') return false;
      return true;
    }
    return false;
  }

  bool get isAdminPusat {
    if (userRole == UserRole.adminPusat || role == 'admin_pusat') return true;
    if (eskalasi == 'PUSAT') return true;
    if (userRole == UserRole.admin || role == 'Staff Admin' || role == 'admin') {
      return !isAdminLksdm;
    }
    return false;
  }

  String? get satuanKerja => unit;

  String get effectiveLksdm {
    if (tim != null && tim!.toUpperCase().contains('LKSDM')) {
      return _normalizeLksdm(tim!);
    }
    if (kawasan != null && kawasan!.toUpperCase().contains('LKSDM')) {
      return _normalizeLksdm(kawasan!);
    }
    if (lksdm != null && lksdm!.toUpperCase().contains('LKSDM')) {
      return _normalizeLksdm(lksdm!);
    }
    if (unit != null && unit!.toUpperCase().contains('LKSDM')) {
      return _normalizeLksdm(unit!);
    }
    if (kawasan != null && kawasan!.isNotEmpty) {
      return kawasan!;
    }
    return 'LKSDM 1';
  }

  static String _normalizeLksdm(String input) {
    final match = RegExp(r'LKSDM\s*(\d+)', caseSensitive: false).firstMatch(input);
    if (match != null) {
      return 'LKSDM ${match.group(1)}';
    }
    return input.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // Mendukung skema tabel `users` baru maupun tabel lama
    final idVal = json['id_user']?.toString() ?? json['id']?.toString();
    final nameVal = json['first_name']?.toString() ??
        json['name']?.toString() ??
        json['nama']?.toString() ??
        json['username']?.toString() ??
        '-';
    final emailVal = json['email']?.toString() ?? '-';
    final roleVal = json['role']?.toString();
    final unitVal = json['satuan_kerja']?.toString() ?? json['unit']?.toString();
    final kawasanVal = json['kawasan']?.toString() ?? json['lksdm']?.toString() ?? json['wilayah_lksdm']?.toString();

    String? idTimVal = json['id_tim']?.toString();
    String? timVal = json['tim']?.toString();
    String? eskalasiVal = json['eskalasi']?.toString();

    // Jika relasi `teams` di-join oleh Supabase PostgREST
    if (json['teams'] is Map) {
      final tMap = json['teams'] as Map;
      idTimVal ??= tMap['id_tim']?.toString();
      timVal ??= tMap['tim']?.toString() ?? tMap['detail_nama_tim']?.toString();
      eskalasiVal ??= tMap['eskalasi']?.toString();
    }

    return UserModel(
      id: idVal,
      username: json['username']?.toString(),
      name: nameVal,
      email: emailVal,
      externalEmail: json['external_email']?.toString(),
      phone: json['phone']?.toString(),
      sex: json['sex']?.toString(),
      role: roleVal,
      unit: unitVal,
      idTim: idTimVal,
      tim: timVal,
      eskalasi: eskalasiVal,
      lksdm: kawasanVal,
      kawasan: kawasanVal,
      jabatan: json['jabatan']?.toString(),
      token: token ?? json['token']?.toString(),
      photoUrl: json['photo_url']?.toString() ??
          json['avatar_url']?.toString() ??
          json['foto']?.toString() ??
          json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': id,
      'username': username,
      'first_name': name,
      'name': name,
      'email': email,
      'external_email': externalEmail,
      'phone': phone,
      'sex': sex,
      'role': role,
      'unit': unit,
      'satuan_kerja': unit,
      'id_tim': idTim,
      'tim': tim,
      'eskalasi': eskalasi,
      'lksdm': lksdm,
      'kawasan': kawasan,
      'jabatan': jabatan,
      'token': token,
      'photo_url': photoUrl,
      'avatar_url': photoUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? externalEmail,
    String? phone,
    String? sex,
    String? role,
    String? unit,
    String? idTim,
    String? tim,
    String? eskalasi,
    String? lksdm,
    String? kawasan,
    String? jabatan,
    String? token,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      externalEmail: externalEmail ?? this.externalEmail,
      phone: phone ?? this.phone,
      sex: sex ?? this.sex,
      role: role ?? this.role,
      unit: unit ?? this.unit,
      idTim: idTim ?? this.idTim,
      tim: tim ?? this.tim,
      eskalasi: eskalasi ?? this.eskalasi,
      lksdm: lksdm ?? this.lksdm,
      kawasan: kawasan ?? this.kawasan,
      jabatan: jabatan ?? this.jabatan,
      token: token ?? this.token,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
