import 'dart:async';

import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'services/connectivity_service.dart';
import 'services/profile_image.dart';
import 'theme/app_theme.dart';
import 'widgets/connectivity_banner.dart';
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/verification_code_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/create_new_password_screen.dart';
import 'screens/main_shell.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/technicians_live_screen.dart';
import 'screens/services_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/directions_map_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_thread_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/map_picker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved language / theme before the first frame so the app
  // opens in the language the user last chose.
  await AppSettings.instance.load();
  await ProfileImage.instance.load(); // restore the saved profile photo
  // Start watching Wi-Fi / mobile / no-connection state right away and verify
  // the internet is actually reachable. The splash waits on the first result;
  // every screen shows a banner while it's down (see ConnectivityBanner).
  unawaited(ConnectivityService.instance.start());
  // No Firebase: phone and email one-time codes are generated and delivered
  // by the Spring backend (`/api/auth/phone/*` and `/api/auth/email/*`), so
  // there is no reCAPTCHA / bot-check step.
  runApp(const CamFixApp());
}

class CamFixApp extends StatelessWidget {
  const CamFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'CAM FIX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppSettings.instance.themeMode,
        builder: (context, child) =>
            ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/language': (context) => const LanguageScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/phone-login': (context) => const PhoneLoginScreen(),
          '/verify-code': (context) => const VerificationCodeScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/verify-email': (context) => const VerifyEmailScreen(),
          '/new-password': (context) => const CreateNewPasswordScreen(),
          '/dashboard': (context) => const MainShell(),
          '/live-tracking': (context) => const LiveTrackingScreen(),
          '/technicians-live': (context) => const TechniciansLiveScreen(),
          '/services': (context) => const ServicesScreen(),
          '/provider': (context) => const ProviderDetailScreen(),
          '/directions': (context) => const DirectionsMapScreen(),
          '/chat': (context) => const ChatListScreen(),
          '/chat-thread': (context) => const ChatThreadScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/map-picker': (context) => const MapPickerScreen(),
        },
      ),
    );
  }
}
