import '../app_settings.dart';

/// One in-app notification, from `GET /api/notifications/mine`. Carries both
/// languages; [localizedTitle] / [localizedMessage] pick by the app language
/// (Khmer falls back to English when the `*Km` field is empty).
class AppNotification {
  const AppNotification({
    required this.id,
    this.type = '',
    this.jobId,
    this.title = '',
    this.message = '',
    this.titleKm,
    this.messageKm,
    this.read = false,
    this.createdAt,
  });

  final int id;
  final String type; // BOOKING_REQUESTED | JOB_ASSIGNED | JOB_IN_PROGRESS | ...
  final int? jobId;
  final String title;
  final String message;
  final String? titleKm;
  final String? messageKm;
  final bool read;
  final DateTime? createdAt;

  bool get _km => AppSettings.instance.lang == AppLang.km;

  String get localizedTitle =>
      _km && (titleKm?.isNotEmpty ?? false) ? titleKm! : title;
  String get localizedMessage =>
      _km && (messageKm?.isNotEmpty ?? false) ? messageKm! : message;

  AppNotification markRead() => AppNotification(
        id: id,
        type: type,
        jobId: jobId,
        title: title,
        message: message,
        titleKm: titleKm,
        messageKm: messageKm,
        read: true,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        type: (j['type'] ?? '').toString(),
        jobId: (j['jobId'] as num?)?.toInt(),
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        titleKm: j['titleKm']?.toString(),
        messageKm: j['messageKm']?.toString(),
        read: j['read'] == true,
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
      );
}
