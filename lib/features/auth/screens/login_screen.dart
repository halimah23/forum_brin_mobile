import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
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
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = emailController.text.trim();
      final password = passwordController.text;
      context.read<AuthCubit>().login(email: email, password: password);
    }
  }

  void handleQuickDemoLogin(String email) {
    emailController.text = email;
    passwordController.text = 'password123';
    context.read<AuthCubit>().login(email: email, password: 'password123');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              constraints: const BoxConstraints(maxWidth: 440),
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

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Logo
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
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
                          style: AppTypography.heading1,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          AppConstants.appSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 32),

                        // Inputs
                        CustomTextField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          label: 'Email Pegawai',
                          hintText: 'nama@brin.go.id',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.email_outlined),
                          onFieldSubmitted: (_) {
                            passwordFocusNode.requestFocus();
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email harus diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          label: 'Password',
                          hintText: 'Masukkan password Anda',
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.lock_outline),
                          onFieldSubmitted: (_) {
                            handleLogin();
                          },
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password harus diisi';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        CustomButton(
                          text: 'Masuk',
                          onPressed: handleLogin,
                          isLoading: isLoading,
                          variant: CustomButtonVariant.primary,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Login SSO BRIN (Segera Hadir)',
                          onPressed: isLoading
                              ? null
                              : () {
                                  showMessage('Login SSO BRIN segera hadir.');
                                },
                          variant: CustomButtonVariant.outlined,
                          icon: const Icon(Icons.badge_outlined),
                        ),

                        const SizedBox(height: 36),

                        // Demo Roles Panel (Solid crisp design, no opacity badges)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.touch_app_outlined,
                                      size: 16,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Akses Pengujian Cepat',
                                    style: AppTypography.heading3,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pilih profil pengujian di bawah ini untuk simulasi login:',
                                style: AppTypography.caption,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildRoleTile(
                                    roleName: 'Pegawai',
                                    roleTag: 'Member',
                                    email: 'pegawai@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Staf LKSDM',
                                    roleTag: 'LKSDM',
                                    email: 'admin.lksdm1@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Staf Pusat',
                                    roleTag: 'Pusat',
                                    email: 'admin.pusat@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Ketua Tim',
                                    roleTag: 'Lead',
                                    email: 'ketuatim@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Eksekutif',
                                    roleTag: 'Exec',
                                    email: 'eksekutif@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Super Admin',
                                    roleTag: 'Admin',
                                    email: 'superadmin@brin.go.id',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Badan Riset dan Inovasi Nasional (BRIN)',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile({
    required String roleName,
    required String roleTag,
    required String email,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => handleQuickDemoLogin(email),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.slate800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleTag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                roleName,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
