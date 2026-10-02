import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../questions/screens/question_list_screen.dart';
import '../widgets/bottom_action_menu.dart';
import '../widgets/trending_chart_widget.dart';
import '../widgets/user_info_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin Tim?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: primaryColor.withAlpha(80), width: 0.5),
                    ),
                    child: Text(
                      isAdminLksdm ? 'STAF ADMIN LKSDM ($lksdmName)' : 'STAF ADMIN PUSAT ($teamName)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profil Staf Admin',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isAdminLksdm ? 'Staf Admin $lksdmName' : 'Staf Admin $teamName',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withAlpha(25),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
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

                  // Admin Profile Card
                  UserInfoCard(user: user),

                  const SizedBox(height: 20),

                  // JOBDESK SCOPE CARD DARI CSV
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withAlpha(50)),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BottomActionMenu(
        items: [
          BottomMenuItem(
            label: 'Antrean',
            icon: Icons.mark_email_unread_rounded,
            color: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionListScreen(
                    user: user,
                    initialTeamFilter: isAdminLksdm ? lksdmName : teamName,
                    initialStatusFilter: isAdminLksdm ? 'menunggu_lksdm' : 'dialihkan_ke_pusat',
                    title: isAdminLksdm ? 'Antrean ($lksdmName)' : 'Antrean ($teamName)',
                  ),
                ),
              );
            },
          ),
          BottomMenuItem(
            label: 'Aktif',
            icon: Icons.chat_bubble_rounded,
            color: Colors.amber.shade900,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionListScreen(
                    user: user,
                    initialTeamFilter: isAdminLksdm ? lksdmName : teamName,
                    initialStatusFilter: 'ditangani_lksdm',
                    title: 'Percakapan Aktif ($teamName)',
                  ),
                ),
              );
            },
          ),
          BottomMenuItem(
            label: 'Selesai',
            icon: Icons.task_alt_rounded,
            color: Colors.green.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionListScreen(
                    user: user,
                    initialTeamFilter: isAdminLksdm ? lksdmName : teamName,
                    initialStatusFilter: 'selesai',
                    title: 'Tiket Selesai ($teamName)',
                  ),
                ),
              );
            },
          ),
          BottomMenuItem(
            label: 'Forum',
            icon: Icons.forum_rounded,
            color: AppColors.primaryBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionListScreen(
                    user: user,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
