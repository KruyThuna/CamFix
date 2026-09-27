/// One of a technician's own named/priced service listings
/// (`GET /api/technicians/{id}/services`), with a real completed-job count -
/// not a fabricated per-service stat.
class TechnicianServiceListing {
  const TechnicianServiceListing({
    required this.id,
    required this.technicianId,
    required this.title,
    required this.price,
    this.description,
    this.completedJobCount = 0,
    this.photoUrl,
  });

  final int id;
  final int technicianId;
  final String title;
  final double price;

  /// Free text the technician wrote themselves - one feature per line, shown
  /// as bullet points. Null when they haven't added any.
  final String? description;
  final int completedJobCount;

  /// Relative URL of the photo the technician attached to this listing,
  /// or null when they have not added one.
  final String? photoUrl;

  /// [description] split into individual bullet lines, empty when unset.
  List<String> get features => description == null
      ? const []
      : description!
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  factory TechnicianServiceListing.fromJson(Map<String, dynamic> j) =>
      TechnicianServiceListing(
        id: (j['id'] as num?)?.toInt() ?? 0,
        technicianId: (j['technicianId'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        description: j['description']?.toString(),
        completedJobCount: (j['completedJobCount'] as num?)?.toInt() ?? 0,
        photoUrl: j['photoUrl']?.toString(),
      );
}
