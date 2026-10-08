import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

typedef IconWidgetBuilder = Widget Function(Color color, double size);

class AppBottomNavItem {
  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const AppBottomNavItem({
    required this.label,
    required this.unselectedIconBuilder,
    required this.selectedIconBuilder,
  });
}

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? backgroundColor;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedItemColor ?? AppColors.primaryRed;
    final inactiveColor = unselectedItemColor ?? AppColors.slate400;
    final bgColor = backgroundColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: bgColor,
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            items: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == idx;
              final color = isSelected ? activeColor : inactiveColor;
              final builder = isSelected ? item.selectedIconBuilder : item.unselectedIconBuilder;

              return BottomNavigationBarItem(
                label: item.label,
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4, top: 4),
                  child: builder(color, 22),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
