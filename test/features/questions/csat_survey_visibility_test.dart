import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/widgets/csat_rating_card.dart';

void main() {
  group('Survey & Question Ownership Verification', () {
    const pegawaiA = UserModel(
      id: 'user-pegawai-1',
      name: 'Budi Santoso',
      email: 'budi@brin.go.id',
      role: 'member',
    );

    const pegawaiB = UserModel(
      id: 'user-pegawai-2',
      name: 'Siti Aminah',
      email: 'siti@brin.go.id',
      role: 'member',
    );

    const staffLksdm = UserModel(
      id: 'user-staff-lksdm-1',
      name: 'Ahmad LKSDM',
      email: 'ahmad@lksdm.brin.go.id',
      role: 'admin_lksdm',
      eskalasi: 'LKSDM',
      lksdm: 'LKSDM 1 : Thamrin I',
    );

    const adminPusat = UserModel(
      id: 'user-admin-pusat-1',
      name: 'Rudi Pusat',
      email: 'rudi@pusat.brin.go.id',
      role: 'admin_pusat',
      eskalasi: 'PUSAT',
    );

    test('isCreatedBy returns true only for the actual creator (Pegawai)', () {
      const qPegawai = QuestionModel(
        id: 101,
        judul: 'Pertanyaan Kenaikan Pangkat Pegawai',
        isi: 'Bagaimana prosedur kenaikan pangkat tahun ini?',
        status: 'selesai',
        rawUserId: 'user-pegawai-1',
        user: pegawaiA,
      );

      // Pembuat asli (Pegawai A)
      expect(qPegawai.isCreatedBy(pegawaiA), isTrue);

      // Pegawai lain (Pegawai B) tidak boleh diakui sebagai pembuat
      expect(qPegawai.isCreatedBy(pegawaiB), isFalse);

      // Staf LKSDM bukan pembuat
      expect(qPegawai.isCreatedBy(staffLksdm), isFalse);
    });

    test('isCreatedBy returns true for Staff LKSDM who submitted consultation to Pusat', () {
      const qMandiriLksdm = QuestionModel(
        id: 102,
        judul: 'Konsultasi Verifikasi PAK ke Tim Pusat',
        isi: 'Mohon arahan terkait berkas PAK yang tertunda di pusat.',
        status: 'selesai',
        targetTimPusat: 'PDIS',
        rawUserId: 'user-staff-lksdm-1',
        user: staffLksdm,
      );

      // Pembuat asli (Staff LKSDM)
      expect(qMandiriLksdm.isCreatedBy(staffLksdm), isTrue);

      // Admin Pusat yang merespons tiket bukan pembuat
      expect(qMandiriLksdm.isCreatedBy(adminPusat), isFalse);

      // Pegawai lain bukan pembuat
      expect(qMandiriLksdm.isCreatedBy(pegawaiA), isFalse);
    });

    testWidgets('CsatRatingCard shows survey form only when NOT read-only', (tester) async {
      const unratedQuestion = QuestionModel(
        id: 201,
        judul: 'Layanan Penggantian Kartu',
        isi: 'Kartu pegawai saya hilang.',
        status: 'selesai',
      );

      // 1. Tampilan untuk pembuat tiket (isReadOnly = false) -> form survei muncul
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CsatRatingCard(
              question: unratedQuestion,
              isReadOnly: false,
            ),
          ),
        ),
      );

      expect(find.text('Survei Kepuasan Layanan'), findsOneWidget);
      expect(find.text('Kirim Penilaian'), findsOneWidget);

      // 2. Tampilan untuk admin / bukan pembuat (isReadOnly = true) -> survei form disembunyikan
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CsatRatingCard(
              question: unratedQuestion,
              isReadOnly: true,
            ),
          ),
        ),
      );

      expect(find.text('Survei Kepuasan Layanan'), findsNothing);
      expect(find.text('Kirim Penilaian'), findsNothing);
    });

    testWidgets('CsatRatingCard shows submitted rating for readOnly and owner', (tester) async {
      const ratedQuestion = QuestionModel(
        id: 202,
        judul: 'Layanan Cuti Tahunan',
        isi: 'Cuti tahunan belum masuk.',
        status: 'selesai',
        rating: 5,
        ratingFeedback: 'Pelayanan sangat cepat dan ramah!',
        ratingTags: 'Respon Cepat (Gercep)',
      );

      // 1. Asker view
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CsatRatingCard(
              question: ratedQuestion,
              isReadOnly: false,
            ),
          ),
        ),
      );

      expect(find.text('Telah Dinilai'), findsOneWidget);
      expect(find.text('Ulasan: "Pelayanan sangat cepat dan ramah!"'), findsOneWidget);

      // 2. Admin read-only view
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CsatRatingCard(
              question: ratedQuestion,
              isReadOnly: true,
            ),
          ),
        ),
      );

      expect(find.text('Dinilai Pengaju'), findsOneWidget);
      expect(find.text('Ulasan: "Pelayanan sangat cepat dan ramah!"'), findsOneWidget);
    });
  });
}
