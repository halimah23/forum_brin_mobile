import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../features/questions/screens/question_detail_screen.dart';
import '../../../features/questions/services/question_service.dart';
import '../storage/session_manager.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bosdm_connect_high_importance',
    'Notifikasi Layanan BOSDM',
    description: 'Saluran notifikasi tiket dan tanggapan layanan BOSDM BRIN',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Inisialisasi plugin notifikasi lokal perangkat & Android Channel
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Registrasi High Importance Notification Channel di Android
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_channel);
      await androidImpl.requestNotificationsPermission();
    }
  }

  /// Tindakan navigasi saat user mengetuk notifikasi di bar status ponsel
  static void _handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);
      final questionIdRaw = data['question_id'];
      if (questionIdRaw != null) {
        final qId = questionIdRaw is int
            ? questionIdRaw
            : int.tryParse(questionIdRaw.toString());
        if (qId != null) {
          final question = await QuestionService.getQuestionDetail(qId);
          final user = await SessionManager.getUser();
          if (question != null && navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => QuestionDetailScreen(
                  question: question,
                  currentUser: user,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Menampilkan pop-up heads-up banner notifikasi langsung di status bar ponsel
  static Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final notifId =
          id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload != null ? jsonEncode(payload) : null,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}
