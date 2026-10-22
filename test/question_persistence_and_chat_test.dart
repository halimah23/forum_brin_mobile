import 'package:forum_brin_mobile/core/services/storage/session_manager.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_brin_mobile/features/questions/services/question_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = _RealHttpOverrides();

    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    await Supabase.initialize(url: url, publishableKey: key);
    await SessionManager.saveUser(
      const UserModel(
        id: 'usr_240',
        name: 'Annisah Tanziela Aziezir',
        email: 'annisah.tanziela.aziezir@brin.go.id',
        role: 'pegawai',
      ),
    );
  });

  test('E2E: Pegawai creates question -> persists to DB -> loads via getQuestions -> all roles send chat answers', () async {
    final client = Supabase.instance.client;

    // 1. Pegawai creates a question
    final testJudul = 'Test Persistensi Pegawai ${DateTime.now().millisecondsSinceEpoch}';
    final testIsi = 'Pertanyaan uji otomatis untuk membuktikan penyimpanan ke database Supabase.';

    final createdQuestion = await QuestionService.createQuestion(
      token: 'test-token',
      judul: testJudul,
      isi: testIsi,
      tugasFungsiIds: const [],
      selectedTeam: 'LKSDM 1 (Kawasan Jakarta)',
      lksdmKawasan: 'LKSDM 1 (Kawasan Jakarta)',
      isPublic: false,
    );

    expect(createdQuestion.id, isNotNull);
    final questionId = createdQuestion.id!;
    print('Created question successfully with real DB ID: $questionId');
    expect(questionId, greaterThan(0));

    // Verify directly in Supabase questions table
    final directCheck = await client.from('questions').select().eq('id', questionId).single();
    expect(directCheck['judul'], testJudul);
    expect(directCheck['status'], 'menunggu_lksdm');

    // 2. Load questions via QuestionService.getQuestions()
    final allQuestions = await QuestionService.getQuestions();
    expect(allQuestions, isNotEmpty);
    // Ensure it's not the static fallback mock (ID 101, 102, 103 only)
    final found = allQuestions.any((q) => q.id == questionId);
    expect(found, isTrue, reason: 'getQuestions() must include newly inserted question from Supabase');

    // 3. Load question detail via QuestionService.getQuestionDetail()
    final detail = await QuestionService.getQuestionDetail(questionId);
    expect(detail, isNotNull);
    expect(detail!.judul, testJudul);

    // 4. Role Pegawai sends chat message
    final pegawaiMsgSuccess = await QuestionService.sendFollowUpMessage(
      questionId: questionId,
      isiPesan: 'Pesan klarifikasi dari Pegawai.',
      pengirimNama: 'Budi Santoso',
      pengirimRole: 'pegawai',
      senderRoleType: 'pegawai',
    );
    expect(pegawaiMsgSuccess, isTrue);

    // 5. Role Admin LKSDM sends chat message
    final lksdmMsgSuccess = await QuestionService.sendFollowUpMessage(
      questionId: questionId,
      isiPesan: 'Tanggapan dari Staf LKSDM Kawasan Thamrin.',
      pengirimNama: 'Budi Handoko',
      pengirimRole: 'admin',
      senderRoleType: 'admin_lksdm',
    );
    expect(lksdmMsgSuccess, isTrue);

    // 6. Role Admin Pusat sends chat message
    final pusatMsgSuccess = await QuestionService.sendFollowUpMessage(
      questionId: questionId,
      isiPesan: 'Validasi dan respon dari Staf Admin Pusat.',
      pengirimNama: 'Rina Melati',
      pengirimRole: 'admin',
      senderRoleType: 'admin_pusat',
    );
    expect(pusatMsgSuccess, isTrue);

    // 7. Verify all answers are persisted and fetched via QuestionDetail
    final updatedDetail = await QuestionService.getQuestionDetail(questionId);
    expect(updatedDetail, isNotNull);
    expect(updatedDetail!.answers, isNotNull);
    expect(updatedDetail.answers!.length, greaterThanOrEqualTo(3));
    print('Total answers retrieved from Supabase for question $questionId: ${updatedDetail.answers!.length}');

    // Clean up test question and answers from Supabase
    try {
      await client.from('answers').delete().eq('question_id', questionId);
      await client.from('questions').delete().eq('id', questionId);
      print('Cleaned up test data for question $questionId');
    } catch (_) {}
  }, timeout: const Timeout(Duration(minutes: 2)));
}
