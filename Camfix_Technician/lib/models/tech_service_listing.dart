/// One of the technician's own named/priced service listings
/// (`/api/technician/me/services`), with a real completed-job count computed
/// server-side from actual jobs - never a number the app makes up.
class TechServiceListing {
  const TechServiceListing({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.completedJobCount = 0,
    this.photoUrl,
  });

  final int id;
  final String title;
  final double price;

  /// Free text - one feature per line, shown as bullets to the customer.
  final String? description;
  final int completedJobCount;

  /// Relative URL of this listing's own photo, or null when none.
  final String? photoUrl;

  factory TechServiceListing.fromJson(Map<String, dynamic> j) =>
      TechServiceListing(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        description: j['description']?.toString(),
        completedJobCount: (j['completedJobCount'] as num?)?.toInt() ?? 0,
        photoUrl: j['photoUrl']?.toString(),
      );
}
