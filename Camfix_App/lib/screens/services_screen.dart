import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/technicians_api.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Maps an internal category name to its localised label.
String categoryLabel(String category) {
  const keys = {
    'Air Conditioner': 'svcAirConditioner',
    'Electrical': 'svcElectrical',
    'Appliance Repair': 'svcApplianceRepair',
    'Motorcycle': 'svcMotorcycle',
    'Car': 'svcCar',
    'Water network': 'svcWaterNetwork',
  };
  final key = keys[category];
  return key == null ? category : AppStrings.t(key);
}

/// "Services" screen — pick a category chip, then browse the providers who
/// offer that service. Matches mockup pages 14–15 (Air Conditioner / Car).
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = _categories.first;
  bool _appliedRouteCategory = false;

  static const List<String> _categories = [
    'Air Conditioner',
    'Electrical',
    'Appliance Repair',
    'Motorcycle',
    'Car',
    'Water network',
  ];

  List<ServiceProvider> _providers = const [];
  bool _loading = true;
  String? _error;

  List<ServiceProvider> get _visibleProviders {
    final all =
        _providers.where((p) => p.category == _category).toList();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  MainShellController? _shell;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await TechniciansApi.instance.list();
      if (mounted) setState(() => _providers = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Category can arrive two ways: as a route argument (pushed directly), or
    // from the dashboard grid via the shell (bottom-nav Service tab).
    if (!_appliedRouteCategory) {
      _appliedRouteCategory = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && _categories.contains(arg)) {
        _category = arg;
      }
    }
    final shell = MainShell.of(context);
    if (shell != _shell) {
      _shell?.pendingCategory.removeListener(_applyPendingCategory);
      _shell = shell;
      _shell?.pendingCategory.addListener(_applyPendingCategory);
      _applyPendingCategory();
    }
  }

  void _applyPendingCategory() {
    final cat = _shell?.pendingCategory.value;
    if (cat != null && _categories.contains(cat)) {
      setState(() => _category = cat);
      _shell?.pendingCategory.value = null;
    }
  }

  @override
  void dispose() {
    _shell?.pendingCategory.removeListener(_applyPendingCategory);
    _searchController.dispose();
    super.dispose();
  }

  static String _formatRating(double r) =>
      r % 1 == 0 ? r.toStringAsFixed(0) : r.toString();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final providers = _visibleProviders;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 14),
            _buildCategoryChips(),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : providers.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                    20, 8, 20, 110 + bottomInset),
                                itemCount: providers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) =>
                                    _buildProviderCard(providers[i]),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => MainShell.of(context)?.goToTab(0),
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
          ),
          Expanded(
            child: Center(
              child: Text(
                AppStrings.t('navService'),
                style: AppText.h2.copyWith(fontSize: 20, color: p.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 15, color: p.textPrimary),
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: AppStrings.t('searchForService'),
          hintStyle: TextStyle(color: p.textSecondary, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: p.textSecondary, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: p.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final p = context.pal;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final label = _categories[i];
          final bool active = label == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryBlue : p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primaryBlue : p.border,
                ),
              ),
              child: Text(
                categoryLabel(label),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : p.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(ServiceProvider provider) {
    final p = context.pal;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context).pushNamed('/provider', arguments: provider),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            // flat, like the mockup list — just a hairline, no heavy drop shadow
            boxShadow: [
              BoxShadow(
                  color: p.shadow, blurRadius: 5, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded,
                    color: p.textSecondary.withValues(alpha: 0.45), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: p.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            provider.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.t('rateOf5')} ${_formatRating(provider.rating)}/5',
                      style:
                          TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: p.textSecondary),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty
                  ? AppStrings.t('noProvidersInCategory')
                  : AppStrings.t('noProvidersMatch'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: p.textSecondary),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: Text(AppStrings.t('retry'))),
          ],
        ),
      ),
    );
  }
}
