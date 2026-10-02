import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import 'admin_dashboard_screen.dart';
import 'eksekutif_dashboard_screen.dart';
import 'ketua_tim_dashboard_screen.dart';
import 'member_dashboard_screen.dart';
import 'super_admin_dashboard_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  final UserModel user;

  const RoleRouterScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Menentukan halaman dashboard berdasarkan enum UserRole
    switch (user.userRole) {
      case UserRole.superAdmin:
        return SuperAdminDashboardScreen(user: user);

      case UserRole.admin:
        return AdminDashboardScreen(user: user);

      case UserRole.ketuaTim:
        return KetuaTimDashboardScreen(user: user);

      case UserRole.eksekutif:
        return EksekutifDashboardScreen(user: user);

      case UserRole.member:
        return MemberDashboardScreen(user: user);
    }
  }
}
