import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/models/user_model.dart';
import '../../../dashboard/screens/admin_dashboard_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../questions/screens/question_list_screen.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import 'menu_types.dart';

class AdminMainTabPage extends StatefulWidget {
  final UserModel user;

  const AdminMainTabPage({
    super.key,
    required this.user,
  });

  @override
  State<AdminMainTabPage> createState() => _AdminMainTabPageState();
}

class _AdminMainTabPageState extends State<AdminMainTabPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdminLksdm = widget.user.isAdminLksdm;
    final lksdmName = widget.user.effectiveLksdm;
    final teamName = widget.user.tim ?? (isAdminLksdm ? lksdmName : 'Fungsi Pengelolaan data dan informasi SDM');
    final primaryColor = isAdminLksdm ? Colors.teal.shade800 : AppColors.primaryBlue;

    final pages = [
      AdminDashboardScreen(
        user: widget.user,
      ),
      QuestionListScreen(
        user: widget.user,
        initialTeamFilter: isAdminLksdm ? lksdmName : teamName,
        title: isAdminLksdm ? 'Layanan SDM ($lksdmName)' : 'Layanan SDM ($teamName)',
      ),
      QuestionListScreen(
        user: widget.user,
        isPublicOnly: true,
        title: 'Forum Kepegawaian BRIN',
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
        selectedItemColor: primaryColor,
        items: AdminMenuType.values
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
