import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/job_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const CamFixTechApp());

class CamFixTechApp extends StatelessWidget {
  const CamFixTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAM FIX Technician',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/phone-login': (_) => const PhoneLoginScreen(),
        '/otp': (_) => const OtpScreen(),
        '/pending': (_) => const PendingScreen(),
        '/home': (_) => const HomeScreen(),
        '/job': (_) => const JobDetailScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
