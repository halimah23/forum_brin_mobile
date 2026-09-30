import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import 'member_dashboard_screen.dart';

/// Backward-compatible alias untuk MemberDashboardScreen
class DashboardScreen extends StatelessWidget {
  final UserModel user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return MemberDashboardScreen(user: user);
  }
}
