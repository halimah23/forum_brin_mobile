import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../dashboard/screens/role_router_screen.dart';
import '../cubits/auth_cubit.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> logoScale;
  late Animation<double> logoOpacity;
  late Animation<double> textOpacity;
  late Animation<Offset> textSlide;

  UserModel? _existingUser;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Jalankan pengecekan sesi auth bersamaan dengan animasi splash
    final authCheck = AuthService.getCurrentUser().then((user) {
      _existingUser = user;
    }).catchError((_) {
      _existingUser = null;
    });

    await _controller.forward();
    await authCheck;

    if (!mounted) return;

    if (_existingUser != null) {
      context.read<AuthCubit>().setUser(_existingUser!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoleRouterScreen(user: _existingUser!),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background layer with curves & BRIN building graphic
          Positioned.fill(
            child: Image.asset(
              AppConstants.splashBgAssetPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top header: BRIN Logo
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                AppConstants.logoBrinTextAssetPath,
                                height: 38,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),

                          // Center Top: Splash Icon
                          FadeTransition(
                            opacity: logoOpacity,
                            child: ScaleTransition(
                              scale: logoScale,
                              child: Image.asset(
                                AppConstants.splashIconAssetPath,
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Text Content
                          FadeTransition(
                            opacity: textOpacity,
                            child: SlideTransition(
                              position: textSlide,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'BOSDM ',
                                          style: TextStyle(color: Color(0xFF0C2B59)),
                                        ),
                                        TextSpan(
                                          text: '- ',
                                          style: TextStyle(color: Color(0xFF0C2B59)),
                                        ),
                                        TextSpan(
                                          text: 'Connect',
                                          style: TextStyle(color: Color(0xFF00C49F)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'TANYA  •  DISKUSI  •  SOLUSI',
                                    style: TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Hubungkan Aspirasi,\nWujudkan Pelayanan yang Lebih Baik',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),

                          // Center Bottom: People Illustration
                          FadeTransition(
                            opacity: textOpacity,
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 280),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Image.asset(
                                AppConstants.splashPeopleAssetPath,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
