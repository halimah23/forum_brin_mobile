import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';

class UserInfoCard extends StatelessWidget {
  final UserModel user;

  const UserInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          _InfoRow(
            label: 'Role',
            value: user.role ?? '-',
          ),
          _InfoRow(
            label: 'Unit',
            value: user.unit ?? '-',
          ),
          _InfoRow(
            label: 'Tim',
            value: user.tim ?? '-',
          ),
          _InfoRow(
            label: 'Jabatan',
            value: user.jabatan ?? '-',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
