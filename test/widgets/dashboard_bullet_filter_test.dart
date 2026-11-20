import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/dashboard/screens/admin_dashboard_screen.dart';
import 'package:forum_brin_mobile/features/dashboard/screens/ketua_tim_dashboard_screen.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';

void main() {
  group('Dashboard Bullet Filter Tests (Semua Chat Aktif Tampil di Beranda)', () {
    const testAdminLksdm = UserModel(
      id: 'admin-1',
      name: 'Staf LKSDM Serpong',
      email: 'staf.lksdm@brin.go.id',
      role: 'admin_lksdm',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    const testKetuaTim = UserModel(
      id: 'ketua-1',
      name: 'Ketua Tim LKSDM Serpong',
      email: 'ketua.lksdm@brin.go.id',
      role: 'ketua_tim',
      eskalasi: 'LKSDM',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    test('TicketStatus active definition guarantees in-progress tickets are active', () {
      final openStatus = TicketStatus.fromString('OPEN');
      final inProgressStatus = TicketStatus.fromString('ditangani_lksdm');
      final closedStatus = TicketStatus.fromString('closed');

      // OPEN dan DITANGANI_LKSDM keduanya harus isActive == true
      expect(openStatus.isActive, isTrue);
      expect(inProgressStatus.isActive, isTrue);
      // Closed tidak aktif
      expect(closedStatus.isActive, isFalse);
    });

    testWidgets('AdminDashboardScreen renders Bullet Filter chips correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(user: testAdminLksdm),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan bullet filter hadir di widget tree
      expect(find.byKey(const ValueKey('bullet_filter_all_active')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_open')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_in_progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_closed')), findsOneWidget);

      // Verifikasi subtitle default beranda (Semua Aktif)
      expect(find.text('Menampilkan semua tiket aktif (belum selesai)'), findsOneWidget);

      // Klik bullet filter Belum Ditangani
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan antrean tiket baru belum ditangani'), findsOneWidget);

      // Klik bullet filter Sedang Ditangani (gunakan ensureVisible)
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan tiket sedang dalam proses penanganan'), findsOneWidget);

      // Klik bullet filter Selesai (gunakan ensureVisible)
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_closed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_closed')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan riwayat tiket selesai'), findsOneWidget);

      // Klik kembali ke Semua Aktif
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_all_active')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_all_active')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan semua tiket aktif (belum selesai)'), findsOneWidget);
    });

    testWidgets('KetuaTimDashboardScreen renders Bullet Filter chips correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: KetuaTimDashboardScreen(user: testKetuaTim),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan bullet filter hadir di widget tree Ketua Tim
      expect(find.byKey(const ValueKey('bullet_filter_all_active')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_open')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_in_progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_closed')), findsOneWidget);

      // Verifikasi subtitle default beranda
      expect(find.text('Menampilkan semua tiket aktif (belum selesai)'), findsOneWidget);

      // Klik bullet filter Perlu Disposisi
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan antrean tiket yang perlu disposisi'), findsOneWidget);

      // Klik bullet filter Sedang Diproses
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan tiket sedang ditangani tim'), findsOneWidget);

      // Klik bullet filter Selesai
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_closed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_closed')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan riwayat tiket selesai'), findsOneWidget);

      // Klik kembali ke Semua Aktif
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_all_active')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_all_active')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan semua tiket aktif (belum selesai)'), findsOneWidget);
    });
  });
}
