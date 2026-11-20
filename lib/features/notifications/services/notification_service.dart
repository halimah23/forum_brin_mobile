import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notifications/fcm_service.dart';
import '../../../core/services/notifications/local_notification_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static SupabaseClient get _client => Supabase.instance.client;

  static RealtimeChannel? _notificationChannel;
  static String? _activeSubscribedUserId;

  /// Notifier untuk update realtime badge lonceng di UI
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Mulai berlangganan notifikasi realtime Supabase & sinkronisasi token FCM untuk user aktif
  static void startRealtimeSubscription(String userId) {
    if (userId.isEmpty) return;

    // Sinkronisasikan token FCM perangkat ke database
    FcmService.syncTokenWithUser(userId);

    if (_activeSubscribedUserId == userId && _notificationChannel != null) {
      return;
    }
    stopRealtimeSubscription();
    _activeSubscribedUserId = userId;

    // Refresh unread count awal
    getUnreadCount(userId).then((count) {
      unreadCountNotifier.value = count;
    });

    try {
      _notificationChannel = _client
          .channel('public:notifications_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final record = payload.newRecord;
              final targetUserId = record['user_id']?.toString() ?? '';

              debugPrint(
                '>>> [REALTIME NOTIF] Event target: "$targetUserId", Active user: "$userId"',
              );

              // Validasi kecocokan target user ID (case-insensitive & trim)
              if (targetUserId.trim().toLowerCase() !=
                  userId.trim().toLowerCase()) {
                return;
              }

              final title =
                  record['title']?.toString() ?? 'Pemberitahuan Layanan';
              final message =
                  record['message']?.toString() ?? 'Terdapat informasi tiket baru.';
              final questionId = record['question_id'];

              LocalNotificationService.showNotification(
                title: title,
                body: message,
                payload: questionId != null ? {'question_id': questionId} : null,
              );

              // Update badge lonceng secara realtime
              getUnreadCount(userId).then((count) {
                unreadCountNotifier.value = count;
              });
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime notification subscription error: $e');
    }
  }

  /// Berhenti berlangganan realtime (misal saat logout)
  static void stopRealtimeSubscription() {
    if (_notificationChannel != null) {
      try {
        _client.removeChannel(_notificationChannel!);
      } catch (_) {}
      _notificationChannel = null;
      _activeSubscribedUserId = null;
    }
  }

  /// Ambil daftar seluruh notifikasi milik user dari Supabase
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
      debugPrint('Error getNotifications: $e');
      return [];
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
    } catch (e) {
      debugPrint('Error getUnreadCount: $e');
      return 0;
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
    } catch (e) {
      debugPrint('Error markAsRead: $e');
      return false;
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
    } catch (e) {
      debugPrint('Error markAllAsRead: $e');
      return false;
    }
  }

  /// Buat notifikasi baru di Supabase
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
      } catch (retryError) {
        debugPrint('Error createNotification: $retryError');
        return null;
      }
    }
  }
}
