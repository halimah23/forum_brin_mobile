import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../../main/presentation/pages/pages.dart';

class RoleRouterScreen extends StatelessWidget {
  final UserModel user;

  const RoleRouterScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Menentukan halaman dashboard utama berdasarkan enum UserRole
    switch (user.userRole) {
      case UserRole.superAdmin:
        return SuperAdminMainTabPage(user: user);

      case UserRole.admin:
      case UserRole.adminLksdm:
      case UserRole.adminPusat:
        return AdminMainTabPage(user: user);

      case UserRole.ketuaTim:
        return KetuaTimMainTabPage(user: user);

      case UserRole.eksekutif:
        return EksekutifMainTabPage(user: user);

      case UserRole.member:
        return MemberMainTabPage(user: user);
    }
  }
}
