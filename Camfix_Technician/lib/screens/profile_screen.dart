import 'package:flutter/material.dart';

import '../models/technician_profile.dart';
import '../services/current_technician.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _area = TextEditingController();
  final _about = TextEditingController();
  final _hours = TextEditingController();
  String _category = kServiceCategories.first;
  bool _editing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fill(CurrentTechnician.instance.value);
  }

  void _fill(TechnicianProfile? p) {
    if (p == null) return;
    _first.text = p.firstName == '-' ? '' : p.firstName;
    _last.text = p.lastName == '-' ? '' : p.lastName;
    _area.text = p.serviceArea;
    _about.text = p.about ?? '';
    _hours.text = p.openingHours ?? '';
    if (kServiceCategories.contains(p.category)) _category = p.category;
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _area, _about, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final updated = await TechnicianApi.instance.updateProfile({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'category': _category,
        'serviceArea': _area.text.trim(),
        'about': _about.text.trim(),
        'openingHours': _hours.text.trim(),
      });
      CurrentTechnician.instance.set(updated);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final profile = CurrentTechnician.instance.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          if (!_editing)
            TextButton(
                onPressed: () => setState(() {
                      _fill(profile);
                      _editing = true;
                    }),
                child: const Text('Edit')),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!_editing) ...[
                  _kv(context, 'Name', profile.displayName),
                  _kv(context, 'Email', profile.email),
                  _kv(context, 'Phone', profile.phoneNumber),
                  _kv(context, 'Category', profile.category),
                  _kv(context, 'Service area', profile.serviceArea),
                  _kv(context, 'About', profile.about ?? '—'),
                  _kv(context, 'Opening hours', profile.openingHours ?? '—'),
                  _kv(context, 'Rating',
                      '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount})'),
                  _kv(context, 'Status',
                      '${profile.approvalStatus} · ${profile.accountStatus}'),
                ] else ...[
                  Row(children: [
                    Expanded(
                        child: LabeledField(
                            label: 'First name', controller: _first)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: LabeledField(
                            label: 'Last name', controller: _last)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text('Service category',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _category,
                        items: [
                          for (final c in kServiceCategories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(label: 'Service area', controller: _area),
                  LabeledField(
                      label: 'About', controller: _about, maxLines: 3),
                  LabeledField(label: 'Opening hours', controller: _hours),
                  const SizedBox(height: 4),
                  PrimaryButton(
                      label: 'Save', busy: _busy, onPressed: _save),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _editing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 12, color: p.textSecondary)),
          const SizedBox(height: 2),
          Text(v, style: TextStyle(fontSize: 15, color: p.textPrimary)),
        ],
      ),
    );
  }
}
