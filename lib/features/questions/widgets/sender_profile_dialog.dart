import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../services/question_service.dart';

class SenderProfileDialog extends StatefulWidget {
  final String senderName;
  final String senderRole;
  final String? userId;
  final String? userEmail;
  final String? photoUrl;
  final String? jabatan;
  final String? unit;
  final String? lksdm;
  final bool isAnonymized;

  const SenderProfileDialog({
    super.key,
    required this.senderName,
    required this.senderRole,
    this.userId,
    this.userEmail,
    this.photoUrl,
    this.jabatan,
    this.unit,
    this.lksdm,
    this.isAnonymized = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String senderName,
    required String senderRole,
    String? userId,
    String? userEmail,
    String? photoUrl,
    String? jabatan,
    String? unit,
    String? lksdm,
    bool isAnonymized = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SenderProfileDialog(
        senderName: senderName,
        senderRole: senderRole,
        userId: userId,
        userEmail: userEmail,
        photoUrl: photoUrl,
        jabatan: jabatan,
        unit: unit,
        lksdm: lksdm,
        isAnonymized: isAnonymized,
      ),
    );
  }

  @override
  State<SenderProfileDialog> createState() => _SenderProfileDialogState();
}

class _SenderProfileDialogState extends State<SenderProfileDialog> {
  bool _isLoading = false;
  String? _loadedEmail;
  String? _loadedJabatan;
  String? _loadedUnit;
  String? _loadedLksdm;
  String? _loadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadedEmail = widget.userEmail;
    _loadedJabatan = widget.jabatan;
    _loadedUnit = widget.unit;
    _loadedLksdm = widget.lksdm;
    _loadedPhotoUrl = widget.photoUrl;

    if (!widget.isAnonymized && (_loadedJabatan == null || _loadedUnit == null || _loadedPhotoUrl == null)) {
      _fetchProfileDetails();
    }
  }

  void _fetchProfileDetails() async {
    if (widget.userId == null && widget.userEmail == null && widget.senderName.isEmpty) return;
    setState(() => _isLoading = true);

    final details = await QuestionService.getUserProfileDetails(
      userId: widget.userId,
      userEmail: widget.userEmail,
      userName: widget.senderName,
    );

    if (mounted && details != null) {
      setState(() {
        _loadedEmail ??= details['email']?.toString();
        _loadedJabatan ??= details['jabatan']?.toString();
        _loadedUnit ??= details['unit']?.toString() ?? details['satuan_kerja']?.toString();
        _loadedLksdm ??= details['kawasan']?.toString() ?? details['lksdm']?.toString() ?? details['tim']?.toString();
        _loadedPhotoUrl ??= details['photo_url']?.toString() ?? details['avatar_url']?.toString();
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _getBadgeColor() {
    final role = widget.senderRole.toLowerCase();
    if (role.contains('pusat')) {
      return Colors.amber.shade900;
    } else if (role.contains('lksdm')) {
      return Colors.teal.shade800;
    } else if (role.contains('ketua')) {
      return Colors.purple.shade800;
    } else if (role.contains('super')) {
      return const Color(0xFF512DA8);
    }
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final displayName = widget.isAnonymized ? 'Pegawai BRIN' : widget.senderName;
    final displayEmail = widget.isAnonymized ? 'Disamarkan demi privasi' : (_loadedEmail ?? '-');
    final displayJabatan = widget.isAnonymized ? 'Pegawai BRIN' : (_loadedJabatan ?? '-');
    final displayUnit = _loadedUnit ?? 'Badan Riset dan Inovasi Nasional (BRIN)';
    final displayLksdm = _loadedLksdm ?? 'LKSDM Terkait';

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto Profil Bulat Besar (WhatsApp Style)
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFCFD8DC),
                    child: ClipOval(
                      child: (!widget.isAnonymized && _loadedPhotoUrl != null && _loadedPhotoUrl!.isNotEmpty)
                          ? Image.network(
                              _loadedPhotoUrl!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Nama Pengirim
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: badgeColor.withAlpha(75), width: 0.8),
                ),
                child: Text(
                  widget.senderRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              // Informasi Detail (Jabatan, Unit, LKSDM, Email)
              _buildDetailItem(
                icon: Icons.work_outline_rounded,
                label: 'Jabatan / Posisi',
                value: displayJabatan,
              ),
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.business_rounded,
                label: 'Satuan Kerja / Unit',
                value: displayUnit,
              ),
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.location_on_outlined,
                label: 'Wilayah Kawasan LKSDM',
                value: displayLksdm,
              ),
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.email_outlined,
                label: 'Email BRIN',
                value: displayEmail,
                isPrivate: widget.isAnonymized,
              ),

              const SizedBox(height: 20),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate100,
                    foregroundColor: AppColors.slate800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isPrivate = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.slate500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrivate ? Colors.amber.shade900 : AppColors.slate800,
                  fontStyle: isPrivate ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
