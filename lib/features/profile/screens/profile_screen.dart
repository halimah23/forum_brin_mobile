import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/storage/session_manager.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel currentUser;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUserData();
  }

  void _refreshUserData() async {
    final saved = await SessionManager.getUser();
    if (saved != null && mounted) {
      setState(() {
        currentUser = saved;
      });
    }
  }

  Future<void> _pickAndChangeProfilePhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      // Batasan ukuran maksimum 10 MB
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran foto melebihi batas maksimal 10 MB.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return;

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PhotoRepositionDialog(
          imageBytes: bytes,
          fileName: file.name,
        ),
      );

      if (confirmed == true && mounted) {
        setState(() => _isUploadingPhoto = true);
        String? publicUrl;

        try {
          final client = Supabase.instance.client;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final storagePath = 'profiles/${currentUser.id ?? "usr"}_${timestamp}_$safeName';

          await client.storage.from('attachments').uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          publicUrl = client.storage.from('attachments').getPublicUrl(storagePath);
        } catch (uploadErr) {
          debugPrint('Upload profile photo fallback: $uploadErr');
          publicUrl = file.path ?? 'storage://local_profile/${file.name}';
        }

        final userId = currentUser.id;
        if (userId != null) {
          await UserService.updateProfilePhoto(userId: userId, photoUrl: publicUrl);
        }

        final updatedUser = currentUser.copyWith(photoUrl: publicUrl);
        await SessionManager.saveUser(updatedUser);

        if (mounted) {
          setState(() {
            currentUser = updatedUser;
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile photo: $e');
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

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
    final roleColor = _getRoleColor(currentUser.userRole);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.slate900,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Avatar & Name (WhatsApp Style Circular Profile Photo)
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFFCFD8DC),
                      child: ClipOval(
                        child: (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty)
                            ? Image.network(
                                currentUser.photoUrl!,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUploadingPhoto ? null : _pickAndChangeProfilePhoto,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentUser.name,
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

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
                      Icon(_getRoleIcon(currentUser.userRole), size: 14, color: AppColors.slate800),
                      const SizedBox(width: 6),
                      Text(
                        _getRoleTitle(currentUser),
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
                      value: currentUser.name,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email BRIN',
                      value: currentUser.email,
                    ),
                    if (currentUser.jabatan != null && currentUser.jabatan!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.work_outline,
                        label: 'Jabatan',
                        value: currentUser.jabatan!,
                      ),
                    ],
                    if (currentUser.unit != null && currentUser.unit!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.business_outlined,
                        label: 'Unit / Satuan Kerja',
                        value: currentUser.unit!,
                      ),
                    ],
                    if (currentUser.effectiveLksdm.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Kawasan LKSDM',
                        value: currentUser.effectiveLksdm,
                      ),
                    ],
                    if (currentUser.tim != null && currentUser.tim!.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildInfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Tim Kerja Layanan',
                        value: currentUser.tim!,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Role Scope & Permissions
                _buildRoleScopeCard(currentUser, roleColor),

                const SizedBox(height: 24),

                // Tombol Keluar Akun
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
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
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        description = '• Konsultasi tiket layanan kepegawaian ke LKSDM Kawasan\n• Pengajuan & pelacakan tiket layanan mandiri\n• Pemantauan riwayat status pertanyaan & tanggapan Staf';
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
        description = '• Fungsi Utama: Monitoring\n'
            '• Hak Akses Utama:\n'
            '  - Melihat Dashboard & Statistik Real-Time\n'
            '  - Memantau Pertanyaan, Jawaban & Diskusi\n'
            '  - Memantau Status Penanganan & Alur Eskalasi Tiket (Read-Only)';
        break;
      case UserRole.superAdmin:
        description = '• Fungsi Utama: Administrasi & monitoring sistem\n• Mengelola master data & hak akses pengguna\n• Memonitor sistem & melihat statistik performa\n• Mengelola pertanyaan populer & Bank FAQ';
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

/// Dialog Penyesuaian Posisi & Zoom Foto Profil Bergaya WhatsApp
class _PhotoRepositionDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String fileName;

  const _PhotoRepositionDialog({
    required this.imageBytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xEB000000),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Atur Posisi Foto Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Viewport Lingkaran Potong Interaktif
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: 240,
                      height: 240,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: Colors.white70),
                  SizedBox(width: 6),
                  Text(
                    'Geser & cubit layar untuk menyesuaikan posisi',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Gunakan Foto Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
