import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/answer_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/screens/question_detail_screen.dart';

void main() {
  group('Konfirmasi Penyelesaian Jawaban Tests', () {
    const memberUser = UserModel(
      id: 'member-user-1',
      name: 'Rian Pegawai',
      email: 'rian@brin.go.id',
      role: 'member',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    const adminLksdmUser = UserModel(
      id: 'admin-lksdm-1',
      name: 'Budi Staf LKSDM',
      email: 'budi@brin.go.id',
      role: 'admin_lksdm',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    const ketuaLksdmUser = UserModel(
      id: 'ketua-lksdm-1',
      name: 'Dr. Hendra Ketua LKSDM',
      email: 'hendra@brin.go.id',
      role: 'ketua_tim',
      eskalasi: 'LKSDM',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    final dummyQuestion = QuestionModel(
      id: 777,
      userId: 'member-user-1',
      user: memberUser,
      judul: 'Pertanyaan Terkait SK Formasi Fungsional',
      isi: 'Bagaimana status usulan formasi fungsional saya?',
      status: 'ditangani_lksdm',
      lksdmKawasan: 'LKSDM 1',
      ticketNumber: 'TKT-2026-0777',
      answers: const [
        AnswerModel(
          id: 1,
          questionId: 777,
          userId: 'admin-lksdm-1',
          senderName: 'Budi Staf LKSDM',
          isiPesan: 'Halo Rian, berkas usulan Anda telah diverifikasi oleh tim LKSDM 1.',
          senderRole: 'admin_lksdm',
          senderRoleType: 'admin_lksdm',
        ),
      ],
    );

    testWidgets('Member screen shows Ya, Terjawab and Belum Terjawab without escalation button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: dummyQuestion,
            currentUser: memberUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan judul kartu konfirmasi hadir
      expect(find.text('Konfirmasi Penyelesaian'), findsOneWidget);
      expect(
        find.text('Apakah solusi dan penjelasan di atas telah menjawab pertanyaan Anda?'),
        findsOneWidget,
      );

      // Verifikasi tombol Ya, Terjawab & Belum Terjawab
      expect(find.byKey(const ValueKey('confirm_resolution_yes')), findsOneWidget);
      expect(find.text('Ya, Terjawab'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_resolution_no')), findsOneWidget);
      expect(find.text('Belum Terjawab'), findsOneWidget);

      // Memastikan teks lama "Belum / Butuh Eskalasi" TIDAK ADA
      expect(find.text('Belum / Butuh Eskalasi'), findsNothing);

      // Memastikan tombol Alihkan ke Pusat TIDAK ADA pada akun member
      expect(find.text('Alihkan ke Pusat'), findsNothing);
    });

    testWidgets('Admin LKSDM and Ketua LKSDM see Alihkan ke Pusat toolbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Tes Staf Admin LKSDM
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: dummyQuestion,
            currentUser: adminLksdmUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Staf Admin LKSDM memiliki tombol 'Alihkan ke Pusat'
      expect(find.text('Alihkan ke Pusat'), findsOneWidget);

      // Tes Ketua Tim LKSDM
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: dummyQuestion,
            currentUser: ketuaLksdmUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ketua Tim LKSDM juga memiliki tombol 'Alihkan ke Pusat'
      expect(find.text('Alihkan ke Pusat'), findsOneWidget);
    });

    testWidgets('Clicking Belum Terjawab shows notification info and ticket continues',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: dummyQuestion,
            currentUser: memberUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol Belum Terjawab
      await tester.ensureVisible(find.byKey(const ValueKey('confirm_resolution_no')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_resolution_no')));
      await tester.pumpAndSettle();

      // Dialog eskalasi TIDAK BOLEH muncul
      expect(find.text('Eskalasi ke Tim Pusat'), findsNothing);
      expect(find.text('Pilih Tim Pusat tujuan eskalasi tiket:'), findsNothing);

      // SnackBar pemberitahuan bahwa tiket tetap aktif dan notifikasi dikirimkan
      expect(
        find.text('Konfirmasi tersimpan. Tiket tetap aktif dan pemberitahuan telah dikirim ke tim penangan untuk tindak lanjut.'),
        findsOneWidget,
      );
    });
  });
}
