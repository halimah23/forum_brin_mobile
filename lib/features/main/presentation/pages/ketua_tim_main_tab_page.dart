import 'package:flutter/material.dart';
import '../../../auth/models/user_model.dart';
import '../../../dashboard/screens/ketua_tim_dashboard_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../questions/screens/question_list_screen.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import 'menu_types.dart';

class KetuaTimMainTabPage extends StatefulWidget {
  final UserModel user;

  const KetuaTimMainTabPage({
    super.key,
    required this.user,
  });

  @override
  State<KetuaTimMainTabPage> createState() => _KetuaTimMainTabPageState();
}

class _KetuaTimMainTabPageState extends State<KetuaTimMainTabPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primaryTeal = Colors.teal.shade800;
    final isLksdm = widget.user.isKetuaTimLksdm;
    final teamFilter = isLksdm ? widget.user.effectiveLksdm : (widget.user.tim ?? 'Tim Layanan SDM BOSDM');
    final teamName = teamFilter;

    final pages = [
      KetuaTimDashboardScreen(
        user: widget.user,
      ),
      QuestionListScreen(
        user: widget.user,
        initialTeamFilter: teamFilter,
        title: 'Tiket & Disposisi ($teamName)',
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
        selectedItemColor: primaryTeal,
        items: KetuaTimMenuType.values
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
