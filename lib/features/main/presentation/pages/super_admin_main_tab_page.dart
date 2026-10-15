import 'package:flutter/material.dart';
import '../../../auth/models/user_model.dart';
import '../../../dashboard/screens/super_admin_audit_screen.dart';
import '../../../dashboard/screens/super_admin_dashboard_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../questions/screens/super_admin_forum_screen.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import 'menu_types.dart';

class SuperAdminMainTabPage extends StatefulWidget {
  final UserModel user;

  const SuperAdminMainTabPage({
    super.key,
    required this.user,
  });

  @override
  State<SuperAdminMainTabPage> createState() => _SuperAdminMainTabPageState();
}

class _SuperAdminMainTabPageState extends State<SuperAdminMainTabPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF512DA8);

    final pages = [
      SuperAdminDashboardScreen(
        user: widget.user,
      ),
      SuperAdminAuditScreen(
        user: widget.user,
      ),
      SuperAdminForumScreen(
        user: widget.user,
      ),
      ProfileScreen(
        user: widget.user,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryPurple,
        items: SuperAdminMenuType.values
            .map(
              (type) => AppBottomNavItem(
                label: type.label,
                unselectedIconBuilder: type.unselectedIconBuilder,
                selectedIconBuilder: type.selectedIconBuilder,
              ),
            )
            .toList(),
      ),
    );
  }
}
