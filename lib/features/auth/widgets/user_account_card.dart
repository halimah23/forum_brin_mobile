import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class UserAccountCard extends StatelessWidget {
  final UserModel user;
  final String currentAdminId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserAccountCard({
    super.key,
    required this.user,
    required this.currentAdminId,
    required this.onEdit,
    required this.onDelete,
  });

  bool get isCurrentAdmin =>
      user.id != null && currentAdminId.isNotEmpty && user.id == currentAdminId;

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFF512DA8); // Deep Purple
      case UserRole.adminLksdm:
        return const Color(0xFF0284C7); // Sky Blue
      case UserRole.adminPusat:
        return const Color(0xFF0D9488); // Teal
      case UserRole.admin:
        return const Color(0xFF2563EB); // Royal Blue
      case UserRole.ketuaTim:
        return const Color(0xFFC2410C); // Amber / Orange
      case UserRole.eksekutif:
        return const Color(0xFF16A34A); // Green Emerald
      case UserRole.member:
        return AppColors.slate700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = user.userRole;
    final roleColor = _getRoleColor(role);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCurrentAdmin ? const Color(0xFF512DA8).withAlpha(120) : AppColors.border,
          width: isCurrentAdmin ? 1.5 : 1,
        ),
        boxShadow: isCurrentAdmin
            ? [
                BoxShadow(
                  color: const Color(0xFF512DA8).withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Avatar, Nama, Email, & Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: AppTypography.heading3.copyWith(fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF512DA8).withAlpha(20),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: const Color(0xFF512DA8), width: 0.8),
                              ),
                              child: const Text(
                                'AKUN ANDA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF512DA8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Badge Role & Jabatan
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: roleColor.withAlpha(80)),
                  ),
                  child: Text(
                    role.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                if (user.jabatan != null && user.jabatan!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      user.jabatan!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Unit Kerja & Tim Layanan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 13, color: AppColors.slate500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Unit: ${user.unit ?? "BOSDM BRIN"}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.groups_outlined, size: 13, color: AppColors.slate500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tim/Kawasan: ${user.tim ?? user.lksdm ?? "Umum"}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Baris Tombol Aksi: Edit & Hapus
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0284C7)),
                  label: const Text('Edit', style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 8),
                if (!isCurrentAdmin)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    icon: Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red.shade700),
                    label: Text('Hapus', style: TextStyle(fontSize: 11.5, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                    onPressed: onDelete,
                  )
                else
                  Tooltip(
                    message: 'Anda tidak dapat menghapus akun Anda sendiri.',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      icon: const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.slate400),
                      label: const Text('Akun Aktif', style: TextStyle(fontSize: 11.5, color: AppColors.slate400)),
                      onPressed: null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
