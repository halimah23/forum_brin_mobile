import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/session_manager.dart';
import 'local_notification_service.dart';

/// Handler level atas yang dipanggil saat notifikasi FCM tiba di latar belakang (background / terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await LocalNotificationService.initialize();
  } catch (_) {}

  debugPrint('FCM background message received: ${message.messageId}');

  // Jika pesan hanya berupa data-payload (tanpa notification payload), tampilkan lewat local notification
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title']?.toString() ?? 'Pemberitahuan Layanan';
    final body = message.data['message']?.toString() ??
        message.data['body']?.toString() ??
        'Terdapat informasi tiket baru.';
    final questionId = message.data['question_id'];

    await LocalNotificationService.showNotification(
      title: title,
      body: body,
      payload: questionId != null ? {'question_id': questionId} : null,
    );
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Token FCM perangkat saat ini (dapat diakses untuk pengujian atau pengiriman)
  static String? currentToken;

  /// Inisialisasi Firebase & Firebase Cloud Messaging
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('>>> Firebase.initializeApp() BERHASIL!');
    } catch (e) {
      debugPrint(
        'Warning: Firebase.initializeApp() gagal (kemungkinan google-services.json belum terbaca): $e',
      );
      return;
    }

    try {
      // Daftarkan background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Minta izin notifikasi (Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      // Konfigurasi heads-up notification di iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1. Pesan saat aplikasi sedang aktif di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'Pemberitahuan Layanan';
        final body = message.notification?.body ??
            message.data['message']?.toString() ??
            message.data['body']?.toString() ??
            'Terdapat informasi tiket baru.';
        final payloadData = Map<String, dynamic>.from(message.data);

        LocalNotificationService.showNotification(
          title: title,
          body: body,
          payload: payloadData.isNotEmpty ? payloadData : null,
        );
      });

      // 2. Saat notifikasi di status bar diklik saat app di background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped from background: ${message.data}');
        if (message.data.isNotEmpty) {
          LocalNotificationService.handlePayloadData(message.data);
        }
      });

      // 3. Saat notifikasi diklik saat app dalam kondisi tertutup (terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        debugPrint(
          'FCM Initial message from terminated state: ${initialMessage.data}',
        );
        // Tunda sedikit agar navigatorKey sudah siap
        Future.delayed(const Duration(milliseconds: 800), () {
          LocalNotificationService.handlePayloadData(initialMessage.data);
        });
      }

      // 4. Ambil token perangkat langsung saat startup
      try {
        // ignore: deprecated_member_use
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          currentToken = token;
          debugPrint('======================================================');
          debugPrint('>>> [BERHASIL] FCM DEVICE TOKEN HP:');
          debugPrint(token);
          debugPrint('======================================================');

          // Jika user sudah memiliki sesi login aktif sebelumnya, otomatis simpan ke Supabase
          final user = await SessionManager.getUser();
          final uid = user?.id;
          if (uid != null && uid.isNotEmpty) {
            await _saveTokenToSupabase(uid, token);
          }
        }
      } catch (tokenErr) {
        debugPrint('Warning fetching initial FCM token: $tokenErr');
      }
    } catch (e) {
      debugPrint('Error configuring FCM listeners: $e');
    }
  }

  /// Sinkronisasikan FCM Token perangkat dengan database Supabase user
  static Future<void> syncTokenWithUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        currentToken = token;
        debugPrint('======================================================');
        debugPrint('>>> FCM DEVICE TOKEN UNTUK USER $userId:');
        debugPrint(token);
        debugPrint('======================================================');
        await _saveTokenToSupabase(userId, token);
      }

      // Dengarkan jika ada token refresh
      // ignore: deprecated_member_use
      _messaging.onTokenRefresh.listen((newToken) {
        currentToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        _saveTokenToSupabase(userId, newToken);
      });
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  /// Simpan atau update FCM token di tabel user_fcm_tokens di Supabase
  static Future<void> _saveTokenToSupabase(String userId, String token) async {
    try {
      final client = Supabase.instance.client;
      // Periksa apakah token sudah ada untuk user ini agar tidak terjadi bentrok duplikasi
      final existing = await client
          .from('user_fcm_tokens')
          .select('id')
          .eq('user_id', userId)
          .eq('fcm_token', token)
          .maybeSingle();

      if (existing == null) {
        await client.from('user_fcm_tokens').insert({
          'user_id': userId,
          'fcm_token': token,
          'device_type': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('>>> [SUKSES] Token FCM berhasil didaftarkan di Supabase untuk user $userId');
      } else {
        await client
            .from('user_fcm_tokens')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
        debugPrint('>>> [SUKSES] Token FCM diperbarui di Supabase untuk user $userId');
      }
    } catch (e) {
      debugPrint(
        'Catatan: Gagal simpan token ke Supabase (pastikan tabel user_fcm_tokens sudah ada): $e',
      );
    }
  }

  /// Hapus token saat logout
  static Future<void> deleteToken(String userId) async {
    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final client = Supabase.instance.client;
        await client
            .from('user_fcm_tokens')
            .delete()
            .match({'user_id': userId, 'fcm_token': token});
      }
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
