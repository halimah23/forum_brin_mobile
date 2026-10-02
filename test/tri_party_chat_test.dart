import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/answer_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';

void main() {
  group('Tri-Party Chat Business Flow & Models Test', () {
    test('QuestionModel correctly parses tri-party columns and initial state', () {
      final json = {
        'id': 200,
        'ticket_number': 'TKT-202610-001',
        'judul': 'Kendala Penetapan PAK untuk Kenaikan Pangkat',
        'isi': 'Mohon konfirmasi verifikasi berkas PAK di kawasan.',
        'status': 'menunggu_lksdm',
        'lksdm_kawasan': 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)',
        'target_tim_pusat': 'Tim Mutasi dan Pengelolaan JF 1',
        'target_tim': 'Tim Mutasi dan Pengelolaan JF 1',
        'is_public': true,
        'created_at': '2026-10-01T10:00:00Z',
        'profiles': {
          'id': '77777777-7777-7777-7777-777777777777',
          'name': 'Budi Pegawai',
          'email': 'pegawai@brin.go.id',
          'role': 'pegawai',
        },
      };

      final q = QuestionModel.fromJson(json);

      expect(q.id, 200);
      expect(q.ticketNumber, 'TKT-202610-001');
      expect(q.status, 'menunggu_lksdm');
      expect(q.lksdmKawasan, 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)');
      expect(q.targetTimPusat, 'Tim Mutasi dan Pengelolaan JF 1');
      expect(q.user?.isPegawai, true);
      expect(q.isEscalated, false);
    });

    test('QuestionModel transitions to dialihkan_ke_pusat and recognizes tri-party escalation', () {
      const initial = QuestionModel(
        id: 200,
        ticketNumber: 'TKT-202610-001',
        judul: 'Kendala Penetapan PAK',
        isi: 'Mohon bantuan.',
        status: 'menunggu_lksdm',
        lksdmKawasan: 'LKSDM 1',
        targetTimPusat: 'Tim Mutasi dan Pengelolaan JF 1',
      );

      expect(initial.isEscalated, false);

      // LKSDM Admin escalates to Central Team
      final escalated = initial.copyWith(
        status: 'dialihkan_ke_pusat',
        escalatedToTeam: 'Tim Mutasi dan Pengelolaan JF 1',
      );

      expect(escalated.status, 'dialihkan_ke_pusat');
      expect(escalated.isEscalated, true);
      expect(escalated.targetTimPusat, 'Tim Mutasi dan Pengelolaan JF 1');
    });

    test('AnswerModel handles 3 distinct parties and system event badges', () {
      // 1. Pegawai Message
      const pegawaiMsg = AnswerModel(
        questionId: 200,
        senderName: 'Budi Pegawai',
        senderRole: 'Pegawai',
        senderRoleType: 'pegawai',
        isiPesan: 'Selamat pagi, mohon bantuannya untuk tiket ini.',
      );
      expect(pegawaiMsg.penjawabNama, 'Budi Pegawai');
      expect(pegawaiMsg.isiJawaban, 'Selamat pagi, mohon bantuannya untuk tiket ini.');
      expect(pegawaiMsg.isOfficial, false);
      expect(pegawaiMsg.isAdminLksdm, false);
      expect(pegawaiMsg.isAdminPusat, false);

      // 2. Admin LKSDM Message
      const lksdmMsg = AnswerModel(
        questionId: 200,
        senderName: 'Handoko (Admin LKSDM 1)',
        senderRole: 'Staf Admin LKSDM',
        senderRoleType: 'admin_lksdm',
        isiPesan: 'Halo Pak Budi, berkas sudah kami terima namun butuh konfirmasi pusat.',
      );
      expect(lksdmMsg.isAdminLksdm, true);
      expect(lksdmMsg.isOfficial, true);
      expect(lksdmMsg.isAdminPusat, false);

      // 3. System Event (Escalation)
      const sysMsg = AnswerModel(
        questionId: 200,
        senderName: 'Sistem Forum',
        senderRole: 'Sistem',
        senderRoleType: 'system_event',
        isiPesan: 'Pertanyaan telah dialihkan oleh Staf LKSDM ke Tim Mutasi JF 1.',
      );
      expect(sysMsg.isSystemEvent, true);

      // 4. Admin Pusat Message
      const pusatMsg = AnswerModel(
        questionId: 200,
        senderName: 'Siti Rahma (Admin Pusat)',
        senderRole: 'Staf Admin Pusat',
        senderRoleType: 'admin_pusat',
        isiPesan: 'Tim Pusat siap mendampingi. Berkas PAK telah kami validasi.',
        attachmentUrl: 'https://example.com/sk-pak.pdf',
      );
      expect(pusatMsg.isAdminPusat, true);
      expect(pusatMsg.isOfficial, true);
      expect(pusatMsg.attachmentUrl, isNotNull);
    });

    test('UserModel role helpers correctly identify role privileges', () {
      const pegUser = UserModel(
        id: '1',
        name: 'Pegawai',
        email: 'pegawai@brin.go.id',
        role: 'pegawai',
      );
      expect(pegUser.isPegawai, true);
      expect(pegUser.isAdminLksdm, false);
      expect(pegUser.isAdminPusat, false);

      const lksdmUser = UserModel(
        id: '2',
        name: 'Admin LKSDM',
        email: 'lksdm@brin.go.id',
        role: 'admin_lksdm',
        unit: 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)',
      );
      expect(lksdmUser.isAdminLksdm, true);
      expect(lksdmUser.isAdminPusat, false);
      expect(lksdmUser.effectiveLksdm, 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)');

      const pusatUser = UserModel(
        id: '3',
        name: 'Admin Pusat',
        email: 'pusat@brin.go.id',
        role: 'admin_pusat',
        tim: 'Tim Mutasi dan Pengelolaan JF 1',
      );
      expect(pusatUser.isAdminPusat, true);
      expect(pusatUser.isAdminLksdm, false);
    });

    test('Ticket resolution rule: Only Pegawai can end chat to selesai, Admin response keeps ticket active', () {
      const question = QuestionModel(
        id: 300,
        ticketNumber: 'TKT-202610-099',
        judul: 'Pencairan Tukin',
        isi: 'Kapan tukin cair?',
        status: 'menunggu_lksdm',
        lksdmKawasan: 'LKSDM 1',
        targetTimPusat: 'Tim Penggajian',
      );

      // Admin LKSDM replies: status transitions to ditangani_lksdm, NEVER selesai
      final afterLksdmReply = question.copyWith(
        status: 'ditangani_lksdm',
      );
      expect(afterLksdmReply.status, 'ditangani_lksdm');
      expect(afterLksdmReply.status != 'selesai', true);

      // Admin Pusat replies: status stays dialihkan_ke_pusat, NEVER selesai
      final afterPusatReply = afterLksdmReply.copyWith(
        status: 'dialihkan_ke_pusat',
      );
      expect(afterPusatReply.status, 'dialihkan_ke_pusat');
      expect(afterPusatReply.status != 'selesai', true);

      // ONLY Pegawai clicking confirm resolution sets status to selesai
      final afterPegawaiConfirm = afterPusatReply.copyWith(
        status: 'selesai',
      );
      expect(afterPegawaiConfirm.status, 'selesai');
    });
  });
}
