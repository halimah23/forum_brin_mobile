enum UserRole {
  superAdmin,
  admin,
  ketuaTim,
  member;

  static UserRole fromString(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) return UserRole.member;
    final normalized = roleStr.toLowerCase().replaceAll(' ', '_').trim();
    switch (normalized) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin':
      case 'admin_layanan':
      case 'admin_tim':
      case 'admintim':
      case 'verifikator':
      case 'anggota_tim':
      case 'staf':
      case 'staff':
        return UserRole.admin;
      case 'ketua_tim':
      case 'ketuatim':
      case 'leader':
        return UserRole.ketuaTim;
      case 'member':
      case 'pegawai':
      case 'user':
      default:
        return UserRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.ketuaTim:
        return 'Ketua Tim';
      case UserRole.member:
        return 'Member';
    }
  }

  String get key {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.ketuaTim:
        return 'ketua_tim';
      case UserRole.member:
        return 'member';
    }
  }
}
