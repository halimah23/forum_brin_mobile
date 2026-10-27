import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/services/notifications/local_notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/cubits/auth_cubit.dart';
import '../features/auth/screens/splash_screen.dart';

class ForumBrinApp extends StatelessWidget {
  const ForumBrinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: MaterialApp(
        navigatorKey: LocalNotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
