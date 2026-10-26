import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/data/lksdm_catalog_data.dart';
import 'package:forum_brin_mobile/features/questions/data/tusi_catalog_data.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/widgets/reopen_ticket_dialog.dart';

void main() {
  group('ReopenTicketDialog & Flow Tests', () {
    final mockQuestion = QuestionModel(
      id: 99,
      ticketNumber: 'TKT-2026-0099',
      judul: 'Permohonan Mutasi dan Penyesuaian SK',
      isi: 'Detail kendala tiket...',
      status: 'selesai',
      lksdmKawasan: 'LKSDM 1',
      targetTimPusat: 'Fungsi Mutasi Umum dan Kesejahteraan',
      user: const UserModel(
        id: 'user-123',
        name: 'Pegawai Uji Coba',
        email: 'pegawai@brin.go.id',
      ),
    );

    testWidgets('ReopenTicketDialog renders correctly with scrollable content and forms',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ReopenTicketDialog.show(
                      context,
                      question: mockQuestion,
                      superAdminName: 'Super Admin Utama',
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Header and Summary
      expect(find.text('Buka Kembali Tiket'), findsOneWidget);
      expect(find.text('TKT-2026-0099'), findsOneWidget);
      expect(find.text('Status Saat Ini: SELESAI'), findsOneWidget);
      expect(find.text('Permohonan Mutasi dan Penyesuaian SK'), findsOneWidget);

      // Verify ScrollView exists to prevent keyboard obstruction
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify target destination choices
      expect(find.text('Staf Layanan Kawasan SDM (LKSDM)'), findsOneWidget);
      expect(find.text('Staf Layanan SDM Pusat (BOSDM Pusat)'), findsOneWidget);

      // Verify default selection (mockQuestion had targetTimPusat, so defaults to pusat)
      expect(find.text('Pilih Tim Kerja Pusat Tujuan: *'), findsOneWidget);

      // Switch to LKSDM destination
      await tester.tap(find.text('Staf Layanan Kawasan SDM (LKSDM)'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Kawasan LKSDM Tujuan: *'), findsOneWidget);

      // Verify note input field
      expect(find.byType(TextFormField), findsOneWidget);

      // Scroll to button and tap 'Aktifkan Kembali Tiket' without input -> validation fails
      final confirmBtn = find.text('Aktifkan Kembali Tiket');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(find.text('Catatan alasan wajib diisi untuk rekam audit sistem.'), findsOneWidget);
    });

    test('Catalog items availability check', () {
      expect(LksdmCatalogData.allLksdm.length, greaterThanOrEqualTo(8));
      expect(TusiCatalogData.centralTeams.length, greaterThanOrEqualTo(14));
      expect(TusiCatalogData.centralTeams, contains('Fungsi Mutasi Umum dan Kesejahteraan'));
    });
  });
}
