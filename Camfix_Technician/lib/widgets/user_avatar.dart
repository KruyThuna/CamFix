import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/current_technician.dart';
import '../services/profile_image.dart';
import '../theme/app_theme.dart';

/// The signed-in technician's photo, or a placeholder icon. Prefers the local
/// [ProfileImage] cache (instant, always in sync with what was just picked);
/// falls back to the backend copy (`CurrentTechnician.photoUrl`) so a fresh
/// browser/device with no local cache still shows it. Rebuilds when either
/// source changes.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.radius = 22,
    this.bgColor,
    this.iconColor = AppColors.primaryBlue,
  });

  final double radius;
  final Color? bgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? context.pal.surfaceAlt;
    return AnimatedBuilder(
      animation: Listenable.merge([ProfileImage.instance, CurrentTechnician.instance]),
      builder: (context, _) {
        final img = ProfileImage.instance;
        final photoUrl = CurrentTechnician.instance.value?.photoUrl;
        ImageProvider? provider;
        if (img.hasImage) {
          provider = MemoryImage(img.bytes!);
        } else if (photoUrl != null && photoUrl.isNotEmpty) {
          provider = NetworkImage('${ApiClient.instance.baseUrl}$photoUrl');
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: provider,
          child: provider == null
              ? Icon(Icons.person, size: radius * 0.95, color: iconColor)
              : null,
        );
      },
    );
  }
}

/// Bottom sheet to take / choose / remove the profile photo.
Future<void> pickProfilePhoto(BuildContext context) {
  final p = context.pal;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
            leading: Icon(icon, color: AppColors.primaryBlue),
            title: Text(label,
                style: TextStyle(color: p.textPrimary, fontSize: 15)),
            onTap: onTap,
          );
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            tile(Icons.photo_camera_outlined, AppStrings.t('takePhoto'), () {
              Navigator.of(sheetContext).pop();
              ProfileImage.instance.pickAndSet(ImageSource.camera);
            }),
            tile(Icons.photo_library_outlined,
                AppStrings.t('chooseFromGallery'), () {
              Navigator.of(sheetContext).pop();
              ProfileImage.instance.pickAndSet(ImageSource.gallery);
            }),
            if (ProfileImage.instance.hasImage)
              tile(Icons.delete_outline, AppStrings.t('removePhoto'), () {
                Navigator.of(sheetContext).pop();
                ProfileImage.instance.clear();
              }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
