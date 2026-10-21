import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Fallback in-memory jika tabel notifications belum dibuat di Supabase
  static final List<NotificationModel> _fallbackNotifications = [];

  /// Ambil daftar seluruh notifikasi milik user
  static Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(response);

      return list.map((item) => NotificationModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Fallback getNotifications: $e');
      return _fallbackNotifications
          .where((n) => n.userId == userId)
          .toList()
        ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }
  }

  /// Ambil jumlah notifikasi belum dibaca (unread count)
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (_) {
      return _fallbackNotifications
          .where((n) => n.userId == userId && !n.isRead)
          .length;
    }
  }

  /// Tandai 1 notifikasi sudah dibaca
  static Future<bool> markAsRead(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (_) {
      final idx =
          _fallbackNotifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _fallbackNotifications[idx] =
            _fallbackNotifications[idx].copyWith(isRead: true);
      }
      return true;
    }
  }

  /// Tandai seluruh notifikasi user sudah dibaca
  static Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (_) {
      for (int i = 0; i < _fallbackNotifications.length; i++) {
        if (_fallbackNotifications[i].userId == userId) {
          _fallbackNotifications[i] =
              _fallbackNotifications[i].copyWith(isRead: true);
        }
      }
      return true;
    }
  }

  /// Buat notifikasi baru
  static Future<NotificationModel?> createNotification({
    required String userId,
    int? questionId,
    required String title,
    required String message,
    String type = 'status_update',
  }) async {
    final payload = {
      'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _client
          .from('notifications')
          .insert(payload)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      try {
        final retryPayload = Map<String, dynamic>.from(payload)..remove('type');
        final res = await _client
            .from('notifications')
            .insert(retryPayload)
            .select()
            .single();
        return NotificationModel.fromJson(res);
      } catch (_) {}
      debugPrint('Fallback createNotification: $e');
      final fallbackItem = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        questionId: questionId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      _fallbackNotifications.insert(0, fallbackItem);
      return fallbackItem;
    }
  }
}
