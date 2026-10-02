import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/core/widgets/status_badge.dart';
import 'package:forum_brin_mobile/features/questions/data/tusi_catalog_data.dart';
import 'package:forum_brin_mobile/features/questions/models/category_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/services/question_service.dart';

void main() {
  group('Tusi Routing & Catalog Tests', () {
    test('Memverifikasi 14 Tim Pusat BOSDM terdaftar lengkap', () {
      expect(TusiCatalogData.allTeams.length, 14);
      expect(TusiCatalogData.allTeams.contains('Fungsi Organisasi dan Tatalaksana'), isTrue);
      expect(TusiCatalogData.allTeams.contains('Fungsi Perencanaan dan Pengembangan Karir SDM'), isTrue);
      expect(TusiCatalogData.allTeams.contains('Fungsi Penilaian Kompetensi'), isTrue);
      expect(TusiCatalogData.allTeams.contains('Fungsi Perencanaan dan Pengembangan Kompetensi SDM'), isTrue);
      expect(TusiCatalogData.allTeams.contains('Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I'), isTrue);
    });

    test('Routing otomatis ke Tim berdasarkan kode atau nama Tusi', () {
      // 1. Ortala
      expect(QuestionService.determineTeamName('ORTALA-01 - Evaluasi Organisasi'), 'Fungsi Organisasi dan Tatalaksana');
      expect(QuestionService.determineTeamName('Penyusunan Peta Jabatan'), 'Fungsi Organisasi dan Tatalaksana');

      // 2. RB
      expect(QuestionService.determineTeamName('RB-02 - Zona Integritas'), 'Fungsi Kesekretariatan RB');

      // 3. Karir
      expect(QuestionService.determineTeamName('BANGKAR-01 - Analisis Beban Kerja (ABK)'), 'Fungsi Perencanaan dan Pengembangan Karir SDM');

      // 4. JF 1 & HKM
      expect(QuestionService.determineTeamName('JF1-01 - Penilaian Usulan HKM Peneliti'), 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I');

      // 5. Manajemen Kinerja
      expect(QuestionService.determineTeamName('Penilaian Kinerja & SK Tunjangan Kinerja'), 'Fungsi Manajemen Kinerja dan Penghargaan ASN');

      // 6. Disiplin & CLTN
      expect(QuestionService.determineTeamName('DISIPLIN-01 - CLTN'), 'Fungsi Pembinaan dan Penegakkan Disiplin ASN');
    });

    test('Filter daftar Tusi per Tim', () {
      final ortalaTusi = TusiCatalogData.getTugasFungsiByTeam('Fungsi Organisasi dan Tatalaksana');
      expect(ortalaTusi.isNotEmpty, isTrue);
      for (var item in ortalaTusi) {
        expect(item.teamName, 'Fungsi Organisasi dan Tatalaksana');
      }
    });
  });

  group('Question & Category Model Tests', () {
    test('Serialisasi CategoryModel', () {
      const cat = CategoryModel(
        id: 1,
        kode: 'BRIN-04.03.01.01',
        nama: 'Evaluasi Organisasi',
        teamName: 'Tim Ortala',
      );

      final json = cat.toJson();
      final fromJson = CategoryModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.kode, 'BRIN-04.03.01.01');
      expect(fromJson.nama, 'Evaluasi Organisasi');
      expect(fromJson.fullDisplayName, 'BRIN-04.03.01.01 - Evaluasi Organisasi');
    });

    test('Serialisasi QuestionModel Ticketing', () {
      const q = QuestionModel(
        id: 99,
        ticketNumber: 'TKT-202609-099',
        judul: 'Pertanyaan Uji Kompetensi',
        isi: 'Rincian pertanyaan...',
        status: 'menunggu_disposisi',
        targetTim: 'Tim Mutasi dan Pengelolaan JF 1',
        assignedTo: 'Analis JF',
        tugasFungsiNama: 'BRIN-04.03.06.02.01.02 - Uji Kompetensi',
      );

      final json = q.toJson();
      final fromJson = QuestionModel.fromJson(json);

      expect(fromJson.id, 99);
      expect(fromJson.ticketNumber, 'TKT-202609-099');
      expect(fromJson.status, 'menunggu_disposisi');
      expect(fromJson.targetTim, 'Tim Mutasi dan Pengelolaan JF 1');
      expect(fromJson.assignedTo, 'Analis JF');
    });
  });

  group('StatusBadge Widget Tests', () {
    testWidgets('Merender badge Menunggu Disposisi', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'menunggu_disposisi'),
          ),
        ),
      );

      expect(find.text('Menunggu Disposisi'), findsOneWidget);
    });

    testWidgets('Merender badge Sedang Diproses', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'sedang_diproses'),
          ),
        ),
      );

      expect(find.text('Sedang Diproses'), findsOneWidget);
    });

    testWidgets('Merender badge Selesai', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'selesai'),
          ),
        ),
      );

      expect(find.text('Selesai'), findsOneWidget);
    });
  });
}
