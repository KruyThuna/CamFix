/// The signed-in user, as returned by `GET /api/auth/me`.
class UserInfo {
  const UserInfo({
    this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phoneNumber = '',
    this.role = '',
    this.status = '',
    this.dateOfBirth,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String status;
  final String? dateOfBirth;

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        id: (j['id'] as num?)?.toInt(),
        firstName: (j['firstName'] ?? '').toString(),
        lastName: (j['lastName'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phoneNumber: (j['phoneNumber'] ?? '').toString(),
        role: (j['role'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        dateOfBirth: j['dateOfBirth']?.toString(),
      );

  /// "First Last", dropping the `-` placeholder the backend stores when a
  /// user signed up without a name.
  String get displayName {
    final parts = [firstName, lastName]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '-');
    final name = parts.join(' ').trim();
    return name.isEmpty ? (email.isEmpty ? 'CAM FIX user' : email) : name;
  }

  /// The real phone, or empty for the synthetic `email:` / `.phone.camfix.local`
  /// placeholders used for email-only accounts.
  String get realPhone =>
      phoneNumber.startsWith('email:') || phoneNumber.startsWith('google:')
          ? ''
          : phoneNumber;
}
