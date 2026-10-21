import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/auth/models/user_role.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/models/ticket_status.dart';

void main() {
  group('Comprehensive SOP Instansi Business Flow Tests', () {
    test('1. Pegawai Profile Auto-Detects LKSDM without manual selector', () {
      // User in Kawasan 6
      const pegawaiKawasan6 = UserModel(
        id: 'usr_151',
        name: 'Hafiz Rifki',
        email: 'hafiz.rifki@brin.go.id',
        role: 'Member',
        unit: 'DPRI',
        kawasan: 'LKSDM 6',
      );

      expect(pegawaiKawasan6.isPegawai, true);
      expect(pegawaiKawasan6.effectiveLksdm, 'LKSDM 6');
      expect(pegawaiKawasan6.satuanKerja, 'DPRI');
    });

    test('2. Staff Admin and Ketua Tim LKSDM 6 correctly match team assignment', () {
      // Staff Admin assigned to tim_020 (LKSDM 6)
      const adminLksdm6 = UserModel(
        id: 'usr_018',
        name: 'Maria Fernanda De Vega',
        email: 'maria.fernanda.de.vega@brin.go.id',
        role: 'Staff Admin',
        unit: 'BOSDM',
        idTim: 'tim_020',
        tim: 'LKSDM 6',
        kawasan: 'LKSDM 1', // Even if residence/base is LKSDM 1, their tim is LKSDM 6
        eskalasi: 'LKSDM',
      );

      expect(adminLksdm6.isAdminLksdm, true);
      expect(adminLksdm6.effectiveLksdm, 'LKSDM 6');

      // Ketua Tim LKSDM 6
      const ketuaTimLksdm6 = UserModel(
        id: 'usr_077',
        name: 'Redho Hasyrahim Fatah',
        email: 'redho.hasyrahim.fatah@brin.go.id',
        role: 'Ketua Tim',
        unit: 'BOSDM',
        idTim: 'tim_020',
        tim: 'LKSDM 6',
        eskalasi: 'LKSDM',
      );

      expect(ketuaTimLksdm6.isKetuaTimLksdm, true);
      expect(ketuaTimLksdm6.effectiveLksdm, 'LKSDM 6');
    });

    test('3. Staff Admin Pusat (ORTALA) correctly identified and filtered', () {
      const adminOrtala = UserModel(
        id: 'usr_005',
        name: 'Wa Ode Fithrah',
        email: 'wa.ode.fithrah@brin.go.id',
        role: 'Staff Admin',
        unit: 'BOSDM',
        idTim: 'tim_001',
        tim: 'ORTALA',
        eskalasi: 'PUSAT',
      );

      expect(adminOrtala.isAdminPusat, true);
      expect(adminOrtala.isAdminLksdm, false);
      expect(adminOrtala.tim, 'ORTALA');
    });

    test('4. Full Question Lifecycle: Created -> Answered -> Escalated -> Completed with CSAT', () {
      // A. Created by Pegawai Kawasan 6
      final initialQuestionJson = {
        'id': 101,
        'ticket_number': 'TKT-202610-101',
        'user_id': 'usr_151',
        'judul': 'Konsultasi Perizinan PDLN Riset',
        'isi': 'Bagaimana alur persetujuan PDLN untuk konferensi internasional?',
        'status': 'menunggu_lksdm',
        'lksdm_kawasan': 'LKSDM 6',
        'target_tim_pusat': null,
        'users': {
          'id_user': 'usr_151',
          'first_name': 'Hafiz Rifki',
          'email': 'hafiz.rifki@brin.go.id',
          'role': 'Member',
          'satuan_kerja': 'DPRI',
          'kawasan': 'LKSDM 6',
        },
      };

      var question = QuestionModel.fromJson(initialQuestionJson);
      expect(question.ticketStatus, TicketStatus.open);
      expect(question.lksdmKawasan, 'LKSDM 6');
      expect(question.targetTimPusat, isNull);
      expect(question.isActive, true);
      expect(question.isClosed, false);
      expect(question.userId, 'usr_151');

      // B. Staff Admin LKSDM 6 answers
      final answeredQuestion = question.copyWith(
        status: 'ditangani_lksdm',
      );
      expect(answeredQuestion.ticketStatus, TicketStatus.inProgress);
      expect(answeredQuestion.isActive, true);

      // C. Escalated to Tim Pusat (ORTALA)
      final escalatedQuestion = answeredQuestion.copyWith(
        status: 'dialihkan_ke_pusat',
        escalatedToTeam: 'ORTALA',
      );
      expect(escalatedQuestion.ticketStatus, TicketStatus.escalated);
      expect(escalatedQuestion.isEscalated, true);
      expect(escalatedQuestion.escalatedToTeam, 'ORTALA');

      // D. Pegawai confirms resolution and marks completed
      final resolvedQuestion = escalatedQuestion.copyWith(
        status: 'selesai',
        rating: 5,
        ratingFeedback: 'Layanan sangat cepat dan informatif. Terima kasih tim!',
        ratingSubmittedAt: DateTime.now().toIso8601String(),
      );
      expect(resolvedQuestion.ticketStatus, TicketStatus.closed);
      expect(resolvedQuestion.isClosed, true);
      expect(resolvedQuestion.rating, 5);
      expect(resolvedQuestion.ratingFeedback, contains('Layanan sangat cepat'));
    });

    test('5. Eksekutif & Super Admin privilege verification', () {
      const eksekutifUser = UserModel(
        id: 'usr_239',
        name: 'Eksekutif BOSDM',
        email: 'eksekutif@brin.go.id',
        role: 'eksekutif',
      );
      expect(eksekutifUser.isEksekutif, true);

      const superAdminUser = UserModel(
        id: 'usr_240',
        name: 'Super Admin BRIN',
        email: 'superadmin@brin.go.id',
        role: 'super_admin',
      );
      expect(superAdminUser.isSuperAdmin, true);
    });
  });
}
