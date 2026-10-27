import 'dart:async';

import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'services/api_config.dart';
import 'services/connectivity_service.dart';
import 'services/profile_image.dart';
import 'services/saved_card_store.dart';
import 'services/search_history_store.dart';
import 'theme/app_theme.dart';
import 'widgets/connectivity_banner.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/profile/language_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/auth/verification_code_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/create_new_password_screen.dart';
import 'screens/home/bottom_nav_screen.dart';
import 'screens/tracking/live_tracking_screen.dart';
import 'screens/tracking/technicians_live_screen.dart';
import 'screens/home/services_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/home/provider_detail_screen.dart';
import 'screens/tracking/directions_map_screen.dart';
import 'screens/message/chat_list_screen.dart';
import 'screens/message/chat_thread_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/booking/map_picker_screen.dart';
import 'screens/message/notifications_screen.dart';
import 'screens/tracking/booking_tracking_screen.dart';
import 'screens/profile/help_support_screen.dart';
import 'screens/profile/preference_screen.dart';
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/profile/favorites_screen.dart';
import 'screens/receipt/booking_receipt_screen.dart';
import 'screens/payment/total_spend_screen.dart';
import 'technician/main.dart' show TechnicianPortal;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved language / theme before the first frame so the app
  // opens in the language the user last chose.
  await AppSettings.instance.load();
  await ApiConfig.load(); // restore saved server endpoint
  await ProfileImage.instance.load(); // restore the saved profile photo
  await SavedCardStore.instance.load(); // restore the saved payment card
  await SearchHistoryStore.instance.load(); // restore recent search queries
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
          '/dashboard': (context) => const BottomNavScreen(),
          '/live-tracking': (context) => const LiveTrackingScreen(),
          '/technicians-live': (context) => const TechniciansLiveScreen(),
          '/services': (context) => const ServicesScreen(),
          '/search': (context) => const SearchScreen(),
          '/provider': (context) => const ProviderDetailScreen(),
          '/directions': (context) => const DirectionsMapScreen(),
          '/chat': (context) => const ChatListScreen(),
          '/chat-thread': (context) => const ChatThreadScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/map-picker': (context) => const MapPickerScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/booking-tracking': (context) => const BookingTrackingScreen(),
          '/booking-receipt': (context) => const BookingReceiptScreen(),
          '/total-spend': (context) => const TotalSpendScreen(),
          '/help-support': (context) => const HelpSupportScreen(),
          '/preference': (context) => const PreferenceScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/technician': (context) => const TechnicianPortal(),
        },
      ),
    );
  }
}
