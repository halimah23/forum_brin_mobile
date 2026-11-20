import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/core/utils/operational_hours_helper.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/answer_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';

void main() {
  group('OperationalHoursHelper Tests', () {
    test('isWithinWorkingHours returns true for Wednesday 10:00 WIB', () {
      // Rabu 2026-11-04 10:00:00 WIB = 03:00:00 UTC
      final wednesday10AmWib = DateTime.utc(2026, 11, 4, 3, 0);
      expect(OperationalHoursHelper.isWithinWorkingHours(wednesday10AmWib), isTrue);
    });

    test('isWithinWorkingHours returns false for Wednesday 17:00 WIB (after office hours)', () {
      // Rabu 2026-11-04 17:00:00 WIB = 10:00:00 UTC
      final wednesday5PmWib = DateTime.utc(2026, 11, 4, 10, 0);
      expect(OperationalHoursHelper.isWithinWorkingHours(wednesday5PmWib), isFalse);
    });

    test('isWithinWorkingHours returns false for Saturday (weekend)', () {
      // Sabtu 2026-11-07 10:00:00 WIB = 03:00:00 UTC
      final saturdayWib = DateTime.utc(2026, 11, 7, 3, 0);
      expect(OperationalHoursHelper.isWithinWorkingHours(saturdayWib), isFalse);
    });

    test('getNextSlaStartTime shifts off-hours Friday evening to Monday 08:00 WIB', () {
      // Jumat 2026-11-06 19:00:00 WIB = 12:00:00 UTC
      final fridayEvening = DateTime.utc(2026, 11, 6, 12, 0);
      final nextSla = OperationalHoursHelper.getNextSlaStartTime(fridayEvening);

      // Harusnya Senin 2026-11-09 pukul 08:00 WIB
      expect(nextSla.weekday, equals(DateTime.monday));
      expect(nextSla.hour, equals(8));
      expect(nextSla.minute, equals(0));
    });

    test('getNextSlaStartTime on early morning weekday (06:00 WIB) starts at 08:00 WIB same day', () {
      // Selasa 2026-11-03 06:00:00 WIB = 2026-11-02 23:00:00 UTC
      final tuesdayMorning = DateTime.utc(2026, 11, 2, 23, 0);
      final nextSla = OperationalHoursHelper.getNextSlaStartTime(tuesdayMorning);

      expect(nextSla.weekday, equals(DateTime.tuesday));
      expect(nextSla.hour, equals(8));
    });
  });

  group('QuestionModel canEdit & canCancel Tests', () {
    final userAuthor = UserModel(id: 'usr_001', name: 'Budi Pegawai', email: 'budi@brin.go.id', role: 'pegawai');
    final otherUser = UserModel(id: 'usr_999', name: 'Siti Pegawai', email: 'siti@brin.go.id', role: 'pegawai');

    test('Author can edit question within 15 minutes', () {
      final now = DateTime.now();
      final freshQuestion = QuestionModel(
        id: 101,
        judul: 'Pertanyaan Segar',
        isi: 'Isi pertanyaan',
        userId: 'usr_001',
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
        status: 'open',
      );

      expect(freshQuestion.canEdit(userAuthor), isTrue);
      expect(freshQuestion.canEdit(otherUser), isFalse);
    });

    test('Author cannot edit question after 15 minutes', () {
      final now = DateTime.now();
      final oldQuestion = QuestionModel(
        id: 102,
        judul: 'Pertanyaan Lama',
        isi: 'Isi lama',
        userId: 'usr_001',
        createdAt: now.subtract(const Duration(minutes: 20)).toIso8601String(),
        status: 'open',
      );

      expect(oldQuestion.canEdit(userAuthor), isFalse);
    });

    test('Author can cancel question if no staff has responded', () {
      final question = QuestionModel(
        id: 103,
        judul: 'Tiket Baru',
        isi: 'Uraian',
        userId: 'usr_001',
        createdAt: DateTime.now().toIso8601String(),
        status: 'open',
        answers: [],
      );

      expect(question.canCancel(userAuthor), isTrue);
      expect(question.canCancel(otherUser), isFalse);
    });

    test('Author cannot cancel question if staff already answered', () {
      final question = QuestionModel(
        id: 104,
        judul: 'Tiket Ditangani',
        isi: 'Uraian',
        userId: 'usr_001',
        createdAt: DateTime.now().toIso8601String(),
        status: 'in_progress',
        answers: [
          AnswerModel(
            id: 201,
            questionId: 104,
            penjawabNama: 'Staf Admin',
            penjawabRole: 'admin_lksdm',
            senderRole: 'admin_lksdm',
            isiJawaban: 'Baik sedang kami proses',
          ),
        ],
      );

      expect(question.canCancel(userAuthor), isFalse);
    });
  });

  group('AnswerModel canEdit & canDelete (soft delete) Tests', () {
    test('Sender can edit answer within 15 minutes', () {
      final now = DateTime.now();
      final answer = AnswerModel(
        id: 301,
        questionId: 101,
        userId: 'usr_001',
        penjawabNama: 'Budi',
        isiJawaban: 'Tanggapan pertama',
        createdAt: now.subtract(const Duration(minutes: 10)).toIso8601String(),
      );

      expect(answer.canEdit('usr_001'), isTrue);
      expect(answer.canEdit('usr_999'), isFalse);
    });

    test('Sender cannot edit answer after 15 minutes', () {
      final now = DateTime.now();
      final answer = AnswerModel(
        id: 302,
        questionId: 101,
        userId: 'usr_001',
        penjawabNama: 'Budi',
        isiJawaban: 'Tanggapan lama',
        createdAt: now.subtract(const Duration(minutes: 16)).toIso8601String(),
      );

      expect(answer.canEdit('usr_001'), isFalse);
    });

    test('Sender can delete/retract answer within 15 minutes if not already deleted', () {
      final now = DateTime.now();
      final answer = AnswerModel(
        id: 303,
        questionId: 101,
        userId: 'usr_001',
        penjawabNama: 'Budi',
        isiJawaban: 'Pesan akan ditarik',
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      );

      expect(answer.canDelete('usr_001'), isTrue);

      final retractedAnswer = answer.copyWith(isDeleted: true);
      expect(retractedAnswer.canDelete('usr_001'), isFalse);
      expect(retractedAnswer.canEdit('usr_001'), isFalse);
    });
  });

  group('JSON Serialization Tests for Operational Rules & Soft Delete', () {
    tearDown(() {
      OperationalHoursHelper.mockNow = null;
    });

    test('QuestionModel handles is_off_hours, sla_start_at, is_deleted, and is_edited', () {
      // Mock waktu Minggu malam di luar jam kerja (sebelum jam 08:00 WIB)
      OperationalHoursHelper.mockNow = DateTime.utc(2026, 11, 2, 13, 0); // 20:00 WIB

      final json = {
        'id': 500,
        'judul': 'Konsultasi Malam',
        'isi': 'Pertanyaan dibuat di luar jam kerja',
        'status': 'antrean_luar_jam_kerja',
        'is_off_hours': true,
        'sla_start_at': '2026-11-03T08:00:00.000',
        'is_deleted': false,
        'is_edited': true,
        'edited_at': '2026-11-02T21:10:00.000',
      };

      final q = QuestionModel.fromJson(json);
      expect(q.isOffHours, isTrue);
      expect(q.slaStartAt, equals('2026-11-03T08:00:00.000'));
      expect(q.isDeleted, isFalse);
      expect(q.isEdited, isTrue);
      expect(q.ticketStatus, equals(TicketStatus.offHoursQueue));
      expect(q.isOffHoursQueue, isTrue);
    });

    test('AnswerModel handles is_deleted and is_edited', () {
      final json = {
        'id': 600,
        'question_id': 500,
        'penjawab_nama': 'Budi',
        'isi_jawaban': 'Pesan ini diedit',
        'is_deleted': true,
        'deleted_at': '2026-11-02T21:20:00.000',
        'is_edited': true,
        'edited_at': '2026-11-02T21:15:00.000',
      };

      final ans = AnswerModel.fromJson(json);
      expect(ans.isDeleted, isTrue);
      expect(ans.deletedAt, equals('2026-11-02T21:20:00.000'));
      expect(ans.isEdited, isTrue);
      expect(ans.editedAt, equals('2026-11-02T21:15:00.000'));
    });
  });

  group('Off-Hours Dynamic Status Transition & Dashboard Role Tests', () {
    tearDown(() {
      OperationalHoursHelper.mockNow = null;
    });

    test('Ticket created off-hours remains offHoursQueue outside working hours', () {
      // Minggu 2026-11-08 20:00 WIB (13:00 UTC) -> Di luar jam kerja
      OperationalHoursHelper.mockNow = DateTime.utc(2026, 11, 8, 13, 0);

      final q = QuestionModel(
        id: 701,
        judul: 'Tiket Libur Akhir Pekan',
        isi: 'Konsultasi dibuat hari Minggu',
        status: 'antrean_luar_jam_kerja',
        isOffHours: true,
        slaStartAt: '2026-11-09T08:00:00.000',
      );

      expect(OperationalHoursHelper.isWithinWorkingHours(), isFalse);
      expect(q.ticketStatus, equals(TicketStatus.offHoursQueue));
      expect(q.isOffHoursQueue, isTrue);
    });

    test('Ticket created off-hours dynamically transitions to OPEN during operational hours', () {
      // Senin 2026-11-09 09:30 WIB (02:30 UTC) -> Jam dinas aktif
      OperationalHoursHelper.mockNow = DateTime.utc(2026, 11, 9, 2, 30);

      final q = QuestionModel(
        id: 702,
        judul: 'Tiket Yang Masuk Jam Dinas',
        isi: 'Sudah hari kerja jam 09:30 WIB',
        status: 'antrean_luar_jam_kerja',
        isOffHours: true,
        slaStartAt: '2026-11-09T08:00:00.000',
      );

      expect(OperationalHoursHelper.isWithinWorkingHours(), isTrue);
      // Status tiket otomatis bertransisi menjadi open
      expect(q.ticketStatus, equals(TicketStatus.open));
      // Banner luar jam kerja tidak lagi aktif
      expect(q.isOffHoursQueue, isFalse);
    });

    test('Mandiri LKSDM ticket created off-hours dynamically transitions to mandiriLksdm during operational hours', () {
      // Senin 2026-11-09 10:00 WIB (03:00 UTC) -> Jam dinas aktif
      OperationalHoursHelper.mockNow = DateTime.utc(2026, 11, 9, 3, 0);

      final q = QuestionModel(
        id: 703,
        judul: 'Konsultasi Mandiri LKSDM ke Pusat',
        isi: 'Eskalasi internal LKSDM',
        status: 'antrean_luar_jam_kerja',
        targetTimPusat: 'Tim Kerja Pengadaan dan Mutasi SDM',
        isOffHours: true,
        slaStartAt: '2026-11-09T08:00:00.000',
      );

      expect(OperationalHoursHelper.isWithinWorkingHours(), isTrue);
      expect(q.ticketStatus, equals(TicketStatus.mandiriLksdm));
      expect(q.isOffHoursQueue, isFalse);
    });

    test('Dashboard filters across all roles categorize off-hours tickets into waiting/open correctly', () {
      // Di luar jam kerja
      OperationalHoursHelper.mockNow = DateTime.utc(2026, 11, 8, 13, 0);

      final offHoursTicket = QuestionModel(
        id: 704,
        judul: 'Tiket Antrean Malam',
        isi: 'Masuk antrean',
        status: 'antrean_luar_jam_kerja',
        isOffHours: true,
      );

      final activeList = [offHoursTicket];

      // Simulasi filter Member / Admin / Ketua Tim
      final openOrWaitingTickets = activeList.where(
        (q) => q.ticketStatus == TicketStatus.open || q.ticketStatus == TicketStatus.offHoursQueue,
      ).toList();

      final inProgressTickets = activeList.where(
        (q) => q.isActive && q.ticketStatus != TicketStatus.open && q.ticketStatus != TicketStatus.offHoursQueue,
      ).toList();

      expect(openOrWaitingTickets.length, equals(1));
      expect(inProgressTickets.isEmpty, isTrue);
    });
  });
}
