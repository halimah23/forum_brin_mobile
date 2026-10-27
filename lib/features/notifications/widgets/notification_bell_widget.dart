import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../screens/notification_screen.dart';
import '../services/notification_service.dart';

class NotificationBellWidget extends StatefulWidget {
  final UserModel user;
  final Color iconColor;

  const NotificationBellWidget({
    super.key,
    required this.user,
    this.iconColor = AppColors.slate700,
  });

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    final uid = widget.user.id?.toString();
    if (uid != null && uid.isNotEmpty) {
      NotificationService.startRealtimeSubscription(uid);
    }
    NotificationService.unreadCountNotifier.addListener(_onRealtimeCountChanged);
  }

  void _onRealtimeCountChanged() {
    if (mounted) {
      setState(() {
        _unreadCount = NotificationService.unreadCountNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    NotificationService.unreadCountNotifier.removeListener(_onRealtimeCountChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NotificationBellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      final uid = widget.user.id?.toString();
      if (uid != null && uid.isNotEmpty) {
        NotificationService.startRealtimeSubscription(uid);
      }
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    final uid = widget.user.id?.toString();
    if (uid == null || uid.isEmpty) return;

    final count = await NotificationService.getUnreadCount(uid);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _openNotificationCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(user: widget.user),
      ),
    );
    _fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            _unreadCount > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: _unreadCount > 0 ? AppColors.colorAccentWarm : widget.iconColor,
            size: 24,
          ),
          tooltip: 'Notifikasi ${_unreadCount > 0 ? "($_unreadCount baru)" : ""}',
          onPressed: _openNotificationCenter,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.colorAccentWarm,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.colorAccentWarm.withAlpha(80),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
