/// The signed-in technician, from `GET /api/technician/me`.
class TechnicianProfile {
  const TechnicianProfile({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phoneNumber = '',
    this.category = '',
    this.serviceArea = '',
    this.about,
    this.openingHours,
    this.rating = 0,
    this.ratingCount = 0,
    this.approvalStatus = 'PENDING',
    this.accountStatus = 'ACTIVE',
    this.available = false,
    this.lastLat,
    this.lastLng,
    this.rejectionReason,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String category;
  final String serviceArea;
  final String? about;
  final String? openingHours;
  final double rating;
  final int ratingCount;
  final String approvalStatus; // PENDING | APPROVED | REJECTED
  final String accountStatus; // ACTIVE | SUSPENDED
  final bool available;
  final double? lastLat;
  final double? lastLng;
  final String? rejectionReason;

  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isRejected => approvalStatus == 'REJECTED';
  bool get isSuspended => accountStatus == 'SUSPENDED';
  bool get isOperational => isApproved && !isSuspended;

  String get displayName {
    final n = [firstName, lastName]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '-')
        .join(' ')
        .trim();
    return n.isEmpty ? (email.isEmpty ? 'Technician' : email) : n;
  }

  factory TechnicianProfile.fromJson(Map<String, dynamic> j) => TechnicianProfile(
        id: (j['id'] as num?)?.toInt() ?? 0,
        firstName: (j['firstName'] ?? '').toString(),
        lastName: (j['lastName'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phoneNumber: (j['phoneNumber'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        serviceArea: (j['serviceArea'] ?? '').toString(),
        about: j['about']?.toString(),
        openingHours: j['openingHours']?.toString(),
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        approvalStatus: (j['approvalStatus'] ?? 'PENDING').toString(),
        accountStatus: (j['accountStatus'] ?? 'ACTIVE').toString(),
        available: j['available'] == true,
        lastLat: (j['lastLat'] as num?)?.toDouble(),
        lastLng: (j['lastLng'] as num?)?.toDouble(),
        rejectionReason: j['rejectionReason']?.toString(),
      );
}

/// The six service categories the backend accepts (see ServiceCategories.java).
const kServiceCategories = <String>[
  'Air Conditioner',
  'Electrical',
  'Appliance Repair',
  'Motorcycle',
  'Car',
  'Water network',
];
