import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_model.dart';
import '../../questions/screens/question_list_screen.dart';
import '../widgets/menu_card.dart';
import '../widgets/user_info_card.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
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
            const Text(
              AppConstants.appTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profil',
            onSelected: (value) {
              if (value == 'profile') {
                // Halaman profil dapat ditambahkan kemudian
              }

              if (value == 'logout') {
                // Logout handler
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
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
                        color: AppColors.primaryRed,
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
                  Icons.person,
                  color: AppColors.primaryRed,
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
              maxWidth: 430,
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Information
                  UserInfoCard(user: user),

                  const SizedBox(height: 28),

                  const Text(
                    'Menu Forum',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu Tanya Jawab
                  MenuCard(
                    icon: Icons.question_answer_outlined,
                    title: 'Tanya Jawab',
                    subtitle: 'Ajukan dan lihat pertanyaan pegawai',
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

                  // Menu Pertanyaan Saya
                  MenuCard(
                    icon: Icons.list_alt_outlined,
                    title: 'Pertanyaan Saya',
                    subtitle: 'Lihat pertanyaan yang pernah diajukan',
                    onTap: () {},
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
