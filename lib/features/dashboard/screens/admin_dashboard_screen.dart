import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../questions/screens/ask_question_screen.dart';
import '../../questions/screens/question_list_screen.dart';
import '../widgets/menu_card.dart';
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
    final teamName = user.tim ?? 'Tim Layanan BOSDM';
    const primaryColor = AppColors.primaryBlue;

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
                  const Text(
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
                      color: AppColors.lightBlueBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: primaryColor.withAlpha(80), width: 0.5),
                    ),
                    child: Text(
                      'PANEL ADMIN TIM ($teamName)',
                      style: const TextStyle(
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
            tooltip: 'Profil Admin Tim',
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
                    const Icon(
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
                            user.tim ?? user.role ?? 'Admin Tim',
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
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightBlueBackground,
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
                    'Selamat datang Admin Layanan,',
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

                  const SizedBox(height: 24),

                  const Text(
                    'Manajemen & Jawaban Tiket Layanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menu 1: Antrean Masuk Tim Saya (Menunggu Tindak Lanjut / Jawaban)
                  MenuCard(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Antrean Masuk Tim Saya',
                    subtitle: 'Tinjau & jawab pertanyaan publik baru dari pegawai',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'menunggu_disposisi',
                            isPublicOnly: true,
                            title: 'Antrean Masuk ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 2: Tiket Sedang Ditangani (Dialihkan / Disetujui Ketua Tim)
                  MenuCard(
                    icon: Icons.engineering_outlined,
                    title: 'Tiket Sedang Ditangani',
                    subtitle: 'Tiket publik yang dialihkan untuk dijawab & ditindaklanjuti',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'sedang_diproses',
                            isPublicOnly: true,
                            title: 'Sedang Ditangani ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 3: Tiket Selesai / Terjawab
                  MenuCard(
                    icon: Icons.task_alt_outlined,
                    title: 'Tiket Selesai / Terjawab',
                    subtitle: 'Lihat arsip pertanyaan yang telah tuntas dijawab',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'selesai',
                            isPublicOnly: true,
                            title: 'Tiket Selesai ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 4: Semua Forum Tanya Jawab Publik
                  MenuCard(
                    icon: Icons.forum_outlined,
                    title: 'Semua Forum Tanya Jawab',
                    subtitle: 'Lihat seluruh pertanyaan publik lintas tim di BOSDM Connect',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            isPublicOnly: true,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 5: Buat Tiket Pertanyaan Baru
                  MenuCard(
                    icon: Icons.add_circle_outline,
                    title: 'Buat Tiket Pertanyaan Baru',
                    subtitle: 'Ajukan konsultasi atau koordinasi antar tim layanan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AskQuestionScreen(
                            token: user.token ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
