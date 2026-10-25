class CompletedWork {
  const CompletedWork({
    required this.id,
    required this.category,
    this.completedAt,
    this.customerUserId,
    this.customerName = '',
    this.description = '',
    this.photoUrl,
    this.address = '',
  });

  final int id;
  final String category;
  final DateTime? completedAt;
  final int? customerUserId;
  final String customerName;
  final String description;
  final String? photoUrl;
  final String address;

  factory CompletedWork.fromJson(Map<String, dynamic> json) => CompletedWork(
        id: (json['id'] as num).toInt(),
        category: json['category'] as String? ?? '',
        customerUserId: (json['customerUserId'] as num?)?.toInt(),
        customerName: (json['customerName'] as String? ?? '').trim(),
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
        description: json['description'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        address: json['address'] as String? ?? '',
      );
}
