import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'services/profile_image.dart';
import 'screens/home_screen.dart';
import 'screens/job_detail_screen.dart';
import 'screens/language_screen.dart';
import 'screens/location_picker_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load(); // restore the saved language first
  await ProfileImage.instance.load(); // restore the saved profile photo
  runApp(const CamFixTechApp());
}

class CamFixTechApp extends StatelessWidget {
  const CamFixTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole MaterialApp when the language changes so every screen
    // (including ones already on the stack) re-translates live.
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'CAM FIX Technician',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppSettings.instance.themeMode,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/language': (_) => const LanguageScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/phone-login': (_) => const PhoneLoginScreen(),
          '/otp': (_) => const OtpScreen(),
          '/pending': (_) => const PendingScreen(),
          '/home': (_) => const HomeScreen(),
          '/job': (_) => const JobDetailScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/location-picker': (_) => const LocationPickerScreen(),
        },
      ),
    );
  }
}
