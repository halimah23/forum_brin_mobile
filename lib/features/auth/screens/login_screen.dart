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
    passwordController.text = 'Password123!';
    context.read<AuthCubit>().login(email: email, password: 'Password123!');
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
                          label: 'Email Pegawai / Username',
                          hintText: 'nama@brin.go.id atau username',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.person_outline),
                          onFieldSubmitted: (_) {
                            passwordFocusNode.requestFocus();
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email atau username harus diisi';
                            }
                            final val = value.trim();
                            if (val.length < 3) {
                              return 'Minimal 3 karakter';
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
                                  const Expanded(
                                    child: Text(
                                      'Akses Pengujian Cepat (Database Supabase)',
                                      style: AppTypography.heading3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pilih akun resmi dari basis data Supabase di bawah ini untuk masuk cepat:',
                                style: AppTypography.caption,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildRoleTile(
                                    roleName: 'Manda Talita TH (Member LK1)',
                                    roleTag: 'Member',
                                    email: 'manda.talita.taruli.hasibuan.@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Lutvia R. (Ketua LKSDM 1)',
                                    roleTag: 'Ketua LKSDM',
                                    email: 'lutvia.restu.putriana@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Faris Setya AH (Admin LKSDM 1)',
                                    roleTag: 'Admin LKSDM',
                                    email: 'faris.setya.aqil.humam@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Raisya QN (Ketua PDIS)',
                                    roleTag: 'Ketua Pusat',
                                    email: 'raisya.qianisa.nabilla@brin.go.id',
                                  ),                                  
                                  _buildRoleTile(
                                    roleName: 'Abid Omar Tusta (Admin PDIS)',
                                    roleTag: 'Admin Pusat',
                                    email: 'abid.omar.tusta@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Rizka FL (Member LK6)',
                                    roleTag: 'Member',
                                    email: 'rizka.fazri.lestari@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Redho H. Fatah (Ketua LKSDM 6)',
                                    roleTag: 'Ketua LKSDM',
                                    email: 'redho.hasyrahim.fatah@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Maria Fernanda DV (Admin LKSDM 6)',
                                    roleTag: 'Admin LKSDM',
                                    email: 'maria.fernanda.de.vega@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Rizka A.R (Ketua ORTALA)',
                                    roleTag: 'Ketua Pusat',
                                    email: 'rizka.amelia.rahmadhani@brin.go.id',
                                  ),                                  
                                  _buildRoleTile(
                                    roleName: 'Merlina M. (Admin ORTALA)',
                                    roleTag: 'Admin Pusat',
                                    email: 'merlina.meiriyanti@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Haliza FA (Member LK3)',
                                    roleTag: 'Member',
                                    email: 'haliza.fawwaz.ayuningtyas@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Tri Gunawan (Ketua LKSDM 3)',
                                    roleTag: 'Ketua LKSDM',
                                    email: 'tri.gunawan.musa@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Najwa KS (Admin LKSDM 3)',
                                    roleTag: 'Admin LKSDM',
                                    email: 'najwa.khairana.sulistyoningsih@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Renatha IR (Ketua PENKOM)',
                                    roleTag: 'Ketua Pusat',
                                    email: 'renatha.indah.riski@brin.go.id',
                                  ),                                  
                                  _buildRoleTile(
                                    roleName: 'Zaidan ND (Admin PENKOM)',
                                    roleTag: 'Admin Pusat',
                                    email: 'zaidan.nabil.diwangkara@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Aisyah F. (Super Admin)',
                                    roleTag: 'Super Admin',
                                    email: 'aisyah.febrianti.kusmiandini@brin.go.id',
                                  ),
                                  _buildRoleTile(
                                    roleName: 'Siti Halimah (Eksekutif)',
                                    roleTag: 'Eksekutif',
                                    email: 'siti.halimah@brin.go.id',
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
              Flexible(
                child: Text(
                  roleName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
