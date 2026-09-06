import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
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

  static const Map<String, List<ServiceProvider>> _providersByCategory = {
    'Air Conditioner': [
      ServiceProvider(
          name: 'Vanna Sok',
          category: 'Air Conditioner',
          location: 'SenSok, PhnomPenh',
          rating: 4.5),
      ServiceProvider(
          name: 'Ngoun Sokrom',
          category: 'Air Conditioner',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.8),
      ServiceProvider(
          name: 'Chai Bunrak',
          category: 'Air Conditioner',
          location: 'Toul Tompung, PhnomPenh',
          rating: 4),
      ServiceProvider(
          name: 'Dara ChanMean',
          category: 'Air Conditioner',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.3),
      ServiceProvider(
          name: 'Na ChanSok',
          category: 'Air Conditioner',
          location: 'SenSok, PhnomPenh',
          rating: 4.2),
    ],
    'Car': [
      ServiceProvider(
          name: 'Kha Bunn',
          category: 'Car',
          location: 'SenSok, PhnomPenh',
          rating: 4.5),
      ServiceProvider(
          name: 'Reak Smey',
          category: 'Car',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.8),
      ServiceProvider(
          name: 'VannSak Doung',
          category: 'Car',
          location: 'Toul Tompung, PhnomPenh',
          rating: 4),
      ServiceProvider(
          name: 'Mean Dara',
          category: 'Car',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.3),
      ServiceProvider(
          name: 'Muo Nisey',
          category: 'Car',
          location: 'SenSok, PhnomPenh',
          rating: 4.2),
    ],
    'Water network': [
      ServiceProvider(
          name: 'Sok Pisey',
          category: 'Water network',
          location: 'SenSok, PhnomPenh',
          rating: 4.6),
      ServiceProvider(
          name: 'Chan Dara',
          category: 'Water network',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.4),
      ServiceProvider(
          name: 'Long Sophea',
          category: 'Water network',
          location: 'Toul Tompung, PhnomPenh',
          rating: 4.1),
      ServiceProvider(
          name: 'Kim Srey',
          category: 'Water network',
          location: 'Chamkarmon, PhnomPenh',
          rating: 4.7),
    ],
    'Electrical': [
      ServiceProvider(
          name: 'Sok Vibol',
          category: 'Electrical',
          location: 'SenSok, PhnomPenh',
          rating: 4.6),
      ServiceProvider(
          name: 'Chan Ratha',
          category: 'Electrical',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.4),
      ServiceProvider(
          name: 'Pich Sambath',
          category: 'Electrical',
          location: 'Chamkarmon, PhnomPenh',
          rating: 4.7),
      ServiceProvider(
          name: 'Long Dara',
          category: 'Electrical',
          location: 'Daun Penh, PhnomPenh',
          rating: 4.1),
    ],
    'Appliance Repair': [
      ServiceProvider(
          name: 'Kong Pisey',
          category: 'Appliance Repair',
          location: 'SenSok, PhnomPenh',
          rating: 4.5),
      ServiceProvider(
          name: 'Nov Sreypov',
          category: 'Appliance Repair',
          location: 'Toul Tompung, PhnomPenh',
          rating: 4.3),
      ServiceProvider(
          name: 'Heng Vichea',
          category: 'Appliance Repair',
          location: 'Mean Chey, PhnomPenh',
          rating: 4.6),
      ServiceProvider(
          name: 'Sam Oudom',
          category: 'Appliance Repair',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.2),
    ],
    'Motorcycle': [
      ServiceProvider(
          name: 'Rith Sokun',
          category: 'Motorcycle',
          location: 'SenSok, PhnomPenh',
          rating: 4.7),
      ServiceProvider(
          name: 'Chea Kimhong',
          category: 'Motorcycle',
          location: 'Chroy Changvar, PhnomPenh',
          rating: 4.4),
      ServiceProvider(
          name: 'Vong Piseth',
          category: 'Motorcycle',
          location: 'Toul Kouk, PhnomPenh',
          rating: 4.5),
      ServiceProvider(
          name: 'Meng Sovann',
          category: 'Motorcycle',
          location: 'Chamkarmon, PhnomPenh',
          rating: 4),
    ],
  };

  List<ServiceProvider> get _visibleProviders {
    final all = _providersByCategory[_category] ?? const [];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  MainShellController? _shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Category can arrive two ways: as a route argument (pushed directly), or
    // from the dashboard grid via the shell (bottom-nav Service tab).
    if (!_appliedRouteCategory) {
      _appliedRouteCategory = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && _providersByCategory.containsKey(arg)) {
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
    if (cat != null && _providersByCategory.containsKey(cat)) {
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
              child: providers.isEmpty
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _circleBackButton(),
          Expanded(
            child: Center(
              child: Text(
                AppStrings.t('navService'),
                style: AppText.h2
                    .copyWith(fontSize: 20, color: context.pal.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 44), // balances the back button
        ],
      ),
    );
  }

  Widget _circleBackButton() {
    final p = context.pal;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
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
            boxShadow: [
              BoxShadow(
                  color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: p.textSecondary, size: 24),
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
}
