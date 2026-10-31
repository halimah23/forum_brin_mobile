import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/questions/data/service_category_catalog.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/models/service_category_model.dart';
import 'package:forum_brin_mobile/features/questions/widgets/question_card.dart';

void main() {
  group('ServiceCategoryModel & Catalog Tests', () {
    test('ServiceCategoryCatalog contains the 9 required categories', () {
      final categories = ServiceCategoryCatalog.defaultCategories;
      expect(categories.length, equals(9));

      final names = categories.map((c) => c.nama).toList();
      expect(names, contains('Kehadiran'));
      expect(names, contains('Mutasi Unit'));
      expect(names, contains('Mutasi Jabatan'));
      expect(names, contains('Mutasi Golongan'));
      expect(names, contains('Talenta'));
      expect(names, contains('Disiplin'));
      expect(names, contains('Ukom'));
      expect(names, contains('KGB'));
      expect(names, contains('Lainnya'));
    });

    test('ServiceCategoryModel serialization & deserialization', () {
      final json = {
        'id': 1,
        'nama': 'Kehadiran',
        'kode': 'KEHADIRAN',
        'deskripsi': 'Presensi & cuti',
        'is_active': true,
        'sort_order': 1,
      };

      final model = ServiceCategoryModel.fromJson(json);
      expect(model.id, equals(1));
      expect(model.nama, equals('Kehadiran'));
      expect(model.kode, equals('KEHADIRAN'));
      expect(model.deskripsi, equals('Presensi & cuti'));
      expect(model.isActive, isTrue);
      expect(model.sortOrder, equals(1));

      final map = model.toJson();
      expect(map['id'], equals(1));
      expect(map['nama'], equals('Kehadiran'));
      expect(map['kode'], equals('KEHADIRAN'));
      expect(map['deskripsi'], equals('Presensi & cuti'));
      expect(map['is_active'], isTrue);
    });
  });

  group('QuestionModel displayCategory & Filter Tests', () {
    test('QuestionModel displayCategory prioritizes kategoriLayanan', () {
      const q = QuestionModel(
        id: 101,
        judul: 'Pertanyaan Uji Kompetensi',
        isi: 'Bagaimana alur pendaftaran ukom?',
        status: 'menunggu_lksdm',
        serviceCategoryId: 7,
        kategoriLayanan: 'Ukom',
        tugasFungsiNama: 'Layanan Umum Kepegawaian',
      );

      expect(q.displayCategory, equals('Ukom'));
      expect(q.serviceCategoryId, equals(7));
      expect(q.kategoriLayanan, equals('Ukom'));
    });

    test('QuestionModel displayCategory falls back to tugasFungsiNama if kategoriLayanan null', () {
      const q = QuestionModel(
        id: 102,
        judul: 'Pertanyaan Lama',
        isi: 'Pertanyaan sebelum migrasi',
        status: 'menunggu_lksdm',
        tugasFungsiNama: 'ORTALA-01 - Evaluasi Organisasi',
      );

      expect(q.displayCategory, equals('ORTALA-01 - Evaluasi Organisasi'));
    });

    test('QuestionModel displayCategory falls back to Layanan Umum if both null', () {
      const q = QuestionModel(
        id: 103,
        judul: 'Pertanyaan Polos',
        isi: 'Tanpa kategori',
        status: 'menunggu_lksdm',
      );

      expect(q.displayCategory, equals('Layanan Umum'));
    });

    test('Filtering questions by category works correctly', () {
      final list = [
        const QuestionModel(
          id: 1,
          judul: 'Absensi error',
          isi: 'Gagal check-in presensi',
          status: 'menunggu_lksdm',
          kategoriLayanan: 'Kehadiran',
        ),
        const QuestionModel(
          id: 2,
          judul: 'Mutasi ke Bandung',
          isi: 'Permohonan mutasi unit kerja',
          status: 'menunggu_lksdm',
          kategoriLayanan: 'Mutasi Unit',
        ),
        const QuestionModel(
          id: 3,
          judul: 'Jadwal Ukom Peneliti',
          isi: 'Kapan jadwal uji kompetensi?',
          status: 'ditangani_lksdm',
          kategoriLayanan: 'Ukom',
        ),
      ];

      final filteredKehadiran = list
          .where((q) => q.displayCategory.toLowerCase().contains('kehadiran'))
          .toList();
      expect(filteredKehadiran.length, equals(1));
      expect(filteredKehadiran.first.id, equals(1));

      final filteredMutasi = list
          .where((q) => q.displayCategory.toLowerCase().contains('mutasi unit'))
          .toList();
      expect(filteredMutasi.length, equals(1));
      expect(filteredMutasi.first.id, equals(2));
    });
  });

  group('QuestionCard UI Category Badge Tests', () {
    testWidgets('QuestionCard displays category badge correctly', (tester) async {
      const q = QuestionModel(
        id: 105,
        ticketNumber: 'TKT-202610-001',
        judul: 'Keterlambatan Presensi Fingerprint',
        isi: 'Mesin fingerprint error sehingga terlambat presensi',
        status: 'menunggu_lksdm',
        kategoriLayanan: 'Kehadiran',
        lksdmKawasan: 'LKSDM 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCard(
              question: q,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Category Badge is displayed
      expect(find.text('Kehadiran'), findsOneWidget);
      expect(find.byIcon(Icons.label_outline), findsOneWidget);
      expect(find.text('Keterlambatan Presensi Fingerprint'), findsOneWidget);
    });
  });
}
