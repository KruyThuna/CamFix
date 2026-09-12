import 'dart:async';

import '../models/user_info.dart';
import 'api_client.dart';
import 'current_user.dart';
import 'token_store.dart';

/// Result of requesting a phone OTP. [devCode] is only populated while the
/// backend runs with `app.otp.expose-code=true` (no SMS provider wired yet).
class OtpRequestResult {
  const OtpRequestResult({required this.message, this.devCode});
  final String message;
  final String? devCode;
}

/// Auth calls against `/api/auth/*`. On a successful sign-in the returned JWT
/// is persisted via [TokenStore].
class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  final _client = ApiClient.instance;

  /// `POST /api/auth/login` — email + password. Stores the JWT on success.
  Future<String> login(String email, String password) async {
    final json = await _client.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return _storeToken(json);
  }

  /// `POST /api/auth/google` — exchange a Google ID token (from the real
  /// Google account picker via `google_sign_in`) for our JWT. Stores the JWT
  /// on success.
  Future<String> loginWithGoogle(String idToken) async {
    final json = await _client.postJson(
      '/api/auth/google',
      {'idToken': idToken},
    );
    return _storeToken(json);
  }

  /// `POST /api/auth/register` — email + password (name / phone optional).
  /// The backend returns a JWT immediately (auto-login).
  Future<String> register(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final json = await _client.postJson('/api/auth/register', {
      'email': email,
      'password': password,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    });
    return _storeToken(json);
  }

  Future<String> _storeToken(Map<String, dynamic> json) async {
    final token = (json['token'] ?? '').toString();
    if (token.isEmpty) throw ApiException(500, 'No token in response');
    await TokenStore.instance.save(token);
    // Pull the freshly-signed-in user's profile (fire and forget).
    unawaited(CurrentUser.instance.refresh());
    return token;
  }

  /// `GET /api/auth/me` — the signed-in user's profile.
  Future<UserInfo> me() async {
    final json = await _client.getJson('/api/auth/me');
    return UserInfo.fromJson(json);
  }

  /// `PUT /api/auth/me` — update name / phone / date of birth.
  Future<UserInfo> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? dateOfBirth,
  }) async {
    final json = await _client.putJson('/api/auth/me', {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    });
    final user = UserInfo.fromJson(json);
    CurrentUser.instance.set(user);
    return user;
  }

  /// `POST /api/auth/phone/request-otp` — sends a code by SMS to [phoneNumber].
  Future<OtpRequestResult> requestPhoneOtp(String phoneNumber) =>
      _requestOtp('/api/auth/phone/request-otp', {'phoneNumber': phoneNumber});

  /// `POST /api/auth/email/request-otp` — sends a code by email to [email].
  Future<OtpRequestResult> requestEmailOtp(String email) =>
      _requestOtp('/api/auth/email/request-otp', {'email': email});

  /// `POST /api/auth/email/verify-otp` — verifies [code]; on success stores the
  /// JWT and returns it. First verification for an address also creates the user.
  Future<String> verifyEmailOtp(String email, String code) async {
    final json = await _client.postJson(
      '/api/auth/email/verify-otp',
      {'email': email, 'code': code},
    );
    return _storeToken(json);
  }

  Future<OtpRequestResult> _requestOtp(
      String path, Map<String, dynamic> body) async {
    final json = await _client.postJson(path, body);
    return OtpRequestResult(
      message: (json['message'] ?? 'OTP sent').toString(),
      devCode: json['devCode']?.toString(),
    );
  }

  /// `POST /api/auth/phone/verify-otp` — verifies [code]; on success stores the
  /// JWT and returns it. First verification for a number also creates the user.
  Future<String> verifyPhoneOtp(String phoneNumber, String code) async {
    final json = await _client.postJson(
      '/api/auth/phone/verify-otp',
      {'phoneNumber': phoneNumber, 'code': code},
    );
    return _storeToken(json);
  }
}
