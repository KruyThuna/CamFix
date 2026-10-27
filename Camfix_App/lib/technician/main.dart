import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'services/profile_image.dart';
import 'screens/get_started_banner_screen.dart';
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
import 'screens/service_listings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/job_chat_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load(); // restore the saved language first
  await ProfileImage.instance.load(); // restore the saved profile photo
  runApp(const CamFixTechApp());
}

/// Hosts the complete technician experience inside the unified customer app.
/// Technician preferences and authentication use their existing `tech_*`
/// storage keys, so switching roles does not overwrite the customer session.
class TechnicianPortal extends StatefulWidget {
  const TechnicianPortal({super.key});

  @override
  State<TechnicianPortal> createState() => _TechnicianPortalState();
}

class _TechnicianPortalState extends State<TechnicianPortal> {
  late final Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    await AppSettings.instance.load();
    await ProfileImage.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const CamFixTechApp();
      },
    );
  }
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
          '/get-started-banner': (_) => const GetStartedBannerScreen(),
          '/job': (_) => const JobDetailScreen(),
          '/job-chat': (_) => const JobChatScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/service-listings': (_) => const ServiceListingsScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/location-picker': (_) => const LocationPickerScreen(),
        },
      ),
    );
  }
}
