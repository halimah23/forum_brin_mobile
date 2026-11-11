import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketReadService {
  static final Map<String, int> _readCache = {};
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('ticket_read_count_'));
      for (final k in keys) {
        final val = prefs.getInt(k);
        if (val != null) {
          _readCache[k] = val;
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error init TicketReadService: $e');
    }
  }

  static String _key(int questionId, String? userId) {
    return 'ticket_read_count_${userId ?? 'anonymous'}_$questionId';
  }

  /// Menghitung berapa banyak respons / chat yang belum dibaca
  static int getUnreadCount({
    required int? questionId,
    required int totalAnswers,
    required String? userId,
  }) {
    if (questionId == null || totalAnswers <= 0) return 0;
    final k = _key(questionId, userId);
    final readCount = _readCache[k] ?? 0;
    final unread = totalAnswers - readCount;
    return unread > 0 ? unread : 0;
  }

  /// Tandai bahwa semua respons tiket saat ini sudah dibaca
  static Future<void> markAsRead({
    required int? questionId,
    required int totalAnswers,
    required String? userId,
  }) async {
    if (questionId == null) return;
    final k = _key(questionId, userId);
    _readCache[k] = totalAnswers;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(k, totalAnswers);
    } catch (e) {
      debugPrint('Error markAsRead in TicketReadService: $e');
    }
  }
}
