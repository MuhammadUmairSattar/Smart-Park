import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_core.dart';
import 'parking_logic.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late TextEditingController _bizCtrl;
  late TextEditingController _currCtrl;
  late TextEditingController _slotCtrl;
  late TextEditingController _taxCtrl;
  late bool _hourlyBilling;

  final _branchIdCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _vipPlateCtrl = TextEditingController();
  final _vipOwnerCtrl = TextEditingController();
  VehicleType _vipVehicle = VehicleType.car;
  String _themeFilter = 'All';

  final Map<VehicleType, TextEditingController> _baseCtrls = {};
  final Map<VehicleType, TextEditingController> _hourCtrls = {};
  final Map<VehicleType, TextEditingController> _graceCtrls = {};
  final Map<VehicleType, bool> _enabledMap = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final s = ref.read(settingsProvider);
    _bizCtrl = TextEditingController(text: s.businessName);
    _currCtrl = TextEditingController(text: s.currency);
    _slotCtrl = TextEditingController(text: s.defaultSlot);
    _taxCtrl = TextEditingController(text: s.taxPercent.toString());
    _hourlyBilling = s.hourlyBilling;

    for (final v in VehicleType.values) {
      final r = s.rates[v] ?? const VehicleRateConfig();
      _baseCtrls[v] = TextEditingController(
          text: r.baseFee == 0 ? '' : '${r.baseFee.toInt()}');
      _hourCtrls[v] = TextEditingController(
          text: r.hourlyRate == 0 ? '' : '${r.hourlyRate.toInt()}');
      _graceCtrls[v] = TextEditingController(text: '${r.graceMinutes}');
      _enabledMap[v] = r.enabled;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bizCtrl.dispose();
    _currCtrl.dispose();
    _slotCtrl.dispose();
    _taxCtrl.dispose();
    _branchIdCtrl.dispose();
    _branchNameCtrl.dispose();
    _vipPlateCtrl.dispose();
    _vipOwnerCtrl.dispose();
    for (final c in _baseCtrls.values) {
      c.dispose();
    }
    for (final c in _hourCtrls.values) {
      c.dispose();
    }
    for (final c in _graceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();
    final cur = ref.read(settingsProvider);
    final updatedRates = <VehicleType, VehicleRateConfig>{};
    for (final v in VehicleType.values) {
      updatedRates[v] = VehicleRateConfig(
        baseFee: double.tryParse(_baseCtrls[v]!.text.trim()) ?? 0,
        hourlyRate: double.tryParse(_hourCtrls[v]!.text.trim()) ?? 0,
        graceMinutes: int.tryParse(_graceCtrls[v]!.text.trim()) ?? 15,
        enabled: _enabledMap[v] ?? true,
      );
    }

    await ref.read(settingsProvider.notifier).updateAll(
          cur.copyWith(
            businessName: _bizCtrl.text.trim().isEmpty
                ? 'SmartPark Pro'
                : _bizCtrl.text.trim(),
            currency:
                _currCtrl.text.trim().isEmpty ? 'Rs.' : _currCtrl.text.trim(),
            defaultSlot: _slotCtrl.text.trim().isEmpty
                ? 'Zone A - Bay 01'
                : _slotCtrl.text.trim(),
            taxPercent: double.tryParse(_taxCtrl.text.trim()) ?? 0,
            hourlyBilling: _hourlyBilling,
            rates: updatedRates,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cur.activeTheme.secondary,
          content: const Text('Settings saved permanently.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final parking = ref.watch(parkingProvider);
    final theme = s.activeTheme;
    final style = s.activeStyle;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('settings')),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.accent,
          labelColor: theme.accent,
          unselectedLabelColor: theme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.payments_outlined), text: 'Tariffs & VAT'),
            Tab(icon: Icon(Icons.apartment_rounded), text: 'Branches & VIP'),
            Tab(icon: Icon(Icons.palette_outlined), text: '50 Themes'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRatesTab(theme, style),
                _buildBranchesAndVipTab(s, parking, theme),
                _buildThemesTab(s, theme, style),
              ],
            ),
          ),
          DeveloperWatermark(theme: theme),
        ],
      ),
    );
  }

  Widget _buildRatesTab(AppThemePreset theme, CardDesignStyle style) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _bizCtrl,
          decoration: const InputDecoration(
            labelText: 'Organization / Site Name',
            prefixIcon: Icon(Icons.storefront),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _slotCtrl,
          decoration: const InputDecoration(
            labelText: 'Default Parking Zone',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _currCtrl,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _taxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tax / VAT %'),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hourly Overtime Billing'),
          subtitle: Text(
            _hourlyBilling ? 'Base + Extra Hourly Rate' : 'Flat Fee Only',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
          value: _hourlyBilling,
          activeThumbColor: theme.accent,
          onChanged: (v) => setState(() => _hourlyBilling = v),
        ),
        const Divider(),
        ...VehicleType.values.map(
          (v) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(style.radius),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(v.icon, color: theme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(AppLocalizations.tr(v.labelKey),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: _enabledMap[v] ?? true,
                      activeThumbColor: theme.accent,
                      onChanged: (val) => setState(() => _enabledMap[v] = val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _baseCtrls[v],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Base Fee', hintText: '0'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _hourCtrls[v],
                        keyboardType: TextInputType.number,
                        enabled: _hourlyBilling,
                        decoration: const InputDecoration(
                            labelText: 'Extra/Hr', hintText: '0'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _graceCtrls[v],
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Grace Min'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: theme.textOnAccent,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: _saveSettings,
          icon: const Icon(Icons.save_rounded),
          label: const Text('SAVE TARIFFS & RULES',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBranchesAndVipTab(
    BusinessSettings s,
    ParkingState parking,
    AppThemePreset theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ACTIVE SITE / BRANCH',
            style: TextStyle(
                color: theme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: s.branches.map((b) {
            final selected = b.id == s.activeBranchId;
            return ChoiceChip(
              label: Text('${b.name} (${b.id})'),
              selected: selected,
              selectedColor: theme.accent,
              labelStyle: TextStyle(
                color: selected ? theme.textOnAccent : theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) =>
                  ref.read(settingsProvider.notifier).setActiveBranch(b.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _branchIdCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Branch ID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _branchNameCtrl,
                decoration: const InputDecoration(labelText: 'Branch Name'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: theme.accent),
              onPressed: () {
                final id = _branchIdCtrl.text.trim().toUpperCase();
                final name = _branchNameCtrl.text.trim();
                if (id.isEmpty || name.isEmpty) return;
                final updated = [
                  ...s.branches.where((b) => b.id != id),
                  BranchConfig(id: id, name: name),
                ];
                ref
                    .read(settingsProvider.notifier)
                    .updateAll(s.copyWith(branches: updated, activeBranchId: id));
                _branchIdCtrl.clear();
                _branchNameCtrl.clear();
              },
              icon: Icon(Icons.add, color: theme.textOnAccent),
            ),
          ],
        ),
        const Divider(height: 28),
        Text('VIP / MONTHLY PASSES (30-DAY WAIVER)',
            style: TextStyle(
                color: theme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _vipPlateCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'VIP Plate Number'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _vipOwnerCtrl,
          decoration: const InputDecoration(labelText: 'VIP Member Name'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<VehicleType>(
          initialValue: _vipVehicle,
          items: VehicleType.values
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(AppLocalizations.tr(v.labelKey)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _vipVehicle = v);
          },
          decoration: const InputDecoration(labelText: 'Vehicle Class'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.secondary,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (_vipPlateCtrl.text.trim().isEmpty ||
                _vipOwnerCtrl.text.trim().isEmpty) {
              return;
            }
            final pass = VipPass(
              passId: 'VIP-${DateTime.now().millisecondsSinceEpoch}',
              plateNumber: _vipPlateCtrl.text.trim().toUpperCase(),
              ownerName: _vipOwnerCtrl.text.trim(),
              vehicleType: _vipVehicle,
              branchId: s.activeBranchId,
              validUntil: DateTime.now().add(const Duration(days: 30)),
            );
            await ref.read(parkingProvider.notifier).addVipPass(pass);
            _vipPlateCtrl.clear();
            _vipOwnerCtrl.clear();
          },
          icon: const Icon(Icons.card_membership),
          label: const Text('ISSUE 30-DAY VIP PASS'),
        ),
        const SizedBox(height: 14),
        ...parking.vipPasses.map(
          (p) => ListTile(
            tileColor: theme.bgCard,
            title: Text('${p.plateNumber} — ${p.ownerName}'),
            subtitle: Text(
              'Branch: ${p.branchId} • Valid until ${DateFormat('dd MMM yyyy').format(p.validUntil)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: () =>
                  ref.read(parkingProvider.notifier).removeVipPass(p.passId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemesTab(
    BusinessSettings s,
    AppThemePreset activeTheme,
    CardDesignStyle activeStyle,
  ) {
    final filtered = AppThemePresets.all.asMap().entries.where((e) {
      if (_themeFilter == 'Dark') return !e.value.isLight;
      if (_themeFilter == 'Light') return e.value.isLight;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: CardDesignStyle.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final st = CardDesignStyle.values[i];
              final sel = s.designStyleIndex == i;
              return ChoiceChip(
                label: Text(st.label),
                selected: sel,
                selectedColor: activeTheme.accent,
                labelStyle: TextStyle(
                  color: sel ? activeTheme.textOnAccent : activeTheme.textPrimary,
                  fontSize: 12,
                ),
                onSelected: (_) =>
                    ref.read(settingsProvider.notifier).setDesignStyle(i),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['All', 'Dark', 'Light'].map((f) {
              final sel = _themeFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: sel,
                  selectedColor: activeTheme.accent,
                  labelStyle: TextStyle(
                    color:
                        sel ? activeTheme.textOnAccent : activeTheme.textPrimary,
                    fontSize: 11.5,
                  ),
                  onSelected: (_) => setState(() => _themeFilter = f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, idx) {
              final entry = filtered[idx];
              final t = entry.value;
              final sel = s.themeIndex == entry.key;
              return GestureDetector(
                onTap: () =>
                    ref.read(settingsProvider.notifier).setTheme(entry.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.bgCard,
                    borderRadius: BorderRadius.circular(activeStyle.radius),
                    border: Border.all(
                      color: sel ? t.accent : t.borderColor,
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 8, backgroundColor: t.accent),
                          const SizedBox(width: 5),
                          CircleAvatar(radius: 8, backgroundColor: t.secondary),
                          const Spacer(),
                          if (sel)
                            Icon(Icons.check_circle, color: t.accent, size: 18),
                        ],
                      ),
                      Text(
                        t.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
