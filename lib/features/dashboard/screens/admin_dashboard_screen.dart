import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_model.dart';
import '../widgets/trending_chart_widget.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isAdminLksdm = user.isAdminLksdm;
    final lksdmName = user.effectiveLksdm;
    final teamName = user.tim ?? (isAdminLksdm ? lksdmName : 'Fungsi Pengelolaan data dan informasi SDM');
    final primaryColor = isAdminLksdm ? Colors.teal.shade800 : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAssetPath,
              height: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: Text(
                      isAdminLksdm ? 'STAF ADMIN LKSDM ($lksdmName)' : 'STAF ADMIN PUSAT ($teamName)',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    isAdminLksdm ? 'Selamat datang Staf Admin Kawasan,' : 'Selamat datang Staf Admin Pusat,',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // JOBDESK SCOPE CARD DARI CSV
                  Container(
                    padding: const EdgeInsets.all(14),
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
                            Icon(isAdminLksdm ? Icons.location_city : Icons.account_tree, color: primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAdminLksdm ? 'Cakupan Tugas & Fungsi $lksdmName' : 'Cakupan Tugas & Fungsi $teamName',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdminLksdm
                              ? '• Penegakan hukuman disiplin ringan-sedang\n• Fasilitasi Kenaikan Gaji Berkala (KGB)\n• Monitoring Tugas Belajar & Kehadiran Pegawai Kawasan\n• Layanan kepegawaian kawasan & verifikasi layanan pusat'
                              : '• Penanganan eskalasi sesuai tupoksi $teamName\n• Penilaian & penetapan kebijakan tingkat pusat\n• Pendampingan percakapan tripartit (Pegawai + LKSDM + Tim Pusat)',
                          style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                  const TrendingChartWidget(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
