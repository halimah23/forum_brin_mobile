import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'menunggu_disposisi':
      case 'menunggu_approval':
      case 'pending':
        label = 'Menunggu Disposisi';
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFE65100);
        borderColor = const Color(0xFFFFB74D);
        icon = Icons.hourglass_top_rounded;
        break;
      case 'sedang_diproses':
      case 'diproses':
      case 'in_progress':
        label = 'Sedang Diproses';
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        borderColor = const Color(0xFF90CAF9);
        icon = Icons.engineering_outlined;
        break;
      case 'selesai':
      case 'dijawab':
      case 'resolved':
        label = 'Selesai';
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        borderColor = const Color(0xFFA5D6A7);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'diajukan':
        label = 'Diajukan';
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        borderColor = const Color(0xFFFFCC80);
        icon = Icons.send_outlined;
        break;
      case 'ditolak':
        label = 'Ditolak';
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        borderColor = const Color(0xFFEF9A9A);
        icon = Icons.cancel_outlined;
        break;
      default:
        label = status;
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        borderColor = const Color(0xFFE0E0E0);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
