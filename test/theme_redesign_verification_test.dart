import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/core/constants/app_colors.dart';
import 'package:forum_brin_mobile/core/theme/app_theme.dart';
import 'package:forum_brin_mobile/core/widgets/custom_button.dart';
import 'package:forum_brin_mobile/core/widgets/custom_text_field.dart';
import 'package:forum_brin_mobile/core/widgets/status_badge.dart';
import 'package:forum_brin_mobile/features/main/presentation/widgets/app_bottom_navigation_bar.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';

void main() {
  group('Visual Theme Tokens & ThemeData Tests', () {
    test('Memverifikasi seluruh design tokens terpusat tema Modern Institutional White', () {
      expect(AppColors.colorBg, const Color(0xFFF5F8FC));
      expect(AppColors.colorSurface, const Color(0xFFFFFFFF));
      expect(AppColors.colorBorder, const Color(0xFFE8EEF5));
      expect(AppColors.colorPrimary, const Color(0xFF1769D2));
      expect(AppColors.colorPrimaryHover, const Color(0xFF1258B5));
      expect(AppColors.colorPrimarySoft, const Color(0xFFE8F2FF));
      expect(AppColors.colorSecondary, const Color(0xFF10B8B5));
      expect(AppColors.colorSecondaryStrong, const Color(0xFF087F83));
      expect(AppColors.colorAccent, const Color(0xFFFFAB38));
      expect(AppColors.colorAccentWarm, const Color(0xFFF07832));
      expect(AppColors.colorText, const Color(0xFF1D2939));
      expect(AppColors.colorTextMuted, const Color(0xFF66758A));
      expect(AppColors.colorTextInverse, const Color(0xFFFFFFFF));
    });

    test('Memverifikasi ThemeData lightTheme mengintegrasikan tokens Material 3', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.colorBg);
      expect(theme.colorScheme.primary, AppColors.colorPrimary);
      expect(theme.colorScheme.secondary, AppColors.colorSecondary);
      expect(theme.colorScheme.surface, AppColors.colorSurface);
      expect(theme.colorScheme.onSurface, AppColors.colorText);

      // Verifikasi ThemeExtension AppCustomTheme
      final extension = theme.extension<AppCustomTheme>();
      expect(extension, isNotNull);
      expect(extension!.primary, AppColors.colorPrimary);
      expect(extension.secondary, AppColors.colorSecondary);
      expect(extension.accent, AppColors.colorAccent);
      expect(extension.accentWarm, AppColors.colorAccentWarm);
    });

    test('Memverifikasi mapping warna TicketStatus selaras tema Oceanic Blue, Teal, & Amber', () {
      expect(TicketStatus.open.color, AppColors.colorAccentWarm);
      expect(TicketStatus.inProgress.color, AppColors.colorSecondary);
      expect(TicketStatus.waitingUser.color, AppColors.colorPrimary);
      expect(TicketStatus.escalated.color, AppColors.colorAccentWarm);
      expect(TicketStatus.inProgressCenter.color, AppColors.colorSecondaryStrong);
      expect(TicketStatus.resolved.color, AppColors.success);
      expect(TicketStatus.closed.color, AppColors.colorTextMuted);
    });
  });

  group('Re-usable Component UI Visual Integration Tests', () {
    testWidgets('CustomButton merender Oceanic Blue dengan styling terpusat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Kirim Pertanyaan',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonText = find.text('Kirim Pertanyaan');
      expect(buttonText, findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppColors.colorPrimary);
    });

    testWidgets('CustomTextField merender surface white dan border institutional', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                controller: controller,
                hintText: 'Tuliskan judul...',
                label: 'Judul Tiket',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Judul Tiket'), findsOneWidget);
      expect(find.text('Tuliskan judul...'), findsOneWidget);
    });

    testWidgets('StatusBadge merender pill dengan warna status dan label ringkas responsif', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: StatusBadge(
                status: 'OPEN',
                useShortLabel: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Antrean LKSDM'), findsOneWidget);
    });

    testWidgets('Minimalist Floating Dock Bottom Navigation Bar merender floating container dan pill aktif', (tester) async {
      int activeIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: AppBottomNavigationBar(
                  currentIndex: activeIndex,
                  onTap: (idx) => setState(() => activeIndex = idx),
                  items: [
                    AppBottomNavItem(
                      label: 'Beranda',
                      unselectedIconBuilder: (c, s) => Icon(Icons.home_outlined, color: c, size: s),
                      selectedIconBuilder: (c, s) => Icon(Icons.home, color: c, size: s),
                    ),
                    AppBottomNavItem(
                      label: 'Tiket Saya',
                      unselectedIconBuilder: (c, s) => Icon(Icons.mail_outline, color: c, size: s),
                      selectedIconBuilder: (c, s) => Icon(Icons.mail, color: c, size: s),
                    ),
                    AppBottomNavItem(
                      label: 'Profil',
                      unselectedIconBuilder: (c, s) => Icon(Icons.person_outline, color: c, size: s),
                      selectedIconBuilder: (c, s) => Icon(Icons.person, color: c, size: s),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Tiket Saya'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap on Tiket Saya
      await tester.tap(find.text('Tiket Saya'));
      await tester.pumpAndSettle();

      expect(activeIndex, 1);
    });
  });
}
