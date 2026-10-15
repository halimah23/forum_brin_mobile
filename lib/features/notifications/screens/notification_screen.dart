import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final UserModel? user;
  final String? userId;

  const NotificationScreen({
    super.key,
    this.user,
    this.userId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  String? get resolvedUserId {
    return widget.userId ??
        widget.user?.id?.toString() ??
        Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final uid = resolvedUserId;
    if (uid == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    final list = await NotificationService.getNotifications(uid);
    if (mounted) {
      setState(() {
        notifications = list;
        isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = resolvedUserId;
    if (uid == null) return;

    final success = await NotificationService.markAllAsRead(uid);
    if (success && mounted) {
      setState(() {
        notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai telah dibaca'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.slate800,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notif) async {
    // 1. Mark as read
    if (!notif.isRead && notif.id != null) {
      await NotificationService.markAsRead(notif.id!);
      if (mounted) {
        setState(() {
          final idx = notifications.indexWhere((n) => n.id == notif.id);
          if (idx != -1) {
            notifications[idx] = notifications[idx].copyWith(isRead: true);
          }
        });
      }
    }

    // 2. Open question detail if questionId is present
    if (notif.questionId != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );

      final question = await QuestionService.getQuestionDetail(notif.questionId!);

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
      }

      if (question != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionDetailScreen(
              question: question,
              currentUser: widget.user,
            ),
          ),
        );
        _loadNotifications();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detail tiket tidak dapat ditemukan atau telah dihapus.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'tiket_diajukan':
        return Icons.confirmation_number_outlined;
      case 'jawaban_baru':
        return Icons.reply_all_rounded;
      case 'tiket_selesai':
        return Icons.check_circle_outline_rounded;
      case 'sla_warning':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'tiket_diajukan':
        return AppColors.primaryBlue;
      case 'jawaban_baru':
        return Colors.green.shade700;
      case 'tiket_selesai':
        return Colors.teal.shade700;
      case 'sla_warning':
        return Colors.amber.shade800;
      default:
        return AppColors.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Notifikasi', style: AppTypography.heading3),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primaryRed),
              label: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.primaryRed),
                      ),
                    )
                  else if (notifications.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 44,
                              color: AppColors.slate400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Notifikasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pemberitahuan tiket baru, tanggapan, atau perubahan status akan tampil di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Row(
                        children: [
                          Text(
                            'Pemberitahuan Terbaru',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount Baru',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final typeColor = _getNotificationColor(notif.type);
                        final typeIcon = _getNotificationIcon(notif.type);
                        final formattedDate = notif.createdAt != null
                            ? notif.createdAt!.replaceAll('T', ' ').split('.').first
                            : '';

                        return InkWell(
                          onTap: () => _handleNotificationTap(notif),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: notif.isRead ? AppColors.surface : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: notif.isRead ? AppColors.border : Colors.green.shade200,
                                width: notif.isRead ? 1 : 1.2,
                              ),
                              boxShadow: notif.isRead
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.green.withAlpha(20),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: typeColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Icon(
                                    typeIcon,
                                    size: 20,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: notif.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                          ),
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryRed,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.slate700,
                                          height: 1.35,
                                        ),
                                      ),
                                      if (formattedDate.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: AppColors.slate400,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                            if (notif.questionId != null) ...[
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Buka Tiket',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: typeColor,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    size: 11,
                                                    color: typeColor,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
