import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/answer_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/screens/question_detail_screen.dart';
import 'package:forum_brin_mobile/features/questions/services/question_service.dart';

void main() {
  group('Auto-Close SLA 48 Jam & Gentle Reminder 24 Jam Tests', () {
    const testMember = UserModel(
      id: 'member-pegawai-1',
      name: 'Rudi Peneliti',
      email: 'rudi@brin.go.id',
      role: 'member',
      kawasan: 'KST Habibie Serpong',
      unit: 'LKSDM 1',
    );

    test('Tiket yang baru dijawab staf (<24 jam) tidak di-auto close dan tidak di-reminder', () async {
      final now = DateTime.now();
      final freshQuestion = QuestionModel(
        id: 1001,
        userId: 'member-pegawai-1',
        user: testMember,
        judul: 'Pertanyaan Formasi Peneliti Baru',
        isi: 'Bagaimana syarat mutasi formasi?',
        status: 'ditangani_lksdm',
        lksdmKawasan: 'LKSDM 1',
        createdAt: now.subtract(const Duration(minutes: 40)).toIso8601String(),
        answers: [
          AnswerModel(
            id: 1,
            questionId: 1001,
            userId: 'admin-1',
            senderName: 'Staf LKSDM',
            isiPesan: 'Halo Pak Rudi, syarat mutasi terlampir pada portal resmi.',
            senderRole: 'admin_lksdm',
            senderRoleType: 'admin_lksdm',
            createdAt: now.subtract(const Duration(minutes: 30)).toIso8601String(),
          ),
        ],
      );

      await QuestionService.checkAndProcessAutoResolveQuestions([freshQuestion]);
      expect(freshQuestion.isClosed, isFalse);
    });

    test('Tiket di mana pesan terakhir adalah dari pegawai tidak boleh di-auto close', () async {
      final now = DateTime.now();
      final questionWaitingStaff = QuestionModel(
        id: 1002,
        userId: 'member-pegawai-1',
        user: testMember,
        judul: 'Pertanyaan Belum Jelas',
        isi: 'Mohon info kelanjutan...',
        status: 'ditangani_lksdm',
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        answers: [
          AnswerModel(
            id: 1,
            questionId: 1002,
            userId: 'admin-1',
            senderName: 'Staf LKSDM',
            isiPesan: 'Sudah kami cek ya pak.',
            senderRole: 'admin_lksdm',
            senderRoleType: 'admin_lksdm',
            createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
          ),
          AnswerModel(
            id: 2,
            questionId: 1002,
            userId: 'member-pegawai-1',
            senderName: 'Rudi Peneliti',
            isiPesan: 'Maaf pak, berkas bagian lampiran 2 masih belum bisa diakses.',
            senderRole: 'pegawai',
            senderRoleType: 'member',
            createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
          ),
        ],
      );

      // Bola ada di staf, sistem tidak boleh menutup tiket
      await QuestionService.checkAndProcessAutoResolveQuestions([questionWaitingStaff]);
      expect(questionWaitingStaff.isClosed, isFalse);
    });

    testWidgets('Tiket Auto-Close tetap memunculkan CSAT rating card opsional di layar Member',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final autoClosedQuestion = QuestionModel(
        id: 1003,
        userId: 'member-pegawai-1',
        user: testMember,
        judul: 'Pertanyaan SK Kenaikan Pangkat',
        isi: 'Bagaimana progres SK saya?',
        status: 'selesai',
        lksdmKawasan: 'LKSDM 1',
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        resolvedAt: now.subtract(const Duration(days: 2)).toIso8601String(),
        answers: [
          AnswerModel(
            id: 1,
            questionId: 1003,
            userId: 'admin-1',
            senderName: 'Staf LKSDM',
            isiPesan: 'SK sudah terbit di sistem kearsipan.',
            senderRole: 'admin_lksdm',
            senderRoleType: 'admin_lksdm',
            createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
          ),
          AnswerModel(
            id: 2,
            questionId: 1003,
            userId: 'system',
            senderName: 'Sistem',
            isiPesan:
                'Tiket ditutup otomatis oleh sistem setelah 48 jam tanpa tanggapan lanjutan dari pegawai. Penilaian kepuasan layanan tetap dapat diisi secara opsional.',
            senderRole: 'system',
            senderRoleType: 'system',
            createdAt: now.toIso8601String(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: autoClosedQuestion,
            currentUser: testMember,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi event pill penutupan otomatis 48 jam
      expect(
        find.text('Tiket telah diselesaikan otomatis oleh sistem (48 jam). Penilaian layanan bersifat opsional.'),
        findsOneWidget,
      );

      // Verifikasi kartu rating survei kepuasan (CSAT) tetap tampil secara opsional
      expect(find.text('Survei Kepuasan Layanan'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.text('Kirim Penilaian'), findsOneWidget);
    });
  });
}
