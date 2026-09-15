/// A customer's star rating of a completed booking, from
/// `GET/POST /api/bookings/{id}/review`.
class Review {
  const Review({
    required this.id,
    required this.jobId,
    required this.technicianId,
    this.customerName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final int id;
  final int jobId;
  final int technicianId;
  final String? customerName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: (j['id'] as num?)?.toInt() ?? 0,
        jobId: (j['jobId'] as num?)?.toInt() ?? 0,
        technicianId: (j['technicianId'] as num?)?.toInt() ?? 0,
        customerName: j['customerName']?.toString(),
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment']?.toString(),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
      );
}
