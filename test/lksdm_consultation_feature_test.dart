import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/dashboard/screens/admin_dashboard_screen.dart';
import 'package:forum_brin_mobile/features/dashboard/screens/ketua_tim_dashboard_screen.dart';
import 'package:forum_brin_mobile/features/questions/data/tusi_catalog_data.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';
import 'package:forum_brin_mobile/features/questions/screens/ask_question_screen.dart';
import 'package:forum_brin_mobile/features/questions/screens/lksdm_consultation_tickets_screen.dart';

void main() {
  group('Fitur Konsultasi Mandiri LKSDM ke Pusat Tests', () {
    const adminLksdmUser = UserModel(
      id: 'lksdm-staff-1',
      name: 'Budi Santoso (Admin LKSDM)',
      email: 'budi.lksdm@brin.go.id',
      role: 'admin_lksdm',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    const ketuaTimLksdmUser = UserModel(
      id: 'lksdm-ketua-1',
      name: 'Dr. Hendra (Ketua Tim LKSDM)',
      email: 'hendra.ketua@brin.go.id',
      role: 'ketua_tim',
      eskalasi: 'LKSDM',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    test('UserModel role validation for LKSDM members', () {
      expect(adminLksdmUser.isAdminLksdm, isTrue);
      expect(adminLksdmUser.isLksdmMember, isTrue);
      expect(ketuaTimLksdmUser.isKetuaTimLksdm, isTrue);
      expect(ketuaTimLksdmUser.isLksdmMember, isTrue);
    });

    test('TicketStatus.mandiriLksdm parsing and properties', () {
      final status1 = TicketStatus.fromString('TIKET_MANDIRI_LKSDM');
      final status2 = TicketStatus.fromString('konsultasi_lksdm');
      expect(status1, equals(TicketStatus.mandiriLksdm));
      expect(status2, equals(TicketStatus.mandiriLksdm));
      expect(status1.shortLabel, equals('Konsultasi LKSDM'));
      expect(status1.isActive, isTrue);
      expect(status1.isClosed, isFalse);
    });

    test('QuestionModel.isMandiriLksdm detection', () {
      final qMandiri = QuestionModel(
        id: 101,
        judul: 'Konsultasi Perbup Formasi JF Peneliti',
        isi: 'Mohon arahan perihal regulasi formasi...',
        status: 'tiket_mandiri_lksdm',
        targetTimPusat: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I',
        lksdmKawasan: 'LKSDM 1',
      );
      expect(qMandiri.isMandiriLksdm, isTrue);
      expect(qMandiri.ticketStatus, equals(TicketStatus.mandiriLksdm));
    });

    testWidgets('AskQuestionScreen renders correctly in LKSDM Consultation mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AskQuestionScreen(
            token: 'test-token',
            user: adminLksdmUser,
            isLksdmConsultation: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header Mode Konsultasi
      expect(find.text('Konsultasi ke Tim Pusat'), findsOneWidget);
      expect(find.text('1. Asal Kawasan LKSDM Pengaju'), findsOneWidget);
      expect(find.text('2. Tim Pusat yang Dituju *'), findsOneWidget);
      expect(find.text('3. Topik / Judul Konsultasi'), findsOneWidget);
      expect(find.text('4. Rincian Kendala / Permohonan Arahan'), findsOneWidget);
      expect(find.text('Kirim Konsultasi ke Tim Pusat'), findsOneWidget);

      // Verify Central Teams dropdown contains official 14 central teams
      expect(find.text(TusiCatalogData.centralTeams.first), findsOneWidget);
    });

    testWidgets('LksdmConsultationTicketsScreen renders tabs, empty state, and action button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LksdmConsultationTicketsScreen(user: adminLksdmUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title and Tabs
      expect(find.text('Konsultasi Saya ke Pusat'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Diproses Pusat'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Konsultasi Baru'), findsOneWidget);
    });

    testWidgets('AdminDashboardScreen shows Consultation Card when user is LKSDM',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(user: adminLksdmUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Consultation Card on LKSDM Dashboard
      expect(find.text('Konsultasi Mandiri ke Pusat'), findsOneWidget);
      expect(find.text('Tiket Saya'), findsOneWidget);
      expect(find.text('Konsultasi Baru'), findsOneWidget);
    });

    testWidgets('KetuaTimDashboardScreen shows Consultation Card when user is LKSDM',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: KetuaTimDashboardScreen(user: ketuaTimLksdmUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Consultation Card on Ketua Tim LKSDM Dashboard
      expect(find.text('Konsultasi Mandiri ke Pusat'), findsOneWidget);
      expect(find.text('Tiket Saya'), findsOneWidget);
      expect(find.text('Konsultasi Baru'), findsOneWidget);
    });
  });
}
