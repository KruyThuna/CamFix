class CompletedWork {
  const CompletedWork(
      {required this.id,
      required this.category,
      this.completedAt,
      this.customerUserId,
      this.customerName = ''});

  final int id;
  final String category;
  final DateTime? completedAt;
  final int? customerUserId;
  final String customerName;

  factory CompletedWork.fromJson(Map<String, dynamic> json) => CompletedWork(
        id: (json['id'] as num).toInt(),
        category: json['category'] as String? ?? '',
        customerUserId: (json['customerUserId'] as num?)?.toInt(),
        customerName: (json['customerName'] as String? ?? '').trim(),
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      );
}
