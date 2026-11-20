import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/dashboard/screens/member_dashboard_screen.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';
import 'package:forum_brin_mobile/features/questions/screens/member_tickets_screen.dart';

void main() {
  group('MemberDashboardScreen & MemberTicketsScreen Filter Tests', () {
    const testSivitas = UserModel(
      id: 'usr_sivitas_1',
      name: 'Rian Pegawai BRIN',
      email: 'rian@brin.go.id',
      role: 'sivitas',
      kawasan: 'KST Habibie Serpong',
      unit: 'Pusat Riset Fisika',
    );

    test('TicketStatus resolves closed and resolved as closed', () {
      final openStatus = TicketStatus.fromString('OPEN');
      final inProgressStatus = TicketStatus.fromString('IN_PROGRESS');
      final resolvedStatus = TicketStatus.fromString('RESOLVED');
      final closedStatus = TicketStatus.fromString('CLOSED');

      expect(openStatus.isActive, isTrue);
      expect(openStatus.isClosed, isFalse);

      expect(inProgressStatus.isActive, isTrue);
      expect(inProgressStatus.isClosed, isFalse);

      expect(resolvedStatus.isClosed, isTrue);
      expect(resolvedStatus.isActive, isFalse);

      expect(closedStatus.isClosed, isTrue);
      expect(closedStatus.isActive, isFalse);
    });

    testWidgets('MemberDashboardScreen renders status filters, category filters, and Buku Saku',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MemberDashboardScreen(user: testSivitas),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan bullet status filter hadir
      expect(find.byKey(const ValueKey('bullet_filter_all_active')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_open')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_in_progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('bullet_filter_closed')), findsOneWidget);

      // Verifikasi subtitle default beranda (Semua Aktif)
      expect(find.text('Menampilkan semua tiket aktif (belum selesai)'), findsOneWidget);

      // Klik filter Belum Ditangani
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_open')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan antrean tiket baru belum ditangani'), findsOneWidget);

      // Klik filter Sedang Ditangani
      await tester.ensureVisible(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bullet_filter_in_progress')));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan tiket sedang dalam proses penanganan'), findsOneWidget);

      // Klik filter Selesai
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

      // Memastikan Buku Saku Tupoksi hadir di Halaman Beranda
      expect(find.byKey(const ValueKey('member_buku_saku_beranda')), findsOneWidget);
      expect(find.text('Buku Saku Tupoksi 14 Tim BOSDM'), findsOneWidget);
    });

    testWidgets('MemberTicketsScreen renders 4 status tabs correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MemberTicketsScreen(user: testSivitas),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Semua Aktif'), findsOneWidget);
      expect(find.text('Belum Ditangani'), findsOneWidget);
      expect(find.text('Sedang Ditangani'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });
  });
}
