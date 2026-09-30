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

class KetuaTimDashboardScreen extends StatelessWidget {
  final UserModel user;

  const KetuaTimDashboardScreen({
    super.key,
    required this.user,
  });

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Ketua Tim?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
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
    final primaryTeal = Colors.teal.shade800;
    final teamName = user.tim ?? 'Tim Layanan SDM BOSDM';

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
                      color: primaryTeal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: primaryTeal, width: 0.5),
                    ),
                    child: Text(
                      'PANEL KETUA TIM ($teamName)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
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
            tooltip: 'Profil Ketua Tim',
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
                      Icons.supervised_user_circle,
                      color: primaryTeal,
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
                            user.tim ?? 'Ketua Tim',
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
                backgroundColor: Colors.teal.shade50,
                child: Icon(
                  Icons.assignment_ind,
                  color: primaryTeal,
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
                    'Selamat datang,',
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

                  // User Info Card
                  UserInfoCard(user: user),

                  const SizedBox(height: 24),

                  const Text(
                    'Manajemen & Supervisi Antrean Tiket',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menu 1: Tiket Konsultasi Privat (Khusus Dijawab Ketua Tim)
                  MenuCard(
                    icon: Icons.lock_outline,
                    title: 'Tiket Konsultasi Privat (Jawab Langsung)',
                    subtitle: 'Pertanyaan rahasia pegawai yang wajib dijawab langsung oleh Ketua Tim',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            isPrivateOnly: true,
                            title: 'Tiket Privat ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 2: Antrean Masuk Publik (Perlu Disposisi / Alihkan ke Admin)
                  MenuCard(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Antrean Masuk Publik (Alihkan ke Admin)',
                    subtitle: 'Tinjau & alihkan ke Admin Tim atau jawab langsung',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'menunggu_disposisi',
                            isPublicOnly: true,
                            title: 'Antrean Masuk Publik ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 3: Tiket Sedang Ditangani Admin/Staf
                  MenuCard(
                    icon: Icons.engineering_outlined,
                    title: 'Tiket Sedang Ditangani Admin/Staf',
                    subtitle: 'Pantau tiket yang sedang diproses oleh Admin Tim',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'sedang_diproses',
                            title: 'Sedang Ditangani ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 4: Seluruh Tiket Selesai
                  MenuCard(
                    icon: Icons.task_alt_outlined,
                    title: 'Tiket Selesai / Terjawab',
                    subtitle: 'Lihat arsip pertanyaan yang telah selesai ditangani',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionListScreen(
                            user: user,
                            initialTeamFilter: user.tim,
                            initialStatusFilter: 'selesai',
                            title: 'Tiket Selesai ($teamName)',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 5: Semua Forum Tanya Jawab
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
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 6: Buat Tiket Pertanyaan
                  MenuCard(
                    icon: Icons.add_circle_outline,
                    title: 'Buat Tiket Pertanyaan Baru',
                    subtitle: 'Ajukan konsultasi atau koordinasi antar tim',
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
