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

/// Minimalist Floating Dock Bottom Navigation Bar
/// Sesuai tema: Modern Institutional White — Oceanic Blue, Teal & Amber
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
    final activeColor = selectedItemColor ?? AppColors.colorPrimary;
    final inactiveColor = unselectedItemColor ?? AppColors.colorTextMuted;
    final bgColor = backgroundColor ?? AppColors.colorSurface;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.colorBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F366A),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == idx;
              final color = isSelected ? activeColor : inactiveColor;
              final iconBuilder = isSelected
                  ? item.selectedIconBuilder
                  : item.unselectedIconBuilder;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(idx),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.colorPrimarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconBuilder(color, 20),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
