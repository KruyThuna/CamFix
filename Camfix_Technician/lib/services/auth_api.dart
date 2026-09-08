import 'dart:async';

import 'api_client.dart';
import 'current_technician.dart';
import 'token_store.dart';

/// Result of requesting a phone OTP. [devCode] is only populated while the
/// backend runs with `app.otp.expose-code=true` (no SMS provider wired yet).
class OtpRequestResult {
  const OtpRequestResult({required this.message, this.devCode});
  final String message;
  final String? devCode;
}

/// Technician auth. Registration hits `/api/technician/auth/*`; password login
/// reuses the shared `/api/auth/login`. Stores the JWT via [TokenStore] on
/// success and kicks off a profile refresh.
class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  final _client = ApiClient.instance;

  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String category,
    required String serviceArea,
  }) async {
    final json = await _client.postJson('/api/technician/auth/register', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'category': category,
      'serviceArea': serviceArea,
    });
    return _storeToken(json);
  }

  Future<String> login(String email, String password) async {
    final json = await _client.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return _storeToken(json);
  }

  Future<OtpRequestResult> requestPhoneOtp(String phoneNumber) async {
    final json = await _client
        .postJson('/api/auth/phone/request-otp', {'phoneNumber': phoneNumber});
    return OtpRequestResult(
      message: (json['message'] ?? 'Code sent').toString(),
      devCode: json['devCode']?.toString(),
    );
  }

  Future<String> verifyPhoneOtp(String phoneNumber, String code) async {
    final json = await _client.postJson(
      '/api/technician/auth/phone/verify-otp',
      {'phoneNumber': phoneNumber, 'code': code},
    );
    return _storeToken(json);
  }

  Future<void> signOut() async {
    await TokenStore.instance.clear();
    _client.clearCache();
    CurrentTechnician.instance.clear();
  }

  Future<String> _storeToken(Map<String, dynamic> json) async {
    final token = (json['token'] ?? '').toString();
    if (token.isEmpty) throw ApiException(500, 'No token in response');
    _client.clearCache();
    await TokenStore.instance.save(token);
    unawaited(CurrentTechnician.instance.refresh());
    return token;
  }
}
