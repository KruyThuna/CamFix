import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/service_quote.dart';
import '../models/tech_job.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'quote_form_sheet.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with LangAware<JobDetailScreen> {
  TechJob? _job;
  bool _loading = true;
  bool _busy = false;
  int? _id;
  List<ServiceQuote> _quotes = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _id ??= ModalRoute.of(context)!.settings.arguments as int;
    if (_job == null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final job = await TechnicianApi.instance.job(_id!);
      if (mounted) setState(() => _job = job);
      if (job.status == 'QUOTE_PENDING' || job.status == 'ARRIVED') {
        final quotes = await TechnicianApi.instance.jobQuotes(_id!);
        if (mounted) setState(() => _quotes = quotes);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openQuoteForm({required bool isRevision}) async {
    final sent = await showQuoteFormSheet(context, jobId: _id!, isRevision: isRevision);
    if (sent && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.t('quoteSentSuccess'))));
      _load();
    }
  }

  Future<void> _setStatus(String status, {bool confirm = false}) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppStrings.t('declineJobQ')),
          content: Text(AppStrings.t('declineJobBody')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.t('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.t('decline'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      final updated = await TechnicianApi.instance.setJobStatus(_id!, status);
      if (mounted) setState(() => _job = updated);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showError(context, '${AppStrings.t('couldNotOpen')} $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final j = _job;
    return Scaffold(
      appBar: AppBar(
        title: Text(j == null
            ? AppStrings.t('job')
            : '${AppStrings.t('jobHash')}${j.id}'),
        actions: j == null
            ? null
            : [
                IconButton(
                  tooltip: AppStrings.t('message'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/chat-thread',
                    arguments: {'jobId': j.id, 'name': j.customerName},
                  ),
                ),
              ],
      ),
      body: _loading || j == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  _StatusPill(status: j.status),
                  const Spacer(),
                  Text(AppStrings.category(j.category),
                      style: TextStyle(color: p.textSecondary)),
                ]),
                const SizedBox(height: 18),
                _row(context, Icons.person_outline, AppStrings.t('customer'),
                    j.customerName),
                InkWell(
                  onTap: j.customerPhone.isEmpty
                      ? null
                      : () => _launch(Uri.parse('tel:${j.customerPhone}')),
                  child: _row(context, Icons.call_outlined,
                      AppStrings.t('phone'),
                      j.customerPhone.isEmpty ? '—' : j.customerPhone,
                      link: j.customerPhone.isNotEmpty),
                ),
                if ((j.address ?? '').isNotEmpty)
                  InkWell(
                    onTap: () => _launch(Uri.parse(
                        'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(j.address!)}')),
                    child: _row(context, Icons.place_outlined,
                        AppStrings.t('address'), j.address!,
                        link: true),
                  ),
                const SizedBox(height: 8),
                Text(AppStrings.t('description'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 4),
                Text(j.description, style: TextStyle(color: p.textPrimary)),
                if (j.lat != null && j.lng != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 180,
                      child: FlutterMap(
                        options: MapOptions(
                            initialCenter: LatLng(j.lat!, j.lng!),
                            initialZoom: 14,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none)),
                        children: [
                          TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.camfix.technician'),
                          MarkerLayer(markers: [
                            Marker(
                                point: LatLng(j.lat!, j.lng!),
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.location_pin,
                                    color: AppColors.primaryBlue, size: 36)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ..._actions(j),
              ],
            ),
    );
  }

  List<Widget> _actions(TechJob j) {
    switch (j.status) {
      case 'ASSIGNED':
        return [
          PrimaryButton(
              label: AppStrings.t('onMyWay'),
              busy: _busy,
              onPressed: () => _setStatus('ON_THE_WAY')),
          const SizedBox(height: 10),
          _declineButton(),
        ];
      case 'ON_THE_WAY':
        return [
          PrimaryButton(
              label: AppStrings.t('iveArrived'),
              busy: _busy,
              onPressed: () => _setStatus('ARRIVED')),
          const SizedBox(height: 10),
          _declineButton(),
        ];
      case 'ARRIVED':
        final rejected = _quotes.isNotEmpty && _quotes.first.isRejected;
        return [
          if (rejected) ...[
            _quoteDeclinedBanner(),
            const SizedBox(height: 14),
          ],
          PrimaryButton(
              label: AppStrings.t(rejected ? 'sendRevisedQuote' : 'sendQuote'),
              busy: _busy,
              onPressed: () => _openQuoteForm(isRevision: rejected)),
        ];
      case 'QUOTE_PENDING':
        return _quotePendingActions();
      case 'IN_PROGRESS':
        return [
          PrimaryButton(
              label: AppStrings.t('markComplete'),
              busy: _busy,
              onPressed: () => _setStatus('COMPLETED')),
        ];
      default:
        return [
          Center(
            child: Text(AppStrings.t('noActionsForJob'),
                style: TextStyle(color: context.pal.textSecondary)),
          ),
        ];
    }
  }

  List<Widget> _quotePendingActions() => [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(AppStrings.t('waitingForCustomerDecision'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
              ),
            ],
          ),
        ),
      ];

  Widget _quoteDeclinedBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD13438).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFFD13438)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(AppStrings.t('quoteWasDeclinedInfo'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFFD13438))),
            ),
          ],
        ),
      );

  Widget _declineButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed:
              _busy ? null : () => _setStatus('REQUESTED', confirm: true),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: const Color(0xFFD13438)),
          child: Text(AppStrings.t('decline')),
        ),
      );

  Widget _row(BuildContext context, IconData icon, String label, String value,
      {bool link = false}) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: p.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
                Text(value,
                    style: TextStyle(
                        color: link ? AppColors.primaryBlue : p.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999)),
      child: Text(AppStrings.jobStatus(status),
          style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }
}
