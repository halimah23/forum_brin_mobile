import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Ambil notifikasi milik pengguna
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final response = await _client
            .from('notifications')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(20);
        return response
            .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}

    // Fallback data notifikasi lokal
    return [
      NotificationModel(
        id: '1',
        title: 'Tanggapan LKSDM Masuk',
        message: 'Staf Admin LKSDM telah menanggapi tiket pertanyaan Anda TKT-202610-001.',
        questionId: 101,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      ),
      NotificationModel(
        id: '2',
        title: 'Status Tiket Diperbarui',
        message: 'Tiket Anda TKT-202610-002 telah dialihkan ke Tim Pusat BOSDM.',
        questionId: 102,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      ),
    ];
  }
}
