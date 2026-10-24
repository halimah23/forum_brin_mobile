import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_notification_service.dart';

/// Handler level atas yang dipanggil saat notifikasi FCM tiba di latar belakang (background / terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
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

  /// Inisialisasi Firebase & Firebase Cloud Messaging
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
    } catch (e) {
      debugPrint(
        'Warning: Firebase.initializeApp() gagal (kemungkinan google-services.json belum dimasukkan): $e',
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
    } catch (e) {
      debugPrint('Error configuring FCM listeners: $e');
    }
  }

  /// Sinkronisasikan FCM Token perangkat dengan database Supabase user
  static Future<void> syncTokenWithUser(String userId) async {
    if (!_isInitialized || userId.isEmpty) return;
    try {
      _messaging.onRegistered.listen((token) {
        debugPrint('FCM Token registered: $token');
        _saveTokenToSupabase(userId, token);
      });

      await _messaging.register();

      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Device Token for user $userId: $token');
        await _saveTokenToSupabase(userId, token);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  /// Simpan atau update FCM token di tabel user_fcm_tokens di Supabase
  static Future<void> _saveTokenToSupabase(String userId, String token) async {
    try {
      final client = Supabase.instance.client;
      await client.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_type': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
      debugPrint('FCM token successfully registered in Supabase.');
    } catch (e) {
      // Fallback jika tabel user_fcm_tokens belum dibuat di Supabase
      debugPrint(
        'Catatan: Tabel user_fcm_tokens belum tersedia di Supabase atau gagal simpan token: $e',
      );
    }
  }

  /// Hapus token saat logout
  static Future<void> deleteToken(String userId) async {
    if (!_isInitialized) return;
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
      await _messaging.unregister();
    } catch (_) {}
  }
}
