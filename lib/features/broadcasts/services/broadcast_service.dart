import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../notifications/services/notification_service.dart';
import '../models/broadcast_model.dart';
import '../models/broadcast_recipient_model.dart';

class BroadcastService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Fallback in-memory list jika tabel belum dimigrasikan di Supabase
  static final List<BroadcastModel> _fallbackBroadcasts = [];
  static final List<Map<String, dynamic>> _fallbackRecipients = [];

  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hexChars =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20, 32)}';
  }

  /// Mengambil daftar pegawai yang masuk dalam cakupan LKSDM pengirim
  static Future<List<UserModel>> getEligibleRecipients({
    required String lksdmScope,
    String? unitFilter,
  }) async {
    try {
      final allUsers = await UserService.getUsers();
      final normalizedScope = lksdmScope.trim().toUpperCase();

      return allUsers.where((user) {
        // Jika pengirim adalah Super Admin dengan cakupan ALL
        if (normalizedScope == 'ALL' || normalizedScope == 'SEMUA') {
          return true;
        }

        // Cek kecocokan LKSDM pengguna
        final userLksdm = user.effectiveLksdm.trim().toUpperCase();
        final matchesLksdm = userLksdm.contains(normalizedScope) ||
            normalizedScope.contains(userLksdm);

        if (!matchesLksdm) return false;

        // Jika ada filter spesifik berdasarkan Satuan Kerja / Kawasan
        if (unitFilter != null && unitFilter.trim().isNotEmpty) {
          final filter = unitFilter.trim().toLowerCase();
          final userUnit = (user.unit ?? '').toLowerCase();
          final userKawasan = (user.kawasan ?? '').toLowerCase();
          return userUnit.contains(filter) || userKawasan.contains(filter);
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error getEligibleRecipients: $e');
      return [];
    }
  }

  /// Membuat dan menyiarkan broadcast baru
  static Future<BroadcastModel?> createBroadcast({
    required UserModel sender,
    required String lksdmScope,
    required String title,
    required String content,
    String priority = 'normal',
    String targetType = 'all_lksdm',
    String? targetFilterValue,
    List<String>? selectedUserIds,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentSize,
  }) async {
    final broadcastId = _generateUuid();
    final nowStr = DateTime.now().toIso8601String();

    // 1. Tentukan target ID pegawai yang berhak menerima
    List<String> recipientUserIds = [];

    if (targetType == 'custom_users' && selectedUserIds != null) {
      recipientUserIds = selectedUserIds;
    } else {
      final eligiblePegawai = await getEligibleRecipients(
        lksdmScope: lksdmScope,
        unitFilter: targetType == 'unit_filter' ? targetFilterValue : null,
      );
      recipientUserIds = eligiblePegawai
          .map((u) => u.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }

    final broadcastData = {
      'id': broadcastId,
      'sender_id': sender.id ?? _generateUuid(),
      'sender_name': sender.name,
      'sender_role': sender.role ?? 'Admin LKSDM',
      'lksdm_scope': lksdmScope,
      'title': title,
      'content': content,
      'priority': priority,
      'target_type': targetType,
      'target_filter_value': targetFilterValue,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'created_at': nowStr,
      'updated_at': nowStr,
    };

    try {
      // 1. Simpan ke tabel broadcasts
      await _client.from('broadcasts').insert(broadcastData);

      // 2. Simpan daftar penerima ke broadcast_recipients secara batch
      if (recipientUserIds.isNotEmpty) {
        final recipientsPayload = recipientUserIds.map((userId) {
          return {
            'broadcast_id': broadcastId,
            'user_id': userId,
            'is_read': false,
            'created_at': nowStr,
          };
        }).toList();

        await _client
            .from('broadcast_recipients')
            .insert(recipientsPayload);

        // 3. Masukkan ke tabel notifications untuk setiap penerima agar lonceng berdering & FCM terpicu
        final notifPrefix = priority == 'urgent' ? '🚨 [PENTING] ' : '📢 ';
        for (final uId in recipientUserIds) {
          try {
            await NotificationService.createNotification(
              userId: uId,
              title: '$notifPrefix$title',
              message: content.length > 120
                  ? '${content.substring(0, 117)}...'
                  : content,
              type: 'broadcast',
            );
          } catch (_) {}
        }
      }

      return BroadcastModel.fromJson(
        broadcastData,
        totalRecipients: recipientUserIds.length,
        readCount: 0,
      );
    } catch (e) {
      debugPrint('Error createBroadcast via Supabase, using fallback: $e');

      // Fallback in-memory jika tabel belum tersedia
      final fallbackItem = BroadcastModel(
        id: broadcastId,
        senderId: sender.id ?? 'sender-1',
        senderName: sender.name,
        senderRole: sender.role ?? 'Admin LKSDM',
        lksdmScope: lksdmScope,
        title: title,
        content: content,
        priority: priority,
        targetType: targetType,
        targetFilterValue: targetFilterValue,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
        createdAt: nowStr,
        updatedAt: nowStr,
        totalRecipients: recipientUserIds.length,
        readCount: 0,
      );

      _fallbackBroadcasts.insert(0, fallbackItem);

      for (final uId in recipientUserIds) {
        _fallbackRecipients.add({
          'id': DateTime.now().millisecondsSinceEpoch + _fallbackRecipients.length,
          'broadcast_id': broadcastId,
          'user_id': uId,
          'is_read': false,
          'read_at': null,
          'created_at': nowStr,
        });

        NotificationService.createNotification(
          userId: uId,
          title: (priority == 'urgent' ? '🚨 [PENTING] ' : '📢 ') + title,
          message: content.length > 120 ? '${content.substring(0, 117)}...' : content,
          type: 'broadcast',
        );
      }

      return fallbackItem;
    }
  }

  /// Mengambil daftar siaran yang ditujukan untuk pegawai tertentu
  static Future<List<BroadcastModel>> getBroadcastsForUser({
    required String userId,
    required String lksdmScope,
  }) async {
    try {
      // Ambil broadcast melalui relasi recipient
      final response = await _client
          .from('broadcast_recipients')
          .select('broadcast_id, is_read, read_at, broadcasts(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawList =
          List<Map<String, dynamic>>.from(response);

      final List<BroadcastModel> result = [];
      for (final item in rawList) {
        if (item['broadcasts'] is Map) {
          final bMap = Map<String, dynamic>.from(item['broadcasts'] as Map);
          bMap['is_read'] = item['is_read'] == true;
          result.add(BroadcastModel.fromJson(bMap, isReadByMe: item['is_read'] == true));
        }
      }

      // Jika kosong (mungkin broadcast ditargetkan untuk all_lksdm tanpa entri recipient individu),
      // fallback ambil berdasarkan lksdm_scope
      if (result.isEmpty) {
        final broadRes = await _client
            .from('broadcasts')
            .select()
            .or('lksdm_scope.eq.$lksdmScope,lksdm_scope.eq.ALL')
            .order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(broadRes);
        return list.map((b) => BroadcastModel.fromJson(b)).toList();
      }

      return result;
    } catch (e) {
      debugPrint('Error getBroadcastsForUser, fallback used: $e');
      return _fallbackBroadcasts.where((b) {
        final matchesScope = b.lksdmScope == lksdmScope || b.lksdmScope == 'ALL';
        final isRecipient = _fallbackRecipients.any((r) =>
            r['broadcast_id'] == b.id && r['user_id'] == userId);
        return matchesScope || isRecipient;
      }).toList();
    }
  }

  /// Mengambil daftar siaran yang dibuat oleh Admin/Ketua Tim LKSDM tertentu
  static Future<List<BroadcastModel>> getBroadcastsCreatedBy({
    required String senderId,
    String? lksdmScope,
  }) async {
    try {
      var query = _client.from('broadcasts').select('*, broadcast_recipients(*)');
      if (lksdmScope != null && lksdmScope.isNotEmpty && lksdmScope != 'ALL') {
        query = query.eq('lksdm_scope', lksdmScope);
      } else {
        query = query.eq('sender_id', senderId);
      }

      final response = await query.order('created_at', ascending: false);
      final rawList = List<Map<String, dynamic>>.from(response);

      return rawList.map((item) {
        return BroadcastModel.fromJson(item, currentUserId: senderId);
      }).toList();
    } catch (e) {
      debugPrint('Error getBroadcastsCreatedBy, fallback used: $e');
      return _fallbackBroadcasts.where((b) {
        if (lksdmScope != null && lksdmScope != 'ALL') {
          return b.lksdmScope == lksdmScope;
        }
        return b.senderId == senderId;
      }).toList();
    }
  }

  /// Mengambil daftar penerima dan status keterbacaannya untuk 1 broadcast
  static Future<List<BroadcastRecipientModel>> getBroadcastRecipients(
      String broadcastId) async {
    try {
      final response = await _client
          .from('broadcast_recipients')
          .select('*, users:user_id(first_name, email, satuan_kerja)')
          .eq('broadcast_id', broadcastId)
          .order('created_at', ascending: true);

      final rawList = List<Map<String, dynamic>>.from(response);
      return rawList.map((r) => BroadcastRecipientModel.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error getBroadcastRecipients fallback: $e');
      final list = _fallbackRecipients
          .where((r) => r['broadcast_id'] == broadcastId)
          .map((r) => BroadcastRecipientModel.fromJson(r))
          .toList();
      return list;
    }
  }

  /// Menandai broadcast sudah dibaca oleh pegawai
  static Future<bool> markAsRead({
    required String broadcastId,
    required String userId,
  }) async {
    try {
      await _client
          .from('broadcast_recipients')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('broadcast_id', broadcastId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error markAsRead: $e');
      final idx = _fallbackRecipients.indexWhere((r) =>
          r['broadcast_id'] == broadcastId && r['user_id'] == userId);
      if (idx != -1) {
        _fallbackRecipients[idx]['is_read'] = true;
        _fallbackRecipients[idx]['read_at'] = DateTime.now().toIso8601String();
      }
      return true;
    }
  }

  /// Mengambil broadcast dengan status 'urgent' yang belum dibaca (untuk pop-up Dashboard)
  static Future<List<BroadcastModel>> getUnreadUrgentBroadcasts({
    required String userId,
    required String lksdmScope,
  }) async {
    try {
      final allUserBroadcasts = await getBroadcastsForUser(
        userId: userId,
        lksdmScope: lksdmScope,
      );

      return allUserBroadcasts.where((b) => b.isUrgent && !b.isReadByMe).toList();
    } catch (e) {
      debugPrint('Error getUnreadUrgentBroadcasts: $e');
      return [];
    }
  }

  /// Menghapus siaran broadcast
  static Future<bool> deleteBroadcast(String broadcastId) async {
    try {
      await _client.from('broadcasts').delete().eq('id', broadcastId);
      return true;
    } catch (e) {
      debugPrint('Error deleteBroadcast fallback: $e');
      _fallbackBroadcasts.removeWhere((b) => b.id == broadcastId);
      _fallbackRecipients.removeWhere((r) => r['broadcast_id'] == broadcastId);
      return true;
    }
  }
}
