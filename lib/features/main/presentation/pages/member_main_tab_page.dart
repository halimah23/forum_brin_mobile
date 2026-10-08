import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/models/user_model.dart';
import '../../../dashboard/screens/member_dashboard_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../questions/screens/question_list_screen.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import 'menu_types.dart';

class MemberMainTabPage extends StatefulWidget {
  final UserModel user;

  const MemberMainTabPage({
    super.key,
    required this.user,
  });

  @override
  State<MemberMainTabPage> createState() => _MemberMainTabPageState();
}

class _MemberMainTabPageState extends State<MemberMainTabPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MemberDashboardScreen(
        user: widget.user,
      ),
      QuestionListScreen(
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
        selectedItemColor: AppColors.primaryRed,
        items: MemberMenuType.values
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
