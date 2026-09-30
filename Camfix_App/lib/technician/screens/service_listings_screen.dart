import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/tech_service_listing.dart';
import '../services/api_client.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Lets a technician manage their own named/priced service listings - the
/// real data behind the customer app's provider-detail "Achievements" tab.
class ServiceListingsScreen extends StatefulWidget {
  const ServiceListingsScreen({super.key});

  @override
  State<ServiceListingsScreen> createState() => _ServiceListingsScreenState();
}

class _ServiceListingsScreenState extends State<ServiceListingsScreen>
    with LangAware<ServiceListingsScreen> {
  List<TechServiceListing>? _listings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final listings = await TechnicianApi.instance.myServices();
      if (mounted) setState(() => _listings = listings);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({TechServiceListing? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ServiceFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(TechServiceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('deleteServiceTitle')),
        content: Text(listing.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.t('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TechnicianApi.instance.deleteService(listing.id);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('myServices'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.t('addService')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_listings ?? const []).isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.28),
                      Icon(
                        Icons.design_services_outlined,
                        size: 46,
                        color: p.textSecondary,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            AppStrings.t('noServicesYet'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _listings!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _listingCard(_listings![i]),
                  ),
      ),
    );
  }

  final Set<int> _uploading = {};

  /// Photo shown to customers on this listing's card - tap to add/replace.
  Widget _photoTile(TechServiceListing listing) {
    final p = context.pal;
    final url = listing.photoUrl;
    return GestureDetector(
      onTap: _uploading.contains(listing.id) ? null : () => _photoMenu(listing),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: p.surfaceAlt,
              child: _uploading.contains(listing.id)
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : url != null
                      ? Image.network(
                          '${ApiClient.instance.baseUrl}$url',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.broken_image_outlined,
                            color: p.textSecondary,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 20,
                              color: p.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.t('addPhoto'),
                              style: TextStyle(
                                fontSize: 9.5,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          if (url != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _photoMenu(TechServiceListing listing) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppStrings.t('chooseFromGallery')),
              onTap: () => Navigator.pop(sheet, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppStrings.t('takePhoto')),
              onTap: () => Navigator.pop(sheet, 'camera'),
            ),
            if (listing.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  AppStrings.t('removePhoto'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(sheet, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _uploading.add(listing.id));
    try {
      if (choice == 'remove') {
        await TechnicianApi.instance.deleteServicePhoto(listing.id);
      } else {
        final file = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (file == null) return;
        await TechnicianApi.instance.uploadServicePhoto(
          listing.id,
          await file.readAsBytes(),
          filename: file.name.isNotEmpty ? file.name : 'service.jpg',
          contentType: file.mimeType ?? 'image/jpeg',
        );
      }
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading.remove(listing.id));
    }
  }

  Widget _listingCard(TechServiceListing listing) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _photoTile(listing),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${listing.price.toStringAsFixed(listing.price == listing.price.roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (listing.completedJobCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${listing.completedJobCount} ${AppStrings.t('jobsCompletedSuffix')}',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ],
                if ((listing.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    listing.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openForm(existing: listing),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _delete(listing),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  const _ServiceFormSheet({this.existing});
  final TechServiceListing? existing;

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _price = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.price.toString(),
  );
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (title.isEmpty) {
      setState(() => _error = AppStrings.t('serviceTitleRequired'));
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = AppStrings.t('servicePriceInvalid'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    try {
      final existing = widget.existing;
      if (existing == null) {
        await TechnicianApi.instance.createService(title, price, description);
      } else {
        await TechnicianApi.instance.updateService(
          existing.id,
          title,
          price,
          description,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? AppStrings.t('addService')
                : AppStrings.t('editService'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: AppStrings.t('serviceTitleLabel'),
            controller: _title,
          ),
          LabeledField(
            label: AppStrings.t('servicePriceLabel'),
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: r'$ ',
          ),
          LabeledField(
            label: AppStrings.t('serviceFeaturesLabel'),
            controller: _description,
            maxLines: 4,
            hint: AppStrings.t('serviceFeaturesHint'),
          ),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          PrimaryButton(
            label: AppStrings.t('save'),
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
