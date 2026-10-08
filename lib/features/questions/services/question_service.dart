import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/session_manager.dart';
import '../data/tusi_catalog_data.dart';
import '../models/answer_model.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../../auth/models/user_model.dart';


class QuestionService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Helper untuk menentukan Nama Tim berdasarkan Kode atau Nama Tugas & Fungsi
  static String determineTeamName(String? categoryName) {
    return TusiCatalogData.resolveTeam(categoryName);
  }

  /// Ambil daftar seluruh 15 Tim BOSDM
  static Future<List<String>> getTeams() async {
    try {
      final response = await _client.from('teams').select('nama').order('id');
      final list = response
          .map((item) => item['nama']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Gunakan fallback lokal jika tabel teams belum diisi
    }
    return TusiCatalogData.allTeams;
  }

  /// Ambil daftar Tugas & Fungsi (bisa difilter per Tim)
  static Future<List<CategoryModel>> getTugasFungsi({
    String? teamName,
    String? token,
  }) async {
    try {
      var query = _client.from('tugas_fungsi').select();
      if (teamName != null && teamName.isNotEmpty) {
        query = query.ilike('team_nama', '%$teamName%');
      }
      final response = await query.order('id');
      final list = response
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback lokal
    }

    if (teamName != null && teamName.isNotEmpty) {
      return TusiCatalogData.getTugasFungsiByTeam(teamName);
    }
    return TusiCatalogData.allTugasFungsi;
  }

  /// Ambil seluruh pertanyaan / tiket dengan filter opsional (Tim, Status, Sifat Publik/Privat, dsb)
  static Future<List<QuestionModel>> getQuestions({
    String? teamFilter,
    String? statusFilter,
    String? userIdFilter,
    bool? isPublicOnly,
    bool? isPrivateOnly,
    String? token,
  }) async {
    try {
      // 1. Ambil pertanyaan beserta profil pembuat dan tugas fungsi
      var query = _client.from('questions').select('''
        id,
        ticket_number,
        judul,
        isi,
        status,
        target_tim,
        assigned_to,
        tugas_fungsi_nama,
        lksdm_kawasan,
        target_tim_pusat,
        admin_lksdm_id,
        admin_pusat_id,
        is_public,
        created_at,
        profiles:user_id (id, name, email, role, unit, tim, jabatan),
        question_tugas_fungsi (
          tugas_fungsi (id, kode, nama, team_nama)
        )
      ''');

      if (isPublicOnly == true) {
        query = query.eq('is_public', true);
      } else if (isPrivateOnly == true) {
        query = query.eq('is_public', false);
      }

      if (userIdFilter != null && userIdFilter.isNotEmpty) {
        query = query.eq('user_id', userIdFilter);
      }

      if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
        query = query.or('target_tim.ilike.%$teamFilter%,lksdm_kawasan.ilike.%$teamFilter%,target_tim_pusat.ilike.%$teamFilter%');
      }

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter.toLowerCase() != 'semua') {
        final normalizedStatus = statusFilter.toLowerCase();
        if (normalizedStatus == 'menunggu_lksdm' || normalizedStatus == 'open') {
          query = query.inFilter('status', ['menunggu_lksdm', 'menunggu_disposisi', 'OPEN', 'open']);
        } else if (normalizedStatus == 'ditangani_lksdm' || normalizedStatus == 'in_progress' || normalizedStatus == 'waiting_user') {
          query = query.inFilter('status', ['ditangani_lksdm', 'sedang_diproses', 'IN_PROGRESS', 'WAITING_USER', 'in_progress', 'waiting_user']);
        } else if (normalizedStatus == 'dialihkan_ke_pusat' || normalizedStatus == 'eskalasi_pusat' || normalizedStatus == 'escalated' || normalizedStatus == 'in_progress_center') {
          query = query.inFilter('status', ['dialihkan_ke_pusat', 'eskalasi_pusat', 'ESCALATED', 'IN_PROGRESS_CENTER', 'escalated', 'in_progress_center']);
        } else if (normalizedStatus == 'selesai' || normalizedStatus == 'closed' || normalizedStatus == 'resolved') {
          query = query.inFilter('status', ['selesai', 'CLOSED', 'RESOLVED', 'closed', 'resolved']);
        } else {
          query = query.eq('status', statusFilter);
        }
      }

      final response = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> questionList =
          List<Map<String, dynamic>>.from(response);

      // 2. Ambil jawaban dari tabel answers
      try {
        final answersResponse = await _client.from('answers').select('''
          id,
          question_id,
          user_id,
          sender_name,
          sender_role,
          isi_pesan,
          attachment_url,
          created_at
        ''').order('created_at', ascending: true);

        final Map<int, List<Map<String, dynamic>>> answersGrouped = {};
        for (var item in answersResponse) {
          final qId = item['question_id'] is int
              ? item['question_id'] as int
              : int.tryParse(item['question_id']?.toString() ?? '') ?? 0;
          answersGrouped.putIfAbsent(qId, () => []).add(Map<String, dynamic>.from(item));
        }

        for (var qMap in questionList) {
          final qId = qMap['id'] is int
              ? qMap['id'] as int
              : int.tryParse(qMap['id']?.toString() ?? '') ?? 0;
          if (answersGrouped.containsKey(qId)) {
            qMap['answers'] = answersGrouped[qId];
          }
        }
      } catch (_) {}

      return questionList
          .map((item) => QuestionModel.fromJson(item))
          .toList();
    } catch (e) {
      // Fallback data simulasi jika koneksi Supabase belum terkonfigurasi
      return _getFallbackQuestions(
        teamFilter: teamFilter,
        statusFilter: statusFilter,
        userIdFilter: userIdFilter,
        isPublicOnly: isPublicOnly,
      );
    }
  }

  /// Ambil pertanyaan milik Member yang sedang login
  static Future<List<QuestionModel>> getMyQuestions({
    String? statusFilter,
    String? token,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    return getQuestions(
      userIdFilter: currentUserId,
      statusFilter: statusFilter,
      token: token,
    );
  }

  static bool _isValidUuid(String id) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
  }

  /// Buat Tiket Pertanyaan Baru (Awal alur: Menunggu penanganan Staf Admin LKSDM Kawasan)
  static Future<QuestionModel> createQuestion({
    required String token,
    required String judul,
    required String isi,
    required List<int> tugasFungsiIds,
    String? selectedTeam,
    String? lksdmKawasan,
    String? targetTimPusat,
    bool isPublic = true,
  }) async {
    final currentUser = _client.auth.currentUser;
    String? userId = currentUser?.id;

    if (userId == null || !_isValidUuid(userId)) {
      final savedUser = await SessionManager.getUser();
      if (savedUser?.id != null && _isValidUuid(savedUser!.id!)) {
        userId = savedUser.id;
      }
    }
    // Fallback ID pegawai jika sesi auth lokal belum memiliki ID Supabase valid
    if (userId == null || !_isValidUuid(userId)) {
      userId = '77777777-7777-7777-7777-777777777777';
    }

    // Tentukan Tusi dan Tim Terkait
    String targetTeam = selectedTeam ?? 'Tim Layanan SDM BOSDM';
    String tusiNama = 'Layanan Umum Kepegawaian';

    if (tugasFungsiIds.isNotEmpty) {
      final selectedId = tugasFungsiIds.first;
      final foundTusi = TusiCatalogData.allTugasFungsi.where((t) => t.id == selectedId).firstOrNull;
      if (foundTusi != null) {
        tusiNama = foundTusi.fullDisplayName;
        if (selectedTeam == null || selectedTeam.isEmpty) {
          targetTeam = foundTusi.teamName ?? TusiCatalogData.resolveTeam(foundTusi.nama);
        }
      }
    }

    final ticketNumber = 'TKT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final effectiveLksdm = lksdmKawasan ?? (selectedTeam?.contains('LKSDM') == true ? selectedTeam : 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)');
    final effectiveTargetPusat = targetTimPusat ?? targetTeam;

    try {
      final insertedQuestion = await _client.from('questions').insert({
        'user_id': userId,
        'ticket_number': ticketNumber,
        'judul': judul,
        'isi': isi,
        'target_tim': targetTeam,
        'tugas_fungsi_nama': tusiNama,
        'lksdm_kawasan': effectiveLksdm,
        'target_tim_pusat': effectiveTargetPusat,
        'is_public': isPublic,
        'status': 'menunggu_lksdm', // Status awal tiket
      }).select('''
        id,
        ticket_number,
        judul,
        isi,
        status,
        target_tim,
        assigned_to,
        tugas_fungsi_nama,
        lksdm_kawasan,
        target_tim_pusat,
        admin_lksdm_id,
        admin_pusat_id,
        is_public,
        created_at,
        profiles:user_id (id, name, email, role, unit, tim, jabatan)
      ''').single();

      final questionId = insertedQuestion['id'] is int
          ? insertedQuestion['id'] as int
          : int.parse(insertedQuestion['id'].toString());

      if (tugasFungsiIds.isNotEmpty) {
        final relations = tugasFungsiIds
            .map((catId) => {
                  'question_id': questionId,
                  'tugas_fungsi_id': catId,
                })
            .toList();
        try {
          await _client.from('question_tugas_fungsi').insert(relations);
        } catch (_) {}
      }

      return QuestionModel.fromJson(Map<String, dynamic>.from(insertedQuestion));
    } catch (e) {
      debugPrint('Error inserting question to Supabase: $e');
      
      // Attempt to retrieve saved user to avoid null exception in UI
      final savedUser = await SessionManager.getUser();

      // Return simulasi jika offline
      return QuestionModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ticketNumber: ticketNumber,
        judul: judul,
        isi: isi,
        status: 'menunggu_lksdm',
        targetTim: targetTeam,
        tugasFungsiNama: tusiNama,
        lksdmKawasan: effectiveLksdm,
        targetTimPusat: effectiveTargetPusat,
        isPublic: isPublic,
        createdAt: DateTime.now().toIso8601String(),
        user: savedUser ?? const UserModel(
          id: '77777777-7777-7777-7777-777777777777',
          name: 'Pengguna Mode Offline',
          email: 'offline@brin.go.id',
          role: 'member',
        ),
      );
    }
  }

  static Future<void> _safeInsertAnswer(Map<String, dynamic> payload) async {
    try {
      await _client.from('answers').insert(payload);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('user_id') || errStr.contains('PGRST204')) {
        final copyPayload = Map<String, dynamic>.from(payload)..remove('user_id');
        await _client.from('answers').insert(copyPayload);
      } else {
        rethrow;
      }
    }
  }

  static Future<void> _safeUpdateQuestion(int questionId, Map<String, dynamic> payload) async {
    try {
      await _client.from('questions').update(payload).eq('id', questionId);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('updated_at') || errStr.contains('PGRST204')) {
        final copyPayload = Map<String, dynamic>.from(payload)..remove('updated_at');
        if (copyPayload.isNotEmpty) {
          await _client.from('questions').update(copyPayload).eq('id', questionId);
        }
      } else {
        rethrow;
      }
    }
  }

  /// Kirim Pesan Balasan / Percakapan Lanjutan oleh Pengguna (Pegawai/Admin LKSDM/Admin Pusat)
  static Future<bool> sendFollowUpMessage({
    required int questionId,
    required String isiPesan,
    required String pengirimNama,
    String pengirimRole = 'pegawai',
    String? senderRoleType,
    String? attachmentUrl,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (userId == null || !_isValidUuid(userId)) {
        final savedUser = await SessionManager.getUser();
        if (savedUser?.id != null && _isValidUuid(savedUser!.id!)) {
          userId = savedUser.id;
        }
      }
      if (userId == null || !_isValidUuid(userId)) {
        userId = '77777777-7777-7777-7777-777777777777';
      }

      final String validSenderRole;
      final roleToCheck = (senderRoleType ?? pengirimRole).toLowerCase();
      if (roleToCheck.contains('pusat')) {
        validSenderRole = 'admin_pusat';
      } else if (roleToCheck.contains('lksdm')) {
        validSenderRole = 'admin_lksdm';
      } else if (roleToCheck.contains('ketua')) {
        validSenderRole = 'ketua_tim';
      } else if (roleToCheck.contains('sistem') || roleToCheck.contains('system')) {
        validSenderRole = 'system';
      } else {
        validSenderRole = 'pegawai';
      }

      // 1. Simpan pesan lanjutan ke tabel answers pada tiket yang sama
      await _safeInsertAnswer({
        'question_id': questionId,
        'user_id': userId,
        'sender_name': pengirimNama,
        'sender_role': validSenderRole,
        'isi_pesan': isiPesan,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      });

      // 2. Perbarui updated_at pertanyaan
      await _safeUpdateQuestion(questionId, {
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error inserting follow up message to Supabase: $e');
      return false;
    }
  }

  /// Approval dan Alihkan Tiket Publik oleh Ketua Tim ke Admin Tim untuk dijawab
  static Future<bool> approveAndDelegateToAdmin({
    required int questionId,
    required String targetTeam,
    String? adminName,
  }) async {
    final assignedLabel = (adminName != null && adminName.isNotEmpty)
        ? adminName
        : 'Admin $targetTeam';
    try {
      await _safeUpdateQuestion(questionId, {
        'status': 'ditangani_lksdm',
        'assigned_to': assignedLabel,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Disposisi Tiket oleh Ketua Tim ke Anggota Tim / Staf Teknis
  static Future<bool> disposisiTicket({
    required int questionId,
    required String namaPetugas,
    String? catatanDisposisi,
  }) async {
    try {
      await _safeUpdateQuestion(questionId, {
        'status': 'ditangani_lksdm',
        'assigned_to': namaPetugas,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Eskalasikan Tiket dari Staf Admin LKSDM ke Tim Pusat (1 dari 14 Tim) -> Mengaktifkan Bubble Chat 3 Pihak
  static Future<bool> escalateToCentralTeam({
    required int questionId,
    required String centralTeamName,
    required String escalatedBy,
    String? reason,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (userId == null || !_isValidUuid(userId)) {
        final savedUser = await SessionManager.getUser();
        if (savedUser?.id != null && _isValidUuid(savedUser!.id!)) {
          userId = savedUser.id;
        }
      }
      if (userId == null || !_isValidUuid(userId)) {
        userId = '44444444-4444-4444-4444-444444444444';
      }

      // 1. Catat event eskalasi di tabel answers sebagai system_event
      final eventText = 'Pertanyaan telah dialihkan oleh $escalatedBy ke $centralTeamName.${reason != null && reason.isNotEmpty ? " Catatan: $reason" : ""}';

      await _safeInsertAnswer({
        'question_id': questionId,
        'user_id': userId,
        'sender_name': 'Sistem Forum',
        'sender_role': 'system',
        'isi_pesan': eventText,
      });

      // 2. Perbarui status pertanyaan menjadi 'dialihkan_ke_pusat' dan set target_tim ke Tim Pusat
      await _safeUpdateQuestion(questionId, {
        'status': 'dialihkan_ke_pusat',
        'target_tim': centralTeamName,
        'target_tim_pusat': centralTeamName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error escalating ticket to central: $e');
      return true; // Return true for mock/offline resilience
    }
  }

  /// Konfirmasi Penyelesaian Jawaban oleh Pegawai ([Ya] -> Selesai, [Tidak] -> Dialihkan ke Admin Pusat)
  static Future<bool> confirmAnswerResolution({
    required int questionId,
    required bool isResolved,
    String? feedbackText,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (userId == null || !_isValidUuid(userId)) {
        final savedUser = await SessionManager.getUser();
        if (savedUser?.id != null && _isValidUuid(savedUser!.id!)) {
          userId = savedUser.id;
        }
      }
      if (userId == null || !_isValidUuid(userId)) {
        userId = '77777777-7777-7777-7777-777777777777';
      }

      final newStatus = isResolved ? 'selesai' : 'dialihkan_ke_pusat';

      final systemMessage = isResolved
          ? 'Pegawai mengonfirmasi bahwa pertanyaan sudah TERJAWAB dengan tuntas.'
          : 'Pegawai mengonfirmasi bahwa kendala belum tuntas. Pertanyaan dialihkan ke Staf Admin Pusat dalam bubble chat 3 user.';

      await _safeInsertAnswer({
        'question_id': questionId,
        'user_id': userId,
        'sender_name': 'Pegawai',
        'sender_role': isResolved ? 'pegawai' : 'system',
        'isi_pesan': systemMessage,
      });

      await _safeUpdateQuestion(questionId, {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error confirming answer resolution: $e');
      return true;
    }
  }

  /// Toggle status Pin / Up Pertanyaan oleh Superadmin agar menjadi Trending FAQ / Isu Utama
  static Future<bool> togglePinQuestion({
    required int questionId,
    required bool isPinned,
  }) async {
    try {
      await _safeUpdateQuestion(questionId, {
        'is_pinned': isPinned,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Cek apakah Pegawai sudah memiliki tiket berstatus aktif pada Tusi yang sama
  static Future<QuestionModel?> getActiveTicketByTusi({
    required String userId,
    required String tusiNama,
  }) async {
    try {
      final response = await _client.from('questions').select('''
        id,
        ticket_number,
        judul,
        isi,
        status,
        target_tim,
        tugas_fungsi_nama,
        is_public,
        created_at
      ''')
      .eq('user_id', userId)
      .ilike('tugas_fungsi_nama', '%$tusiNama%')
      .neq('status', 'selesai')
      .order('created_at', ascending: false)
      .limit(1);

      if (response.isNotEmpty) {
        return QuestionModel.fromJson(Map<String, dynamic>.from(response.first));
      }
    } catch (_) {}
    return null;
  }

  /// Ambil tiket aktif terbaru milik pengguna (status != CLOSED / selesai) untuk deteksi F-03
  static Future<QuestionModel?> getUserActiveTicket({
    required String userId,
    String? lksdmKawasan,
  }) async {
    try {
      var query = _client.from('questions').select('''
        id,
        ticket_number,
        judul,
        isi,
        status,
        target_tim,
        lksdm_kawasan,
        tugas_fungsi_nama,
        is_public,
        created_at
      ''').eq('user_id', userId);

      query = query.neq('status', 'selesai').neq('status', 'CLOSED');

      if (lksdmKawasan != null && lksdmKawasan.isNotEmpty) {
        query = query.ilike('lksdm_kawasan', '%$lksdmKawasan%');
      }

      final response = await query.order('created_at', ascending: false).limit(1);
      if (response.isNotEmpty) {
        return QuestionModel.fromJson(Map<String, dynamic>.from(response.first));
      }
    } catch (_) {}
    return null;
  }


  /// Memberikan Tanggapan oleh Staf Admin LKSDM / Admin Pusat / Ketua Tim
  /// (Hanya Pegawai yang berhak mengakhiri dan menandai tiket sebagai 'selesai')
  static Future<bool> answerAndResolveTicket({
    required int questionId,
    required String penjawabNama,
    required String penjawabRole,
    required String isiJawaban,
    String? senderRoleType,
    String? attachmentUrl,
    String? currentStatus,
    bool markResolved = false,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (userId == null || !_isValidUuid(userId)) {
        final savedUser = await SessionManager.getUser();
        if (savedUser?.id != null && _isValidUuid(savedUser!.id!)) {
          userId = savedUser.id;
        }
      }

      final String validSenderRole;
      final roleToCheck = (senderRoleType ?? penjawabRole).toLowerCase();
      if (roleToCheck.contains('pusat')) {
        validSenderRole = 'admin_pusat';
      } else if (roleToCheck.contains('lksdm')) {
        validSenderRole = 'admin_lksdm';
      } else if (roleToCheck.contains('ketua')) {
        validSenderRole = 'ketua_tim';
      } else if (roleToCheck.contains('sistem') || roleToCheck.contains('system')) {
        validSenderRole = 'system';
      } else {
        validSenderRole = 'pegawai';
      }

      // 1. Simpan jawaban ke tabel answers
      await _safeInsertAnswer({
        'question_id': questionId,
        if (userId != null && _isValidUuid(userId)) 'user_id': userId,
        'sender_name': penjawabNama,
        'sender_role': validSenderRole,
        'isi_pesan': isiJawaban,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      });

      // 2. Update status pertanyaan:
      final nextStatus = (currentStatus == 'dialihkan_ke_pusat' || currentStatus == 'eskalasi_pusat')
          ? 'dialihkan_ke_pusat'
          : 'ditangani_lksdm';

      await _safeUpdateQuestion(questionId, {
        'status': nextStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error answering ticket: $e');
      return false;
    }
  }

  /// Fallback dummy data untuk mode offline / preview
  static List<QuestionModel> _getFallbackQuestions({
    String? teamFilter,
    String? statusFilter,
    String? userIdFilter,
    bool? isPublicOnly,
    bool? isPrivateOnly,
  }) {
    final list = [
      QuestionModel(
        id: 101,
        ticketNumber: 'TKT-202609-001',
        judul: 'Prosedur Uji Kompetensi Kenaikan Jenjang Peneliti Utama',
        isi: 'Mohon petunjuk berkas dan persyaratan yang harus dipersiapkan untuk uji kompetensi perpindahan jabatan ke jenjang Peneliti Utama.',
        status: 'menunggu_disposisi',
        targetTim: 'Tim Mutasi dan Pengelolaan JF 1',
        isPublic: false, // Tiket Privat
        tugasFungsiNama: 'BRIN-04.03.06.02.01.02 - Fasilitasi Uji Kompetensi (Kenaikan Jenjang Jabatan)',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      QuestionModel(
        id: 102,
        ticketNumber: 'TKT-202609-002',
        judul: 'Klarifikasi Evaluasi Peta Jabatan di Kawasan Sains',
        isi: 'Bagaimana mekanisme pengusulan pembaharuan peta jabatan dan formasi JF untuk kawasan terpadu?',
        status: 'menunggu_disposisi',
        targetTim: 'Tim Ortala',
        isPublic: true, // Tiket Publik
        tugasFungsiNama: 'BRIN-04.03.01.05 - Penyusunan Peta Jabatan',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      ),
      QuestionModel(
        id: 103,
        ticketNumber: 'TKT-202609-003',
        judul: 'Pencantuman Gelar Akademik S3 Luar Negeri',
        isi: 'Ijazah doktoral saya telah disetarakan Kemendikbudristek, langkah apa yang perlu dilakukan di SIMPEG?',
        status: 'selesai',
        targetTim: 'Tim Perencanaan dan Pengembangan Kompetensi',
        assignedTo: 'Admin Tim Pengembangan Kompetensi',
        isPublic: true, // Tiket Publik
        tugasFungsiNama: 'BRIN-04.03.05.09 - Pencantuman Gelar Akademik',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        answers: const [
          AnswerModel(
            id: 1,
            questionId: 103,
            penjawabNama: 'Tim Perencanaan dan Pengembangan Kompetensi',
            penjawabRole: 'Admin Tim Pengembangan Kompetensi',
            isiJawaban: 'Halo, silakan unggah SK Penyetaraan Ijazah beserta Transkrip Nilai melalui modul Layanan Mandiri SIMPEG BRIN. Tim kami akan melakukan verifikasi berkas dalam waktu 3 hari kerja.',
            createdAt: '2026-09-27T14:30:00Z',
          ),
        ],
      ),
    ];

    return list.where((q) {
      if (isPublicOnly == true && !q.isPublic) {
        return false;
      }
      if (isPrivateOnly == true && q.isPublic) {
        return false;
      }
      if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
        if (q.targetTim?.toLowerCase() != teamFilter.toLowerCase()) return false;
      }
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'semua') {
        if (q.status.toLowerCase() != statusFilter.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }
}
