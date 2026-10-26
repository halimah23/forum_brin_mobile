import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/session_manager.dart';
import '../data/tusi_catalog_data.dart';
import '../models/answer_model.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../../notifications/services/notification_service.dart';

class QuestionService {
  static SupabaseClient get _client => Supabase.instance.client;
  static DateTime? _lastAutoResolveCheck;

  /// Helper untuk menentukan Nama Tim berdasarkan Kode atau Nama Tugas & Fungsi
  static String determineTeamName(String? categoryName) {
    return TusiCatalogData.resolveTeam(categoryName);
  }

  /// Ambil daftar seluruh 15 Tim BOSDM
  static Future<List<String>> getTeams() async {
    try {
      final response = await _client.from('teams').select();
      final list = response
          .map((item) => (item['detail_nama_tim'] ?? item['tim'] ?? item['nama'])?.toString() ?? '')
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
      if (teamName != null && teamName.isNotEmpty) {
        // Query via relasi team_tusi
        try {
          final response = await _client
              .from('team_tusi')
              .select('tugas_fungsi:id_tusi(*), teams:id_tim(*)')
              .or('teams.tim.ilike.%$teamName%,teams.detail_nama_tim.ilike.%$teamName%');
          final list = response.map((item) {
            final tusi = item['tugas_fungsi'] as Map<String, dynamic>? ?? {};
            final team = item['teams'] as Map<String, dynamic>? ?? {};
            return CategoryModel(
              id: int.tryParse(tusi['id_tusi']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
              idTusi: tusi['id_tusi']?.toString(),
              nama: tusi['tugas_fungsi']?.toString() ?? '-',
              kode: tusi['id_tusi']?.toString(),
              teamName: team['detail_nama_tim']?.toString() ?? team['tim']?.toString(),
            );
          }).toList();
          if (list.isNotEmpty) return list;
        } catch (_) {}

        var query = _client.from('tugas_fungsi').select();
        query = query.ilike('team_nama', '%$teamName%');
        final response = await query;
        final list = response
            .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (list.isNotEmpty) return list;
      } else {
        final response = await _client.from('tugas_fungsi').select();
        final list = response
            .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Fallback lokal
    }

    if (teamName != null && teamName.isNotEmpty) {
      return TusiCatalogData.getTugasFungsiByTeam(teamName);
    }
    return TusiCatalogData.allTugasFungsi;
  }

  /// Ambil seluruh pertanyaan / tiket dengan filter opsional (Tim, Status, dsb)
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
      PostgrestFilterBuilder<List<Map<String, dynamic>>> buildQuery(String selectClause) {
        var q = _client.from('questions').select(selectClause);

        if (isPublicOnly == true) {
          q = q.eq('is_public', true);
        } else if (isPrivateOnly == true) {
          q = q.eq('is_public', false);
        }

        if (userIdFilter != null && userIdFilter.isNotEmpty) {
          q = q.eq('user_id', userIdFilter);
        }

        if (teamFilter != null &&
            teamFilter.isNotEmpty &&
            teamFilter != 'Semua Tim') {
          final cleanTeam = teamFilter.trim();
          final lksdmMatch = RegExp(r'LKSDM\s*(\d+)', caseSensitive: false).firstMatch(cleanTeam);
          if (lksdmMatch != null) {
            final shortLksdm = 'LKSDM ${lksdmMatch.group(1)}';
            q = q.or(
                'lksdm_kawasan.ilike.%$shortLksdm%,lksdm_kawasan.ilike.%$cleanTeam%,target_tim_pusat.ilike.%$cleanTeam%');
          } else {
            q = q.or(
                'lksdm_kawasan.ilike.%$cleanTeam%,target_tim_pusat.ilike.%$cleanTeam%');
          }
        }

        if (statusFilter != null &&
            statusFilter.isNotEmpty &&
            statusFilter.toLowerCase() != 'semua') {
          final normalizedStatus = statusFilter.toLowerCase();
          if (normalizedStatus == 'menunggu_lksdm' ||
              normalizedStatus == 'open') {
            q = q.inFilter('status',
                ['menunggu_lksdm', 'menunggu_disposisi', 'OPEN', 'open']);
          } else if (normalizedStatus == 'ditangani_lksdm' ||
              normalizedStatus == 'in_progress' ||
              normalizedStatus == 'waiting_user') {
            q = q.inFilter('status', [
              'ditangani_lksdm',
              'sedang_diproses',
              'IN_PROGRESS',
              'WAITING_USER',
              'in_progress',
              'waiting_user'
            ]);
          } else if (normalizedStatus == 'dialihkan_ke_pusat' ||
              normalizedStatus == 'eskalasi_pusat' ||
              normalizedStatus == 'escalated' ||
              normalizedStatus == 'in_progress_center') {
            q = q.inFilter('status', [
              'dialihkan_ke_pusat',
              'eskalasi_pusat',
              'ESCALATED',
              'IN_PROGRESS_CENTER',
              'escalated',
              'in_progress_center',
              'tiket_mandiri_lksdm',
              'TIKET_MANDIRI_LKSDM',
            ]);
          } else if (normalizedStatus == 'tiket_mandiri_lksdm' ||
              normalizedStatus == 'konsultasi_lksdm' ||
              normalizedStatus == 'mandiri_lksdm') {
            q = q.inFilter('status', [
              'tiket_mandiri_lksdm',
              'konsultasi_lksdm',
              'mandiri_lksdm',
              'TIKET_MANDIRI_LKSDM',
            ]);
          } else if (normalizedStatus == 'selesai' ||
              normalizedStatus == 'closed' ||
              normalizedStatus == 'resolved') {
            q = q.inFilter('status',
                ['selesai', 'CLOSED', 'RESOLVED', 'closed', 'resolved']);
          } else {
            q = q.eq('status', statusFilter);
          }
        }
        return q;
      }

      List<dynamic> response;
      try {
        response = await buildQuery('''
          id,
          ticket_number,
          judul,
          isi,
          status,
          tugas_fungsi_nama,
          lksdm_kawasan,
          target_tim_pusat,
          admin_lksdm_id,
          admin_pusat_id,
          is_public,
          is_pinned,
          created_at,
          attachment_url,
          attachment_name,
          rating,
          rating_feedback,
          rating_submitted_at,
          rating_tags,
          resolved_at,
          users:user_id (id_user, first_name, email, role, satuan_kerja, kawasan, jabatan, teams:id_tim(id_tim, tim, detail_nama_tim, eskalasi)),
          tugas_fungsi:id_tusi (id_tusi, tugas_fungsi)
        ''').order('created_at', ascending: false);
      } catch (err) {
        try {
          response = await buildQuery('''
            id,
            ticket_number,
            judul,
            isi,
            status,
            tugas_fungsi_nama,
            lksdm_kawasan,
            target_tim_pusat,
            admin_lksdm_id,
            admin_pusat_id,
            is_public,
            is_pinned,
            created_at,
            attachment_url,
            attachment_name,
            rating,
            rating_feedback,
            rating_submitted_at,
            resolved_at,
            users:user_id (id_user, first_name, email, role, satuan_kerja, kawasan, jabatan, teams:id_tim(id_tim, tim, detail_nama_tim, eskalasi))
          ''').order('created_at', ascending: false);
        } catch (err2) {
          debugPrint('Fallback question query basic fields: $err2');
          response = await buildQuery('''
            id,
            user_id,
            ticket_number,
            judul,
            isi,
            status,
            tugas_fungsi_nama,
            lksdm_kawasan,
            target_tim_pusat,
            admin_lksdm_id,
            admin_pusat_id,
            is_public,
            is_pinned,
            created_at,
            rating,
            rating_feedback,
            rating_submitted_at,
            rating_tags,
            resolved_at
          ''').order('created_at', ascending: false);
        }
      }
      final List<Map<String, dynamic>> questionList =
          List<Map<String, dynamic>>.from(response);

      // 2. Ambil jawaban dari tabel answers secara aman (tanpa hardcode nama kolom)
      try {
        final answersResponse = await _client
            .from('answers')
            .select()
            .order('created_at', ascending: true);

        final Map<int, List<Map<String, dynamic>>> answersGrouped = {};
        for (var item in answersResponse) {
          final qId = item['question_id'] is int
              ? item['question_id'] as int
              : int.tryParse(item['question_id']?.toString() ?? '') ?? 0;
          answersGrouped
              .putIfAbsent(qId, () => [])
              .add(Map<String, dynamic>.from(item));
        }

        for (var qMap in questionList) {
          final qId = qMap['id'] is int
              ? qMap['id'] as int
              : int.tryParse(qMap['id']?.toString() ?? '') ?? 0;
          if (answersGrouped.containsKey(qId)) {
            qMap['answers'] = answersGrouped[qId];
          }
        }
      } catch (e) {
        debugPrint('Error grouping answers in getQuestions: $e');
      }

      final list = questionList.map((item) => QuestionModel.fromJson(item)).toList();
      unawaited(checkAndProcessAutoResolveQuestions(list));
      return list;
    } catch (e) {
      debugPrint('Error fetching questions from Supabase: $e');
      return [];
    }
  }

  /// Ambil detail 1 pertanyaan beserta seluruh percakapan/jawaban terbarunya secara live
  static Future<QuestionModel?> getQuestionDetail(int questionId) async {
    try {
      Map<String, dynamic> qResponse;
      try {
        final res = await _client.from('questions').select('''
          id,
          ticket_number,
          judul,
          isi,
          status,
          tugas_fungsi_nama,
          lksdm_kawasan,
          target_tim_pusat,
          admin_lksdm_id,
          admin_pusat_id,
          is_public,
          is_pinned,
          created_at,
          attachment_url,
          attachment_name,
          rating,
          rating_feedback,
          rating_submitted_at,
          rating_tags,
          resolved_at,
          users:user_id (id_user, first_name, email, role, satuan_kerja, kawasan, jabatan, teams:id_tim(id_tim, tim, detail_nama_tim, eskalasi)),
          tugas_fungsi:id_tusi (id_tusi, tugas_fungsi)
        ''').eq('id', questionId).single();
        qResponse = Map<String, dynamic>.from(res);
      } catch (_) {
        try {
          final res = await _client.from('questions').select('''
            id,
            ticket_number,
            judul,
            isi,
            status,
            tugas_fungsi_nama,
            lksdm_kawasan,
            target_tim_pusat,
            admin_lksdm_id,
            admin_pusat_id,
            is_public,
            is_pinned,
            created_at,
            attachment_url,
            attachment_name,
            rating,
            rating_feedback,
            rating_submitted_at,
            resolved_at,
            users:user_id (id_user, first_name, email, role, satuan_kerja, kawasan, jabatan, teams:id_tim(id_tim, tim, detail_nama_tim, eskalasi))
          ''').eq('id', questionId).single();
          qResponse = Map<String, dynamic>.from(res);
        } catch (_) {
          final res = await _client.from('questions').select('''
            id,
            user_id,
            ticket_number,
            judul,
            isi,
            status,
            tugas_fungsi_nama,
            lksdm_kawasan,
            target_tim_pusat,
            admin_lksdm_id,
            admin_pusat_id,
            is_public,
            is_pinned,
            created_at,
            rating,
            rating_feedback,
            rating_submitted_at,
            rating_tags,
            resolved_at
          ''').eq('id', questionId).single();
          qResponse = Map<String, dynamic>.from(res);
        }
      }

      final qMap = Map<String, dynamic>.from(qResponse);

      // Ambil answers langsung untuk ID pertanyaan ini
      try {
        final answersResponse = await _client
            .from('answers')
            .select()
            .eq('question_id', questionId)
            .order('created_at', ascending: true);
        qMap['answers'] = List<Map<String, dynamic>>.from(answersResponse);
      } catch (e) {
        debugPrint('Error fetching answers for question $questionId: $e');
      }

      final qObj = QuestionModel.fromJson(qMap);
      unawaited(checkAndProcessAutoResolveQuestions([qObj]));
      return qObj;
    } catch (e) {
      debugPrint('Error fetching question detail $questionId: $e');
      return null;
    }
  }

  /// Ambil pertanyaan milik Member yang sedang login
  static Future<List<QuestionModel>> getMyQuestions({
    String? userId,
    String? statusFilter,
    String? token,
  }) async {
    final currentUserId = userId ??
        _client.auth.currentUser?.id ??
        (await SessionManager.getUser())?.id?.toString();
    return getQuestions(
      userIdFilter: currentUserId,
      statusFilter: statusFilter,
      token: token,
    );
  }

  static bool _isValidUserId(String? id) {
    if (id == null) return false;
    final clean = id.trim();
    return clean.isNotEmpty;
  }

  static bool _isValidUuid(String? id) => _isValidUserId(id);

  /// Mengirimkan notifikasi ke seluruh Staf Admin dan Ketua Tim yang bertugas di tim / kawasan terkait
  static Future<void> notifyTeamMembers({
    required String targetTeam,
    int? questionId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      final cleanTarget = targetTeam.trim().toUpperCase();
      final lksdmMatch = RegExp(r'LKSDM\s*(\d+)', caseSensitive: false).firstMatch(cleanTarget);
      final targetShortLksdm = lksdmMatch != null ? 'LKSDM ${lksdmMatch.group(1)}' : cleanTarget;

      final users = await _client
          .from('users')
          .select('id_user, role, kawasan, teams:id_tim(id_tim, tim, eskalasi)')
          .or('role.ilike.%admin%,role.ilike.%ketua%,role.ilike.%lksdm%,role.ilike.%pusat%');

      final matchedIds = <String>[];
      for (var u in users) {
        final uTeam = (u['teams'] is Map ? u['teams']['tim'] : null)?.toString().toUpperCase() ?? '';
        final uKawasan = u['kawasan']?.toString().toUpperCase() ?? '';
        final uId = u['id_user']?.toString();

        if (uId == null || uId.isEmpty) continue;

        bool isMatch = false;
        if (targetShortLksdm.startsWith('LKSDM')) {
          if (uTeam.contains(targetShortLksdm) || uKawasan.contains(targetShortLksdm)) {
            isMatch = true;
          }
        } else {
          if (uTeam == cleanTarget ||
              (uTeam.isNotEmpty && cleanTarget.contains(uTeam)) ||
              (cleanTarget.isNotEmpty && uTeam.contains(cleanTarget))) {
            isMatch = true;
          }
        }

        if (isMatch) {
          matchedIds.add(uId);
        }
      }

      debugPrint(
        '>>> [NOTIFY TEAM] Target: "$cleanTarget", Found: ${matchedIds.length} user(s): $matchedIds',
      );

      if (matchedIds.isNotEmpty) {
        final futures = matchedIds.map((id) => NotificationService.createNotification(
          userId: id,
          questionId: questionId,
          title: title,
          message: message,
          type: type,
        ));
        await Future.wait(futures);
      }
    } catch (e) {
      debugPrint('Notice notifyTeamMembers error: $e');
    }
  }

  /// Buat Tiket Pertanyaan Baru (Mendukung Tiket Pegawai & Konsultasi Mandiri LKSDM ke Pusat)
  static Future<QuestionModel> createQuestion({
    required String token,
    required String judul,
    required String isi,
    required List<int> tugasFungsiIds,
    String? selectedTeam,
    String? lksdmKawasan,
    String? targetTimPusat,
    bool isPublic = false,
    String? attachmentUrl,
    String? attachmentName,
    bool isLksdmConsultation = false,
  }) async {
    final currentUser = _client.auth.currentUser;
    String? resolvedId = currentUser?.id;

    if (!_isValidUserId(resolvedId)) {
      final savedUser = await SessionManager.getUser();
      if (_isValidUserId(savedUser?.id)) {
        resolvedId = savedUser!.id;
      }
    }
    if (!_isValidUserId(resolvedId)) {
      throw Exception('Sesi pengguna tidak valid atau belum login.');
    }
    final String userId = resolvedId!;

    // Tentukan Tusi dan Tim Terkait
    String targetTeam = selectedTeam ?? 'Tim Layanan SDM BOSDM';
    String tusiNama = 'Layanan Umum Kepegawaian';

    if (tugasFungsiIds.isNotEmpty) {
      final selectedId = tugasFungsiIds.first;
      final foundTusi = TusiCatalogData.allTugasFungsi
          .where((t) => t.id == selectedId)
          .firstOrNull;
      if (foundTusi != null) {
        tusiNama = foundTusi.fullDisplayName;
        if (selectedTeam == null || selectedTeam.isEmpty) {
          targetTeam =
              foundTusi.teamName ?? TusiCatalogData.resolveTeam(foundTusi.nama);
        }
      }
    }

    final ticketNumber =
        'TKT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final String effectiveLksdm = lksdmKawasan ??
        (selectedTeam != null && selectedTeam.contains('LKSDM')
            ? selectedTeam
            : 'LKSDM 1');
    final effectiveTargetPusat = targetTimPusat ?? (targetTeam.contains('LKSDM') ? null : targetTeam);

    try {
      final initialStatus = isLksdmConsultation ? 'tiket_mandiri_lksdm' : 'menunggu_lksdm';
      final insertPayload = <String, dynamic>{
        'user_id': userId,
        'ticket_number': ticketNumber,
        'judul': judul,
        'isi': isi,
        'tugas_fungsi_nama': tusiNama,
        'lksdm_kawasan': effectiveLksdm,
        if (effectiveTargetPusat != null) 'target_tim_pusat': effectiveTargetPusat,
        'is_public': false,
        'status': initialStatus, // Status awal tiket
      };
      if (attachmentUrl != null) {
        insertPayload['attachment_url'] = attachmentUrl;
      }
      if (attachmentName != null) {
        insertPayload['attachment_name'] = attachmentName;
      }

      Map<String, dynamic>? insertedQuestion;
      Map<String, dynamic> toInsert = Map<String, dynamic>.from(insertPayload);

      for (int retry = 0; retry < 4; retry++) {
        try {
          insertedQuestion =
              await _client.from('questions').insert(toInsert).select('''
            id,
            ticket_number,
            judul,
            isi,
            status,
            tugas_fungsi_nama,
            lksdm_kawasan,
            target_tim_pusat,
            admin_lksdm_id,
            admin_pusat_id,
            is_public,
            is_pinned,
            created_at,
            users:user_id (id_user, first_name, email, role, satuan_kerja, kawasan, jabatan, teams:id_tim(id_tim, tim, detail_nama_tim, eskalasi))
          ''').single();
          break;
        } catch (e) {
          final errStr = e.toString();
          debugPrint(
              'Postgrest insert question attempt $retry failed: $errStr');
          if (errStr.contains('PGRST204') ||
              errStr.contains('does not exist')) {
            final match = RegExp(
                    r"(?:Could not find the '([^']+)' column|column questions\.([a-zA-Z0-9_]+) does not exist)")
                .firstMatch(errStr);
            if (match != null) {
              final col = match.group(1) ?? match.group(2);
              if (col != null && toInsert.containsKey(col)) {
                toInsert.remove(col);
                continue;
              }
            }
            if (toInsert.containsKey('attachment_name')) {
              toInsert.remove('attachment_name');
              continue;
            }
            if (toInsert.containsKey('attachment_url')) {
              toInsert.remove('attachment_url');
              continue;
            }
          }
          if (retry == 3) rethrow;
        }
      }

      if (insertedQuestion == null) {
        throw Exception('Gagal menyimpan tiket pertanyaan ke server Supabase.');
      }

      final questionId = insertedQuestion['id'] is int
          ? insertedQuestion['id'] as int
          : int.parse(insertedQuestion['id'].toString());

      // Trigger notifikasi tiket berhasil dibuat
      try {
        if (isLksdmConsultation) {
          await NotificationService.createNotification(
            userId: userId,
            questionId: questionId,
            title: 'Konsultasi LKSDM Diajukan',
            message:
                'Tiket #$ticketNumber Anda telah berhasil diteruskan langsung ke $effectiveTargetPusat.',
            type: 'tiket_diajukan',
          );

          if (effectiveTargetPusat != null && effectiveTargetPusat.isNotEmpty) {
            await notifyTeamMembers(
              targetTeam: effectiveTargetPusat,
              questionId: questionId,
              title: 'Konsultasi Baru dari $effectiveLksdm (#$ticketNumber)',
              message: 'Staf/Ketua $effectiveLksdm mengajukan konsultasi ke $effectiveTargetPusat: "$judul".',
              type: 'tiket_baru',
            );
          }
        } else {
          await NotificationService.createNotification(
            userId: userId,
            questionId: questionId,
            title: 'Tiket Berhasil Diajukan',
            message:
                'Tiket #$ticketNumber Anda sedang menunggu verifikasi oleh Staf Layanan Kawasan SDM ($effectiveLksdm).',
            type: 'tiket_diajukan',
          );

          // Notifikasi ke seluruh Staf Admin & Ketua Tim Kawasan LKSDM
          await notifyTeamMembers(
            targetTeam: effectiveLksdm,
            questionId: questionId,
            title: 'Tiket Baru Masuk (#$ticketNumber)',
            message: 'Ada tiket baru dari pegawai di $effectiveLksdm: "$judul".',
            type: 'tiket_baru',
          );
        }
      } catch (e) {
        debugPrint('Warning: Notification creation failed: $e');
      }

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

      return QuestionModel.fromJson(
          Map<String, dynamic>.from(insertedQuestion));
    } catch (e) {
      debugPrint('Error inserting question to Supabase: $e');
      rethrow;
    }
  }

  static Future<void> _safeInsertAnswer(Map<String, dynamic> payload) async {
    final name =
        payload['sender_name'] ?? payload['penjawab_nama'] ?? 'Pengguna';
    final role =
        payload['sender_role'] ?? payload['penjawab_role'] ?? 'pegawai';
    final msg = payload['isi_pesan'] ?? payload['isi_jawaban'] ?? '-';

    // 1. Coba format tabel answers SOP instansi terbaru
    final Map<String, dynamic> modernPayload = {
      'question_id': payload['question_id'],
      'sender_name': name,
      'sender_role': role,
      'isi_pesan': msg,
    };
    if (payload['user_id'] != null) {
      modernPayload['user_id'] = payload['user_id'];
    }
    if (payload['attachment_url'] != null) {
      modernPayload['attachment_url'] = payload['attachment_url'];
    }
    if (payload['attachment_name'] != null) {
      modernPayload['attachment_name'] = payload['attachment_name'];
    }

    try {
      await _client.from('answers').insert(modernPayload);
      return;
    } catch (_) {}

    // 2. Fallback untuk skema legacy
    final Map<String, dynamic> candidate = Map<String, dynamic>.from(payload);
    candidate['penjawab_nama'] = name;
    candidate['sender_name'] = name;
    candidate['penjawab_role'] = role;
    candidate['sender_role'] = role;
    candidate['isi_jawaban'] = msg;
    candidate['isi_pesan'] = msg;
    candidate.remove('user_id');

    Map<String, dynamic> toInsert = Map<String, dynamic>.from(candidate);
    for (int retry = 0; retry < 6; retry++) {
      try {
        await _client.from('answers').insert(toInsert);
        return;
      } catch (e) {
        final errStr = e.toString();
        debugPrint('Postgrest answer insert attempt $retry failed: $errStr');
        if (errStr.contains('PGRST204') ||
            errStr.contains('Could not find the') ||
            errStr.contains('does not exist')) {
          final match = RegExp(
                  r"(?:Could not find the '([^']+)' column|column answers\.([a-zA-Z0-9_]+) does not exist)")
              .firstMatch(errStr);
          if (match != null) {
            final col = match.group(1) ?? match.group(2);
            if (col != null && toInsert.containsKey(col)) {
              toInsert.remove(col);
              continue;
            }
          }
          if (toInsert.containsKey('sender_role_type')) {
            toInsert.remove('sender_role_type');
            continue;
          }
          if (toInsert.containsKey('attachment_url')) {
            toInsert.remove('attachment_url');
            continue;
          }
        }
        if (retry == 5) rethrow;
      }
    }
  }

  static Future<void> _safeUpdateQuestion(
      int questionId, Map<String, dynamic> payload) async {
    Map<String, dynamic> toUpdate = Map<String, dynamic>.from(payload);
    toUpdate.remove(
        'updated_at'); // Remove updated_at as it is not present in questions table
    if (toUpdate.isEmpty) return;

    for (int retry = 0; retry < 5; retry++) {
      try {
        await _client.from('questions').update(toUpdate).eq('id', questionId);
        return;
      } catch (e) {
        final errStr = e.toString();
        debugPrint('Postgrest question update attempt $retry failed: $errStr');
        if (errStr.contains('updated_at') ||
            errStr.contains('PGRST204') ||
            errStr.contains('Could not find the') ||
            errStr.contains('does not exist')) {
          final match = RegExp(
                  r"(?:Could not find the '([^']+)' column|column questions\.([a-zA-Z0-9_]+) does not exist)")
              .firstMatch(errStr);
          if (match != null) {
            final col = match.group(1) ?? match.group(2);
            if (col != null && toUpdate.containsKey(col)) {
              toUpdate.remove(col);
              if (toUpdate.isEmpty) return;
              continue;
            }
          }
          toUpdate.remove('updated_at');
          if (toUpdate.isEmpty) return;
          continue;
        }
        if (retry == 4) {
          debugPrint('Error updating question $questionId: $e');
        }
      }
    }
  }

  /// Kirim Pesan Balasan / Percakapan Lanjutan oleh Pengguna (Pegawai/Admin LKSDM/Admin Pusat/Ketua Tim)
  static Future<bool> sendFollowUpMessage({
    required int questionId,
    required String isiPesan,
    required String pengirimNama,
    String pengirimRole = 'pegawai',
    String? senderRoleType,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (!_isValidUserId(userId)) {
        final savedUser = await SessionManager.getUser();
        if (_isValidUserId(savedUser?.id)) {
          userId = savedUser!.id;
        }
      }
      if (userId == null || userId.trim().isEmpty) {
        throw Exception('Sesi pengguna tidak valid atau belum login.');
      }

      final String validSenderRole;
      final roleToCheck = (senderRoleType ?? pengirimRole).toLowerCase();
      if (roleToCheck.contains('pusat')) {
        validSenderRole = 'admin_pusat';
      } else if (roleToCheck.contains('lksdm')) {
        validSenderRole = 'admin_lksdm';
      } else if (roleToCheck.contains('ketua')) {
        validSenderRole = 'ketua_tim';
      } else if (roleToCheck.contains('sistem') ||
          roleToCheck.contains('system')) {
        validSenderRole = 'system';
      } else {
        validSenderRole = 'pegawai';
      }

      // 1. Simpan pesan ke tabel answers
      await _safeInsertAnswer({
        'question_id': questionId,
        'user_id': userId,
        'sender_name': pengirimNama,
        'penjawab_nama': pengirimNama,
        'sender_role': validSenderRole,
        'penjawab_role': pengirimRole,
        'sender_role_type': validSenderRole,
        'isi_pesan': isiPesan,
        'isi_jawaban': isiPesan,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (attachmentName != null) 'attachment_name': attachmentName,
      });

      // 2. Perbarui status pertanyaan: jika direspon oleh Ketua Tim / Admin LKSDM, ubah jadi 'ditangani_lksdm' (IN_PROGRESS)
      final updateData = <String, dynamic>{};
      if (validSenderRole == 'admin_lksdm' || validSenderRole == 'ketua_tim') {
        updateData['status'] = 'ditangani_lksdm';
      } else if (validSenderRole == 'admin_pusat') {
        updateData['status'] = 'dialihkan_ke_pusat';
      }

      if (updateData.isNotEmpty) {
        await _safeUpdateQuestion(questionId, updateData);
      }

      // 3. Dispatch notifikasi ke pihak lawan bicara
      try {
        final qRecord = await _client
            .from('questions')
            .select('user_id, ticket_number, lksdm_kawasan, target_tim_pusat')
            .eq('id', questionId)
            .maybeSingle();

        if (qRecord != null) {
          final authorId = qRecord['user_id']?.toString();
          final ticketNumber = qRecord['ticket_number']?.toString() ?? questionId.toString();

          if (validSenderRole != 'pegawai') {
            // Dijawab oleh staf/ketua tim -> Kirim notifikasi ke Pegawai
            if (authorId != null && authorId.isNotEmpty) {
              await NotificationService.createNotification(
                userId: authorId,
                questionId: questionId,
                title: 'Pertanyaan Anda Telah Dijawab',
                message: '$pengirimNama telah memberikan jawaban pada tiket #$ticketNumber Anda.',
                type: 'jawaban_baru',
              );
            }
          } else {
            // Pegawai mengirim pesan balasan -> Kirim notifikasi ke tim penangan
            final targetLksdm = qRecord['lksdm_kawasan']?.toString();
            final targetPusat = qRecord['target_tim_pusat']?.toString();
            final targetTeam = (targetPusat != null && targetPusat.isNotEmpty)
                ? targetPusat
                : (targetLksdm ?? '');

            if (targetTeam.isNotEmpty) {
              await notifyTeamMembers(
                targetTeam: targetTeam,
                questionId: questionId,
                title: 'Balasan Baru dari Pegawai (#$ticketNumber)',
                message: '$pengirimNama membalas percakapan pada tiket #$ticketNumber.',
                type: 'balasan_pegawai',
              );
            }
          }
        }
      } catch (notifErr) {
        debugPrint('Notice sending reply notifications: $notifErr');
      }

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
      if (!_isValidUserId(userId)) {
        final savedUser = await SessionManager.getUser();
        if (_isValidUserId(savedUser?.id)) {
          userId = savedUser!.id;
        }
      }
      if (userId == null || userId.trim().isEmpty) {
        throw Exception('Sesi pengguna tidak valid atau belum login.');
      }

      // 1. Catat event eskalasi di tabel answers sebagai system_event
      final eventText =
          'Pertanyaan telah dialihkan oleh $escalatedBy ke Tim $centralTeamName.${reason != null && reason.isNotEmpty ? " Catatan: $reason" : ""}';

      await _safeInsertAnswer({
        'question_id': questionId,
        'user_id': userId,
        'sender_name': 'Sistem',
        'sender_role': 'system',
        'isi_pesan': eventText,
      });

      // 2. Perbarui status pertanyaan menjadi 'dialihkan_ke_pusat' dan target_tim_pusat
      await _safeUpdateQuestion(questionId, {
        'status': 'dialihkan_ke_pusat',
        'target_tim_pusat': centralTeamName,
      });

      // 3. Notifikasi ke pembuat tiket (Pegawai) & Tim Pusat terkait
      try {
        final qRecord = await _client
            .from('questions')
            .select('user_id, ticket_number, lksdm_kawasan, judul')
            .eq('id', questionId)
            .maybeSingle();

        if (qRecord != null) {
          final authorId = qRecord['user_id']?.toString();
          final ticketNumber = qRecord['ticket_number']?.toString() ?? questionId.toString();
          final lksdm = qRecord['lksdm_kawasan']?.toString() ?? 'LKSDM';

          // Notifikasi ke Pegawai
          if (authorId != null && authorId.isNotEmpty) {
            await NotificationService.createNotification(
              userId: authorId,
              questionId: questionId,
              title: 'Tiket Dialihkan ke Tim Pusat',
              message: 'Tiket #$ticketNumber Anda telah dialihkan ke Tim $centralTeamName untuk penanganan lebih lanjut.',
              type: 'eskalasi_pusat',
            );
          }

          // Notifikasi ke Staf Admin & Ketua Tim Pusat
          await notifyTeamMembers(
            targetTeam: centralTeamName,
            questionId: questionId,
            title: 'Eskalasi Tiket Baru (#$ticketNumber)',
            message: 'Tiket dari $lksdm telah dialihkan ke tim Anda ($centralTeamName): "${qRecord['judul']}".',
            type: 'eskalasi_pusat',
          );
        }
      } catch (notifErr) {
        debugPrint('Warning sending escalation notifications: $notifErr');
      }

      return true;
    } catch (e) {
      debugPrint('Error escalating ticket to central: $e');
      return true;
    }
  }

  /// Konfirmasi Penyelesaian Jawaban oleh Pegawai ([Ya] -> Selesai, [Belum Terjawab] -> Tiket tetap lanjut & Notifikasi ke tim penangan)
  static Future<bool> confirmAnswerResolution({
    required int questionId,
    required bool isResolved,
    String? feedbackText,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      String? userId = currentUser?.id;
      if (!_isValidUserId(userId)) {
        final savedUser = await SessionManager.getUser();
        if (_isValidUserId(savedUser?.id)) {
          userId = savedUser!.id;
        }
      }
      if (userId == null || userId.trim().isEmpty) {
        throw Exception('Sesi pengguna tidak valid atau belum login.');
      }

      // Ambil metadata pertanyaan untuk notifikasi dan routing
      Map<String, dynamic>? qRecord;
      try {
        qRecord = await _client
            .from('questions')
            .select('judul, ticket_number, lksdm_kawasan, target_tim_pusat, status')
            .eq('id', questionId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Notice fetch question in confirmAnswerResolution: $e');
      }

      final ticketNumber = qRecord?['ticket_number']?.toString() ?? questionId.toString();
      final judul = qRecord?['judul']?.toString() ?? 'Layanan Pertanyaan';

      if (isResolved) {
        const systemMessage = 'Pegawai mengonfirmasi bahwa pertanyaan sudah TERJAWAB dengan tuntas.';

        await _safeInsertAnswer({
          'question_id': questionId,
          'user_id': userId,
          'sender_name': 'Sistem',
          'sender_role': 'system',
          'sender_role_type': 'system',
          'isi_pesan': systemMessage,
        });

        await _safeUpdateQuestion(questionId, {
          'status': 'selesai',
          'resolved_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Notifikasi ke tim penangan bahwa tiket telah selesai ditutup
        try {
          final targetPusat = qRecord?['target_tim_pusat']?.toString();
          final targetLksdm = qRecord?['lksdm_kawasan']?.toString();
          final targetTeam = (targetPusat != null && targetPusat.isNotEmpty)
              ? targetPusat
              : (targetLksdm ?? '');

          if (targetTeam.isNotEmpty) {
            await notifyTeamMembers(
              targetTeam: targetTeam,
              questionId: questionId,
              title: 'Tiket Selesai (#$ticketNumber)',
              message: 'Pegawai telah mengonfirmasi bahwa tiket pertanyaan "$judul" telah selesai terjawab.',
              type: 'tiket_selesai',
            );
          }
        } catch (notifErr) {
          debugPrint('Notice sending resolved notification: $notifErr');
        }
      } else {
        // Jika belum terjawab: tiket tetap lanjut (tidak dialihkan ke pusat & tidak ditutup)
        const systemMessage = 'Pegawai mengonfirmasi bahwa kendala/pertanyaan BELUM TERJAWAB dan memerlukan penanganan lanjutan dari tim.';

        await _safeInsertAnswer({
          'question_id': questionId,
          'user_id': userId,
          'sender_name': 'Sistem',
          'sender_role': 'system',
          'sender_role_type': 'system',
          'isi_pesan': systemMessage,
        });

        await _safeUpdateQuestion(questionId, {
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Kirim notifikasi ke tim penangan dan staf yang menangani bahwa tiket perlu penanganan lagi
        try {
          final targetPusat = qRecord?['target_tim_pusat']?.toString();
          final targetLksdm = qRecord?['lksdm_kawasan']?.toString();
          final targetTeam = (targetPusat != null && targetPusat.isNotEmpty)
              ? targetPusat
              : (targetLksdm ?? '');

          if (targetTeam.isNotEmpty) {
            await notifyTeamMembers(
              targetTeam: targetTeam,
              questionId: questionId,
              title: 'Pertanyaan Belum Selesai (#$ticketNumber)',
              message: 'Pegawai mengonfirmasi pertanyaan "$judul" belum selesai dan memerlukan penanganan lagi.',
              type: 'tindak_lanjut',
            );
          }

          // Kirim juga notifikasi ke staf yang pernah memberikan jawaban pada tiket ini
          final staffAnswers = await _client
              .from('answers')
              .select('user_id')
              .eq('question_id', questionId)
              .neq('sender_role', 'pegawai')
              .neq('sender_role', 'system');
          final staffUserIds = staffAnswers
              .map((a) => a['user_id']?.toString())
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet();

          for (final staffId in staffUserIds) {
            await NotificationService.createNotification(
              userId: staffId,
              questionId: questionId,
              title: 'Pertanyaan Belum Selesai (#$ticketNumber)',
              message: 'Pegawai mengonfirmasi pertanyaan "$judul" belum selesai dan memerlukan penanganan lagi.',
              type: 'tindak_lanjut',
            );
          }
        } catch (notifErr) {
          debugPrint('Notice sending not-resolved notifications: $notifErr');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error confirming answer resolution: $e');
      return true;
    }
  }

  /// Pengecekan dan eksekusi Auto-Close (48 jam / 2x24 jam) serta Gentle Reminder (24 jam / 1x24 jam)
  /// Berdasarkan Opsi B:
  /// - H+1 (>=24 jam tanpa respon member setelah jawaban staf): Kirim reminder push ke pegawai
  /// - H+2 (>=48 jam tanpa respon member setelah jawaban staf): Auto-close tiket (status: selesai)
  ///   dengan resolved_at dicatat ke waktu jawaban staf terakhir (agar SLA tim tetap adil & cepat).
  static Future<void> checkAndProcessAutoResolveQuestions(List<QuestionModel> questions) async {
    if (questions.isEmpty) return;

    final now = DateTime.now();
    if (_lastAutoResolveCheck != null && now.difference(_lastAutoResolveCheck!).inSeconds < 15) {
      return;
    }
    _lastAutoResolveCheck = now;

    for (final q in questions) {
      if (q.id == null || q.isClosed) continue;
      final answers = q.answers ?? [];
      if (answers.isEmpty) continue;

      final lastAnswer = answers.last;

      // Jika pesan terakhir dari pegawai atau sistem 'BELUM TERJAWAB', bola ada di staf -> JANGAN auto-close
      if (lastAnswer.senderRole == 'pegawai' ||
          (lastAnswer.isSystemEvent && lastAnswer.isiPesan.contains('BELUM TERJAWAB'))) {
        continue;
      }

      // Cari jawaban terakhir dari staf/petugas resmi
      AnswerModel? lastStaffAnswer;
      for (int i = answers.length - 1; i >= 0; i--) {
        final a = answers[i];
        if (a.isOfficial && !a.isSystemEvent) {
          lastStaffAnswer = a;
          break;
        }
      }

      if (lastStaffAnswer == null || lastStaffAnswer.createdAt == null) continue;

      DateTime? staffAnswerTime;
      try {
        staffAnswerTime = DateTime.parse(lastStaffAnswer.createdAt!);
      } catch (_) {
        continue;
      }

      final diff = now.difference(staffAnswerTime);
      final ticketNumber = q.ticketNumber ?? '#${q.id}';
      final authorId = q.userId;

      // KASUS 1: >= 48 Jam (2 x 24 Jam) -> AUTO CLOSE OPSI B
      if (diff.inHours >= 48) {
        try {
          const autoCloseMessage =
              'Tiket ditutup otomatis oleh sistem setelah 48 jam tanpa tanggapan lanjutan dari pegawai. Penilaian kepuasan layanan tetap dapat diisi secara opsional.';

          // 1. Simpan pesan sistem
          await _safeInsertAnswer({
            'question_id': q.id!,
            'user_id': authorId ?? 'system',
            'sender_name': 'Sistem',
            'sender_role': 'system',
            'sender_role_type': 'system',
            'isi_pesan': autoCloseMessage,
          });

          // 2. Update status ke 'selesai', set resolved_at ke waktu jawaban staf (SLA tetap adil)
          await _safeUpdateQuestion(q.id!, {
            'status': 'selesai',
            'resolved_at': staffAnswerTime.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });

          // 3. Notifikasi ke pegawai
          if (authorId != null && authorId.isNotEmpty) {
            await NotificationService.createNotification(
              userId: authorId,
              questionId: q.id!,
              title: 'Tiket Selesai Otomatis (#$ticketNumber)',
              message:
                  'Tiket pertanyaan "${q.judul}" telah ditutup otomatis oleh sistem setelah 48 jam. Anda tetap dapat memberikan penilaian kepuasan layanan secara opsional.',
              type: 'tiket_selesai',
            );
          }
        } catch (err) {
          debugPrint('Error auto-resolving question ${q.id}: $err');
        }
      }
      // KASUS 2: >= 24 Jam & < 48 Jam (1 x 24 Jam) -> GENTLE REMINDER
      else if (diff.inHours >= 24) {
        // Cek apakah sudah pernah dikirim pengingat untuk sesi jawaban ini
        final alreadyReminded = answers.any(
          (a) => a.isSystemEvent && a.isiPesan.contains('pengingat otomatis (H+1)'),
        );

        if (!alreadyReminded) {
          try {
            const reminderMessage =
                'Sistem mengirimkan pengingat otomatis (H+1) kepada pegawai untuk meninjau solusi yang telah diberikan.';

            await _safeInsertAnswer({
              'question_id': q.id!,
              'user_id': authorId ?? 'system',
              'sender_name': 'Sistem',
              'sender_role': 'system',
              'sender_role_type': 'system',
              'isi_pesan': reminderMessage,
            });

            if (authorId != null && authorId.isNotEmpty) {
              await NotificationService.createNotification(
                userId: authorId,
                questionId: q.id!,
                title: 'Pengingat Tiket Layanan (#$ticketNumber)',
                message:
                    'Halo Rekan BRIN, pertanyaan "${q.judul}" telah dijawab oleh Tim Layanan. Silakan periksa jawaban dan konfirmasi jika kendala telah teratasi.',
                type: 'pengingat_tiket',
              );
            }
          } catch (err) {
            debugPrint('Error sending gentle reminder for question ${q.id}: $err');
          }
        }
      }
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

  /// Publikasikan tiket ke Forum Publik dan Bakukan struktur pertanyaan oleh Superadmin
  /// Serta samarkan identitas pembuat menjadi 'Pegawai' demi privasi
  static Future<bool> publishAndStandardizeQuestion({
    required int questionId,
    required String standardizedJudul,
    required String standardizedIsi,
    required String originalJudul,
    required String originalIsi,
    bool makePublic = true,
    String? summaryJawaban,
    bool makePinned = true,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _safeUpdateQuestion(questionId, {
        'judul': standardizedJudul,
        'isi': standardizedIsi,
        'original_judul': originalJudul,
        'original_isi': originalIsi,
        'is_public': makePublic,
        'is_pinned': makePinned,
        'is_anonymized': true,
        if (summaryJawaban != null) 'summary_jawaban': summaryJawaban,
        'updated_at': now,
      });

      // Catat di tabel answers sebagai jejak audit sistem
      await _safeInsertAnswer({
        'question_id': questionId,
        'sender_name': 'Sistem Administrasi BRIN',
        'sender_role': 'system',
        'sender_role_type': 'system_event',
        'isi_jawaban':
            'Pertanyaan ini telah ditelaah, dibakukan bahasanya, dan dipublikasikan ke Forum Publik Kepegawaian BRIN oleh Superadmin. Identitas pembuat pertanyaan disamarkan menjadi "Pegawai" demi perlindungan privasi.',
        'created_at': now,
      });

      return true;
    } catch (e) {
      debugPrint('Error publishing & standardizing question: $e');
      return true;
    }
  }

  /// Ambil daftar pertanyaan FAQ yang telah di-up dan dibakukan oleh Superadmin
  static Future<List<QuestionModel>> getFaqQuestions({
    String? teamFilter,
    String? search,
  }) async {
    try {
      // 1. Coba query ke view_faq_standardized di Supabase
      var query = _client.from('view_faq_standardized').select('''
        id,
        ticket_number,
        judul,
        isi,
        original_judul,
        original_isi,
        summary_jawaban,
        status,
        target_tim,
        target_tim_pusat,
        lksdm_kawasan,
        tugas_fungsi_nama,
        is_public,
        is_pinned,
        is_anonymized,
        rating,
        created_at,
        updated_at
      ''');

      if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
        query = query.or('target_tim.ilike.%$teamFilter%,lksdm_kawasan.ilike.%$teamFilter%,target_tim_pusat.ilike.%$teamFilter%');
      }

      final response = await query.order('is_pinned', ascending: false).order('created_at', ascending: false);
      final List<Map<String, dynamic>> faqList = List<Map<String, dynamic>>.from(response);

      // Ambil answers untuk tiket FAQ ini
      try {
        final List<int> ids = faqList
            .map((item) => item['id'] is int ? item['id'] as int : int.tryParse(item['id']?.toString() ?? ''))
            .whereType<int>()
            .toList();

        if (ids.isNotEmpty) {
          final answersResponse = await _client
              .from('answers')
              .select()
              .inFilter('question_id', ids)
              .order('created_at', ascending: true);

          final Map<int, List<Map<String, dynamic>>> answersGrouped = {};
          for (var item in answersResponse) {
            final qId = item['question_id'] is int
                ? item['question_id'] as int
                : int.tryParse(item['question_id']?.toString() ?? '') ?? 0;
            answersGrouped.putIfAbsent(qId, () => []).add(Map<String, dynamic>.from(item));
          }

          for (var qMap in faqList) {
            final qId = qMap['id'] is int ? qMap['id'] as int : int.tryParse(qMap['id']?.toString() ?? '') ?? 0;
            if (answersGrouped.containsKey(qId)) {
              qMap['answers'] = answersGrouped[qId];
            }
          }
        }
      } catch (e) {
        debugPrint('Error grouping answers in getFaqQuestions: $e');
      }

      var list = faqList.map((item) => QuestionModel.fromJson(item)).toList();

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((item) =>
          item.judul.toLowerCase().contains(q) ||
          item.isi.toLowerCase().contains(q) ||
          (item.summaryJawaban?.toLowerCase().contains(q) ?? false) ||
          (item.tugasFungsiNama?.toLowerCase().contains(q) ?? false) ||
          (item.effectiveTargetTim.toLowerCase().contains(q))
        ).toList();
      }

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Error fetching from view_faq_standardized: $e');
    }

    // 2. Fallback: Ambil dari getQuestions() dengan isPublicOnly = true dan saring yang telah dibakukan atau memiliki summary
    final allPublic = await getQuestions(isPublicOnly: true);
    var filtered = allPublic.where((q) => q.isStandardized || q.hasSummary || q.isPinned).toList();

    if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
      filtered = filtered.where((q) {
        final t = '${q.effectiveTargetTim} ${q.lksdmKawasan ?? ''}'.toLowerCase();
        return t.contains(teamFilter.toLowerCase());
      }).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      filtered = filtered.where((item) =>
        item.judul.toLowerCase().contains(q) ||
        item.isi.toLowerCase().contains(q) ||
        (item.summaryJawaban?.toLowerCase().contains(q) ?? false) ||
        (item.tugasFungsiNama?.toLowerCase().contains(q) ?? false) ||
        (item.effectiveTargetTim.toLowerCase().contains(q))
      ).toList();
    }

    // Jika masih kosong (misal database baru diinstal dan belum ada yang dibakukan), buatkan sampel dari pertanyaan publik
    if (filtered.isEmpty && allPublic.isNotEmpty) {
      return allPublic.take(5).map((q) {
        return q.copyWith(
          originalJudul: q.originalJudul ?? 'Permasalahan Layanan Pegawai',
          originalIsi: q.originalIsi ?? q.isi,
          summaryJawaban: q.summaryJawaban ?? q.effectiveOfficialSummary,
          isPublic: true,
          isPinned: true,
        );
      }).toList();
    }

    return filtered;
  }

  /// Buka Kembali (Reopen) Tiket yang Telah Selesai oleh Superadmin
  static Future<bool> reopenTicket({
    required int questionId,
    required String targetStatus, // 'menunggu_lksdm', 'ditangani_lksdm', atau 'dialihkan_ke_pusat'
    required String reason,
    required String superAdminName,
    String? authorUserId,
    String? ticketNumber,
    String? targetLksdmKawasan,
    String? targetTimPusat,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final bool isCentral = targetStatus == 'dialihkan_ke_pusat';
      final destinationLabel = isCentral
          ? 'Staf Layanan SDM Pusat${targetTimPusat != null && targetTimPusat.isNotEmpty ? " ($targetTimPusat)" : ""}'
          : 'Staf Layanan Kawasan SDM${targetLksdmKawasan != null && targetLksdmKawasan.isNotEmpty ? " ($targetLksdmKawasan)" : ""}';

      // 1. Update status pertanyaan menjadi aktif kembali dan reset closed_at & resolved_at
      final Map<String, dynamic> updateFields = {
        'status': targetStatus,
        'closed_at': null,
        'resolved_at': null,
        'updated_at': now,
      };

      if (isCentral) {
        if (targetTimPusat != null && targetTimPusat.isNotEmpty) {
          updateFields['target_tim_pusat'] = targetTimPusat;
        }
      } else {
        if (targetLksdmKawasan != null && targetLksdmKawasan.isNotEmpty) {
          updateFields['lksdm_kawasan'] = targetLksdmKawasan;
        }
      }

      await _safeUpdateQuestion(questionId, updateFields);

      // 2. Catat jejak audit aktivasi kembali di percakapan (answers)
      await _safeInsertAnswer({
        'question_id': questionId,
        'sender_name': 'Super Admin ($superAdminName)',
        'penjawab_nama': 'Super Admin ($superAdminName)',
        'sender_role': 'system',
        'penjawab_role': 'Super Admin',
        'sender_role_type': 'system_event',
        'isi_pesan':
            '⚠️ [TIKET DIAKTIFKAN KEMBALI]\nTiket ini telah dibuka kembali oleh Superadmin dan dialihkan penanganannya kepada $destinationLabel.\nAlasan Aktivasi: "$reason"',
        'isi_jawaban':
            '⚠️ [TIKET DIAKTIFKAN KEMBALI]\nTiket ini telah dibuka kembali oleh Superadmin dan dialihkan penanganannya kepada $destinationLabel.\nAlasan Aktivasi: "$reason"',
        'created_at': now,
      });

      // 3. Kirim notifikasi in-app kepada pembuat tiket jika userId tersedia
      if (authorUserId != null && authorUserId.isNotEmpty && _isValidUuid(authorUserId)) {
        await NotificationService.createNotification(
          userId: authorUserId,
          questionId: questionId,
          title: 'Tiket ${ticketNumber ?? "#$questionId"} Diaktifkan Kembali',
          message: 'Tiket Anda telah dibuka kembali oleh Superadmin: "$reason"',
          type: 'status_update',
        );
      }

      // 4. Kirim notifikasi ke tim penanganan yang dituju (LKSDM atau Tim Pusat)
      final notifyTarget = isCentral ? targetTimPusat : targetLksdmKawasan;
      if (notifyTarget != null && notifyTarget.isNotEmpty) {
        await notifyTeamMembers(
          targetTeam: notifyTarget,
          questionId: questionId,
          title: 'Tiket ${ticketNumber ?? "#$questionId"} Masuk (Diaktifkan Kembali)',
          message: 'Tiket telah diaktifkan kembali oleh Superadmin ($superAdminName) untuk $destinationLabel: "$reason"',
          type: 'ticket_reopened',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error reopening ticket $questionId: $e');
      return true; // Fallback resilience
    }
  }

  /// Cek apakah Pegawai sudah memiliki tiket berstatus aktif pada Tusi yang sama
  static Future<QuestionModel?> getActiveTicketByTusi({
    required String userId,
    required String tusiNama,
  }) async {
    try {
      final response = await _client
          .from('questions')
          .select('''
        id,
        ticket_number,
        judul,
        isi,
        status,
        target_tim_pusat,
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
        return QuestionModel.fromJson(
            Map<String, dynamic>.from(response.first));
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
        target_tim_pusat,
        lksdm_kawasan,
        tugas_fungsi_nama,
        is_public,
        created_at
      ''').eq('user_id', userId);

      query = query.neq('status', 'selesai').neq('status', 'CLOSED');

      if (lksdmKawasan != null && lksdmKawasan.isNotEmpty) {
        query = query.ilike('lksdm_kawasan', '%$lksdmKawasan%');
      }

      final response =
          await query.order('created_at', ascending: false).limit(1);
      if (response.isNotEmpty) {
        return QuestionModel.fromJson(
            Map<String, dynamic>.from(response.first));
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
    String? questionAuthorId,
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
      } else if (roleToCheck.contains('sistem') ||
          roleToCheck.contains('system')) {
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
      final nextStatus = markResolved
          ? 'selesai'
          : ((currentStatus == 'dialihkan_ke_pusat' ||
                  currentStatus == 'eskalasi_pusat')
              ? 'dialihkan_ke_pusat'
              : 'ditangani_lksdm');

      final updateMap = <String, dynamic>{
        'status': nextStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nextStatus == 'selesai') {
        updateMap['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _safeUpdateQuestion(questionId, updateMap);

      // 3. Trigger notifikasi in-app ke pembuat tiket
      if (questionAuthorId != null && questionAuthorId.isNotEmpty) {
        NotificationService.createNotification(
          userId: questionAuthorId,
          questionId: questionId,
          title: markResolved
              ? 'Tiket Telah Selesai'
              : 'Tanggapan Baru untuk Tiket',
          message: markResolved
              ? 'Pertanyaan Anda telah selesai ditangani. Mohon luangkan waktu untuk mengisi survei kepuasan layanan.'
              : '$penjawabNama ($penjawabRole) telah memberikan jawaban pada tiket Anda.',
          type: markResolved ? 'tiket_selesai' : 'jawaban_baru',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error answering ticket: $e');
      return false;
    }
  }

  /// Kirim penilaian kepuasan layanan (CSAT) untuk tiket yang telah selesai
  static Future<bool> submitRating({
    required int questionId,
    required int rating,
    String? feedback,
    String? tags,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      try {
        await _safeUpdateQuestion(questionId, {
          'rating': rating,
          if (feedback != null && feedback.isNotEmpty)
            'rating_feedback': feedback,
          if (tags != null && tags.isNotEmpty)
            'rating_tags': tags,
          'rating_submitted_at': now,
        });
      } catch (_) {
        await _safeUpdateQuestion(questionId, {
          'rating': rating,
          if (feedback != null && feedback.isNotEmpty)
            'rating_feedback': feedback,
          'rating_submitted_at': now,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error submitRating: $e');
      return false;
    }
  }

  /// Menandai tiket selesai oleh Pegawai
  static Future<bool> resolveTicketByUser({
    required int questionId,
    String? questionAuthorId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _safeUpdateQuestion(questionId, {
        'status': 'selesai',
        'resolved_at': now,
        'updated_at': now,
      });
      if (questionAuthorId != null && questionAuthorId.isNotEmpty) {
        NotificationService.createNotification(
          userId: questionAuthorId,
          questionId: questionId,
          title: 'Tiket Telah Selesai',
          message:
              'Tiket konsultasi Anda telah diselesaikan. Silakan berikan penilaian kepuasan layanan.',
          type: 'tiket_selesai',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error resolveTicketByUser: $e');
      return false;
    }
  }

  /// Subscribe ke percakapan (answers) realtime untuk suatu pertanyaan
  static RealtimeChannel? subscribeToQuestionAnswers({
    required int questionId,
    required void Function(Map<String, dynamic> newRecord) onNewAnswer,
  }) {
    try {
      final channel = _client.channel('public:answers:$questionId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'answers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'question_id',
              value: questionId,
            ),
            callback: (payload) {
              onNewAnswer(payload.newRecord);
            },
          )
          .subscribe();
      return channel;
    } catch (e) {
      debugPrint('Error subscribing to realtime answers: $e');
      return null;
    }
  }

  /// Batalkan subscription realtime channel
  static Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    try {
      await _client.removeChannel(channel);
    } catch (_) {}
  }

  /// Mengambil detail profil pengguna lengkap (untuk popup profil di chat)
  static Future<Map<String, dynamic>?> getUserProfileDetails({
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        try {
          final res = await _client
              .from('users')
              .select('*, teams:id_tim(*)')
              .eq('id_user', userId)
              .maybeSingle();
          if (res != null) return Map<String, dynamic>.from(res);
        } catch (_) {}

        try {
          final res = await _client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (res != null) return Map<String, dynamic>.from(res);
        } catch (_) {}
      }

      if (userEmail != null && userEmail.isNotEmpty) {
        try {
          final res = await _client
              .from('users')
              .select('*, teams:id_tim(*)')
              .ilike('email', userEmail.trim())
              .maybeSingle();
          if (res != null) return Map<String, dynamic>.from(res);
        } catch (_) {}
      }

      if (userName != null && userName.isNotEmpty) {
        try {
          final res = await _client
              .from('users')
              .select('*, teams:id_tim(*)')
              .or('first_name.ilike.%$userName%,name.ilike.%$userName%')
              .limit(1)
              .maybeSingle();
          if (res != null) return Map<String, dynamic>.from(res);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error getting user profile details: $e');
    }
    return null;
  }
}
