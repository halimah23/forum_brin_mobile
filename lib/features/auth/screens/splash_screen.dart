import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController textController;

  late Animation<double> logoScale;
  late Animation<double> logoOpacity;
  late Animation<double> textOpacity;
  late Animation<Offset> textSlide;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: logoController,
        curve: Curves.easeOutBack,
      ),
    );

    logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: logoController,
        curve: Curves.easeIn,
      ),
    );

    textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: textController,
        curve: Curves.easeIn,
      ),
    );

    textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: textController,
        curve: Curves.easeOut,
      ),
    );

    startAnimation();
  }

  Future<void> startAnimation() async {
    await logoController.forward();

    await Future.delayed(
      const Duration(milliseconds: 200),
    );

    await textController.forward();

    await Future.delayed(
      const Duration(milliseconds: 1200),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    logoController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBlue,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: logoOpacity,
                child: ScaleTransition(
                  scale: logoScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Image.asset(
                      AppConstants.logoAssetPath,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: textOpacity,
                child: SlideTransition(
                  position: textSlide,
                  child: const Column(
                    children: [
                      Text(
                        AppConstants.appTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Forum & Kolaborasi\nPegawai BRIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
