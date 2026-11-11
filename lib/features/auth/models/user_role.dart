enum UserRole {
  superAdmin,
  admin,
  adminLksdm,
  adminPusat,
  ketuaTim,
  eksekutif,
  sivitas;

  /// Backwards-compatibility alias agar kode lama tetap aman
  static const UserRole member = sivitas;

  static UserRole fromString(String? roleStr, {String? eskalasi}) {
    if (roleStr == null || roleStr.isEmpty) return UserRole.sivitas;
    final normalized = roleStr.toLowerCase().replaceAll(' ', '_').trim();
    final esk = eskalasi?.toUpperCase().trim();

    switch (normalized) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin_lksdm':
      case 'lksdm':
      case 'staf_lksdm':
      case 'staff_lksdm':
        return UserRole.adminLksdm;
      case 'admin_pusat':
      case 'adminpusat':
      case 'staf_pusat':
      case 'staff_pusat':
        return UserRole.adminPusat;
      case 'admin':
      case 'admin_layanan':
      case 'admin_tim':
      case 'admintim':
      case 'verifikator':
      case 'anggota_tim':
      case 'staf':
      case 'staff':
      case 'staf_admin':
      case 'staff_admin':
        if (esk == 'LKSDM') return UserRole.adminLksdm;
        if (esk == 'PUSAT') return UserRole.adminPusat;
        return UserRole.admin;
      case 'ketua_tim':
      case 'ketuatim':
      case 'leader':
        return UserRole.ketuaTim;
      case 'eksekutif':
      case 'executive':
      case 'pimpinan':
      case 'direktur':
        return UserRole.eksekutif;
      case 'sivitas':
      case 'member':
      case 'pegawai':
      case 'user':
      default:
        return UserRole.sivitas;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.adminLksdm:
        return 'Staf Admin LKSDM';
      case UserRole.adminPusat:
        return 'Staf Admin Pusat';
      case UserRole.admin:
        return 'Staf Admin';
      case UserRole.ketuaTim:
        return 'Ketua Tim';
      case UserRole.eksekutif:
        return 'Eksekutif';
      case UserRole.sivitas:
        return 'Sivitas';
    }
  }

  String get key {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.adminLksdm:
        return 'admin_lksdm';
      case UserRole.adminPusat:
        return 'admin_pusat';
      case UserRole.admin:
        return 'admin';
      case UserRole.ketuaTim:
        return 'ketua_tim';
      case UserRole.eksekutif:
        return 'eksekutif';
      case UserRole.sivitas:
        return 'sivitas';
    }
  }
}
