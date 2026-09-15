/// A technician the customer has saved, from `GET /api/favorites/mine`.
class Favorite {
  const Favorite({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    this.technicianPhone,
    this.category,
    this.serviceArea,
    this.rating = 0,
    this.ratingCount = 0,
    this.photoUrl,
    this.available = false,
  });

  final int id;
  final int technicianId;
  final String technicianName;
  final String? technicianPhone;
  final String? category;
  final String? serviceArea;
  final double rating;
  final int ratingCount;
  final String? photoUrl;
  final bool available;

  factory Favorite.fromJson(Map<String, dynamic> j) => Favorite(
        id: (j['id'] as num?)?.toInt() ?? 0,
        technicianId: (j['technicianId'] as num?)?.toInt() ?? 0,
        technicianName: j['technicianName']?.toString() ?? '',
        technicianPhone: j['technicianPhone']?.toString(),
        category: j['category']?.toString(),
        serviceArea: j['serviceArea']?.toString(),
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        photoUrl: j['photoUrl']?.toString(),
        available: j['available'] == true,
      );
}
