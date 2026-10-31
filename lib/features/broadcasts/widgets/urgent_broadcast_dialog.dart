import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../screens/broadcast_detail_screen.dart';
import '../services/broadcast_service.dart';

class UrgentBroadcastDialog {
  static final Set<String> _dismissedSessionBroadcastIds = {};

  /// Memeriksa apakah ada broadcast 'urgent' yang belum dibaca oleh user, lalu memunculkan modal dialog
  static Future<void> checkAndShow(
    BuildContext context,
    UserModel currentUser,
  ) async {
    final userId = currentUser.id;
    if (userId == null || userId.isEmpty) return;

    try {
      final unreadUrgents = await BroadcastService.getUnreadUrgentBroadcasts(
        userId: userId,
        lksdmScope: currentUser.effectiveLksdm,
      );

      final eligible = unreadUrgents.where((b) {
        return !_dismissedSessionBroadcastIds.contains(b.id);
      }).toList();

      if (eligible.isEmpty) return;

      final broadcast = eligible.first;

      if (!context.mounted) return;

      _dismissedSessionBroadcastIds.add(broadcast.id);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pengumuman Penting LKSDM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                broadcast.title,
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dari: ${broadcast.senderName} (${broadcast.lksdmScope})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  broadcast.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
              if (broadcast.hasAttachment) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        broadcast.attachmentName ?? 'Tersedia lampiran berkas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti Saja'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BroadcastDetailScreen(
                      broadcast: broadcast,
                      currentUser: currentUser,
                    ),
                  ),
                );
              },
              child: const Text(
                'Buka Sekarang',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Check urgent broadcast error: $e');
    }
  }
}
