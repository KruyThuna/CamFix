import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../services/api_client.dart';
import '../services/current_technician.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// One-time onboarding step where a technician posts a promotional banner
/// (with an optional headline) shown to customers in the app's home
/// carousel. Reachable again later from the home screen's "Get started"
/// prompt as long as no banner is set, so it isn't a one-shot dead end.
class GetStartedBannerScreen extends StatefulWidget {
  const GetStartedBannerScreen({super.key});

  @override
  State<GetStartedBannerScreen> createState() => _GetStartedBannerScreenState();
}

class _GetStartedBannerScreenState extends State<GetStartedBannerScreen>
    with LangAware<GetStartedBannerScreen> {
  final _picker = ImagePicker();
  final _title = TextEditingController();
  Uint8List? _image;
  String? _imageName;
  String? _imageMime;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title.text = CurrentTechnician.instance.value?.bannerTitle ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _image = bytes;
      _imageName = file.name.isNotEmpty ? file.name : 'banner.jpg';
      _imageMime = file.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _submit() async {
    final image = _image;
    if (image == null) {
      showError(context, AppStrings.t('bannerImageRequired'));
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await TechnicianApi.instance.uploadBanner(
        image,
        filename: _imageName ?? 'banner.jpg',
        contentType: _imageMime ?? 'image/jpeg',
        title: _title.text.trim(),
      );
      CurrentTechnician.instance.set(updated);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeExisting() async {
    setState(() => _busy = true);
    try {
      final updated = await TechnicianApi.instance.deleteBanner();
      CurrentTechnician.instance.set(updated);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final existingBannerUrl = CurrentTechnician.instance.value?.bannerUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('getStartedBannerTitle')),
        actions: const [LanguageToggle()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.t('getStartedBannerIntro'),
              style: TextStyle(color: p.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: p.surfaceAlt,
                  child: _image != null
                      ? Image.memory(_image!, fit: BoxFit.cover)
                      : existingBannerUrl != null
                          ? Image.network(
                              '${ApiClient.instance.baseUrl}$existingBannerUrl',
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(Icons.image_outlined,
                                  size: 48, color: p.textSecondary),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(AppStrings.t('takePhoto')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(AppStrings.t('chooseFromGallery')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: AppStrings.t('bannerHeadlineLabel'),
              controller: _title,
              hint: AppStrings.t('bannerHeadlineHint'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: AppStrings.t('postBanner'),
              busy: _busy,
              onPressed: _submit,
            ),
            if (existingBannerUrl != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _removeExisting,
                  child: Text(AppStrings.t('removeBanner'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
