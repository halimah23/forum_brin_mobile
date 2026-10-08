import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Konfirmasi Keluar', style: AppTypography.heading3),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?', style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthCubit>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P';
    final roleColor = _getRoleColor(user.userRole);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.slate900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Avatar & Name
                CircleAvatar(
                  radius: 40,
                  backgroundColor: roleColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.slate300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getRoleIcon(user.userRole), size: 14, color: AppColors.slate800),
                      const SizedBox(width: 6),
                      Text(
                        _getRoleTitle(user),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Detail Information Section
                _buildSectionCard(
                  title: 'Informasi Akun & Kepegawaian',
                  icon: Icons.badge_outlined,
                  iconColor: roleColor,
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      value: user.name,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email BRIN',
                      value: user.email,
                    ),
                    if (user.jabatan != null && user.jabatan!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.work_outline,
                        label: 'Jabatan',
                        value: user.jabatan!,
                      ),
                    ],
                    if (user.unit != null && user.unit!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.business_outlined,
                        label: 'Unit / Satuan Kerja',
                        value: user.unit!,
                      ),
                    ],
                    if (user.lksdm != null && user.lksdm!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'Kawasan LKSDM',
                        value: user.lksdm!,
                      ),
                    ],
                    if (user.tim != null && user.tim!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Tim Layanan SDM',
                        value: user.tim!,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Role Scope / Tupoksi Info
                _buildRoleScopeCard(user, roleColor),

                const SizedBox(height: 16),

                // App Info Card
                _buildSectionCard(
                  title: 'Tentang Aplikasi',
                  icon: Icons.info_outline,
                  iconColor: AppColors.primaryBlue,
                  children: [
                    _buildInfoRow(
                      icon: Icons.smartphone_outlined,
                      label: 'Aplikasi',
                      value: AppConstants.appTitle,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Versi System',
                      value: 'v1.0.0 (BOSDM Connect)',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Logout Action Button
                CustomButton(
                  text: 'Keluar dari Akun',
                  onPressed: () => _handleLogout(context),
                  variant: CustomButtonVariant.outlined,
                  borderColor: AppColors.error,
                  textColor: AppColors.error,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate400),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleScopeCard(UserModel user, Color roleColor) {
    String description = '';
    switch (user.userRole) {
      case UserRole.member:
        description = '• Konsultasi tiket layanan kepegawaian ke LKSDM Kawasan\n• Partisipasi diskusi di Forum Kepegawaian BRIN\n• Pemantauan riwayat status pertanyaan & tanggapan Staf';
        break;
      case UserRole.adminLksdm:
        description = '• Penanganan awal & verifikasi layanan kepegawaian kawasan (${user.effectiveLksdm})\n• Disiplin tingkat ringan-sedang & monitoring tugas belajar\n• Penanganan eskalasi percakapan tripartit ke Pusat';
        break;
      case UserRole.adminPusat:
        description = '• Penanganan eskalasi tiket tingkat pusat (${user.tim ?? "Tim Pusat"})\n• Penetapan kebijakan & pendampingan tripartit';
        break;
      case UserRole.admin:
        description = user.isAdminLksdm
            ? '• Penanganan awal & verifikasi layanan kepegawaian kawasan (${user.effectiveLksdm})\n• Disiplin tingkat ringan-sedang & monitoring tugas belajar\n• Penanganan eskalasi percakapan tripartit ke Pusat'
            : '• Penanganan eskalasi tiket tingkat pusat (${user.tim ?? "Tim Pusat"})\n• Penetapan kebijakan & pendampingan tripartit';
        break;
      case UserRole.ketuaTim:
        description = '• Manajerial & disposisi antrean pertanyaan tim (${user.tim ?? "Tim Layanan SDM"})\n• Penunjukan penanggung jawab & penyelesaian tiket';
        break;
      case UserRole.eksekutif:
        description = '• Akses monitoring agregasi statistik forum kepegawaian\n• Pemantauan isu populer & kecepatan respon penanganan tiket';
        break;
      case UserRole.superAdmin:
        description = '• Hak akses pengawasan penuh seluruh modul sistem\n• Audit trail obrolan, Bank FAQ, & manajemen akun';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_ind_outlined, size: 20, color: roleColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cakupan Peran & Wewenang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.slate800,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.member:
        return AppColors.primaryRed;
      case UserRole.adminLksdm:
        return Colors.teal.shade800;
      case UserRole.adminPusat:
        return Colors.amber.shade900;
      case UserRole.admin:
        return Colors.teal.shade800;
      case UserRole.ketuaTim:
        return Colors.teal.shade700;
      case UserRole.eksekutif:
        return const Color(0xFF283593);
      case UserRole.superAdmin:
        return const Color(0xFF512DA8);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.member:
        return Icons.person;
      case UserRole.adminLksdm:
        return Icons.business_outlined;
      case UserRole.adminPusat:
        return Icons.account_balance;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.ketuaTim:
        return Icons.supervised_user_circle;
      case UserRole.eksekutif:
        return Icons.insights;
      case UserRole.superAdmin:
        return Icons.shield;
    }
  }

  String _getRoleTitle(UserModel user) {
    switch (user.userRole) {
      case UserRole.member:
        return 'PEGAWAI BRIN';
      case UserRole.adminLksdm:
        return 'STAF ADMIN LKSDM';
      case UserRole.adminPusat:
        return 'STAF ADMIN PUSAT';
      case UserRole.admin:
        return user.isAdminLksdm ? 'STAF ADMIN LKSDM' : 'STAF ADMIN PUSAT';
      case UserRole.ketuaTim:
        return 'KETUA TIM';
      case UserRole.eksekutif:
        return 'EKSEKUTIF / PIMPINAN';
      case UserRole.superAdmin:
        return 'SUPER ADMIN';
    }
  }
}
