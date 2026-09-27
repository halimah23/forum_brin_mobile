import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String label;

    switch (status.toLowerCase()) {
      case 'diajukan':
        label = 'Diajukan';
        break;
      case 'diproses':
        label = 'Diproses';
        break;
      case 'dijawab':
        label = 'Dijawab';
        break;
      case 'selesai':
        label = 'Selesai';
        break;
      case 'ditolak':
        label = 'Ditolak';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightRedBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primaryRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
