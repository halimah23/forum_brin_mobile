import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../../main/presentation/pages/pages.dart';
import '../../notifications/services/notification_service.dart';

class RoleRouterScreen extends StatefulWidget {
  final UserModel user;

  const RoleRouterScreen({
    super.key,
    required this.user,
  });

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  void initState() {
    super.initState();
    final uid = widget.user.id?.toString();
    if (uid != null && uid.isNotEmpty) {
      NotificationService.startRealtimeSubscription(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan halaman dashboard utama berdasarkan enum UserRole
    switch (widget.user.userRole) {
      case UserRole.superAdmin:
        return SuperAdminMainTabPage(user: widget.user);

      case UserRole.admin:
      case UserRole.adminLksdm:
      case UserRole.adminPusat:
        return AdminMainTabPage(user: widget.user);

      case UserRole.ketuaTim:
        return KetuaTimMainTabPage(user: widget.user);

      case UserRole.eksekutif:
        return EksekutifMainTabPage(user: widget.user);

      case UserRole.member:
        return MemberMainTabPage(user: widget.user);
    }
  }
}
