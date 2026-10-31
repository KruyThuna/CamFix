/// A promotional banner returned from `GET /api/banners`. Managed by the admin
/// console to showcase announcements, promotions, discounts, or service categories.
class AppBanner {
  const AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    this.actionUrl,
    this.imageUrl,
    this.displayOrder = 0,
    this.active = true,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? category;
  final String? actionUrl;
  final String? imageUrl;
  final int displayOrder;
  final bool active;

  factory AppBanner.fromJson(Map<String, dynamic> j) => AppBanner(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        subtitle: j['subtitle']?.toString(),
        category: j['category']?.toString(),
        actionUrl: j['actionUrl']?.toString(),
        imageUrl: j['imageUrl']?.toString(),
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
        active: j['active'] == true,
      );
}

