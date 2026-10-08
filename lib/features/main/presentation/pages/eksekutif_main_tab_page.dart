import 'package:flutter/material.dart';
import '../../../auth/models/user_model.dart';
import '../../../dashboard/screens/eksekutif_dashboard_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../../questions/screens/question_list_screen.dart';
import '../widgets/app_bottom_navigation_bar.dart';
import 'menu_types.dart';

class EksekutifMainTabPage extends StatefulWidget {
  final UserModel user;

  const EksekutifMainTabPage({
    super.key,
    required this.user,
  });

  @override
  State<EksekutifMainTabPage> createState() => _EksekutifMainTabPageState();
}

class _EksekutifMainTabPageState extends State<EksekutifMainTabPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryIndigo = Color(0xFF283593);

    final pages = [
      EksekutifDashboardScreen(
        user: widget.user,
      ),
      QuestionListScreen(
        user: widget.user,
        title: 'Monitoring Obrolan & Tiket',
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
        selectedItemColor: primaryIndigo,
        items: EksekutifMenuType.values
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
