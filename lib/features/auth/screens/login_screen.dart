import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../dashboard/screens/dashboard_screen.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(user: state.user),
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.forum_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        AppConstants.appTitle,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppConstants.appSubtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'Masukkan email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Masukkan password',
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
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Masuk',
                        onPressed: handleLogin,
                        isLoading: isLoading,
                        backgroundColor: AppColors.darkBlue,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                showMessage('Login SSO belum diintegrasikan.');
                              },
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Login dengan SSO'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        AppConstants.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
}
