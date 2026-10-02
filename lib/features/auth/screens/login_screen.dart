import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../dashboard/screens/role_router_screen.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      showMessage('Email harus diisi.');
      return;
    }
    if (password.isEmpty) {
      showMessage('Password harus diisi.');
      return;
    }

    context.read<AuthCubit>().login(email: email, password: password);
  }

  void handleQuickDemoLogin(String email) {
    emailController.text = email;
    passwordController.text = 'password123';
    context.read<AuthCubit>().login(email: email, password: 'password123');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleRouterScreen(user: state.user),
                      ),
                    );
                  } else if (state is AuthError) {
                    showMessage(state.message);
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            AppConstants.logoAssetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        AppConstants.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppConstants.appSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Email Pegawai',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'nama@brin.go.id',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Masukkan password akun Anda',
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Masuk',
                        onPressed: handleLogin,
                        isLoading: isLoading,
                        backgroundColor: AppColors.primaryRed,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                showMessage('Login SSO BRIN segera hadir pada pembaruan mendatang.');
                              },
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Login dengan SSO BRIN (Segera Hadir)'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // PANEL DEMO QUICK LOGIN (5 ROLE USER)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primaryRed),
                                SizedBox(width: 8),
                                Text(
                                  'Akses Cepat Pengujian (5 Role Akun)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilih role di bawah untuk simulasi login instan:',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildRoleChip(
                                  label: '🧑‍💼 Pegawai (Member)',
                                  color: Colors.blue.shade700,
                                  onTap: () => handleQuickDemoLogin('pegawai@brin.go.id'),
                                ),
                                _buildRoleChip(
                                  label: '🛡️ Staf LKSDM',
                                  color: Colors.teal.shade800,
                                  onTap: () => handleQuickDemoLogin('admin.lksdm1@brin.go.id'),
                                ),
                                _buildRoleChip(
                                  label: '🏢 Staf Pusat',
                                  color: AppColors.primaryBlue,
                                  onTap: () => handleQuickDemoLogin('admin.pusat@brin.go.id'),
                                ),
                                _buildRoleChip(
                                  label: '👨‍💼 Ketua Tim',
                                  color: Colors.purple.shade700,
                                  onTap: () => handleQuickDemoLogin('ketuatim@brin.go.id'),
                                ),
                                _buildRoleChip(
                                  label: '👔 Eksekutif',
                                  color: const Color(0xFF283593),
                                  onTap: () => handleQuickDemoLogin('eksekutif@brin.go.id'),
                                ),
                                _buildRoleChip(
                                  label: '⚡ Super Admin',
                                  color: const Color(0xFF512DA8),
                                  onTap: () => handleQuickDemoLogin('superadmin@brin.go.id'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Badan Riset dan Inovasi Nasional (BRIN)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
