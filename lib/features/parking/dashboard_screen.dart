import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_core.dart';
import '../../core/luxury_ui.dart';
import 'parking_logic.dart';
import 'receipt_screen.dart';
import 'settings_screen.dart';

class PlateOcrParser {
  static final List<RegExp> _regionalPatterns = [
    RegExp(r'\b[A-Z]{2,4}[-\s]?\d{2,4}\b'),
    RegExp(r'\b[A-Z]{1,3}[-\s]?\d{1,5}[-\s]?[A-Z]{0,2}\b'),
    RegExp(r'\b[A-Z]{2}\d{2}[-\s]?[A-Z]{3}\b'),
    RegExp(r'\b[A-Z]{1,3}\d{2,4}[A-Z]{1,3}\b'),
  ];

  static ({String best, List<String> candidates}) parseRecognizedText(
      RecognizedText recognized) {
    final scored = <String, double>{};

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final cleaned = line.text
            .toUpperCase()
            .replaceAll(RegExp(r'[^A-Z0-9\-\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.length < 4 || cleaned.length > 14) continue;

        final area = line.boundingBox.width * line.boundingBox.height;
        for (final pattern in _regionalPatterns) {
          for (final match in pattern.allMatches(cleaned)) {
            final token = match.group(0)!.trim();
            if (token.length < 4) continue;
            final hasLetters = RegExp(r'[A-Z]').hasMatch(token);
            final hasDigits = RegExp(r'\d').hasMatch(token);
            if (!hasLetters || !hasDigits) continue;

            final score = (area / 1000.0) + (token.length * 2.0);
            if ((scored[token] ?? 0) < score) scored[token] = score;
          }
        }
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final candidates = sorted.map((e) => e.key).take(4).toList();
    final fallback = recognized.text
        .toUpperCase()
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[^A-Z0-9\-\s]'), '')
        .trim();

    return (
      best: candidates.isNotEmpty ? candidates.first : fallback,
      candidates: candidates,
    );
  }
}

class ProDashboardScreen extends ConsumerStatefulWidget {
  const ProDashboardScreen({super.key});

  @override
  ConsumerState<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends ConsumerState<ProDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VehicleType _selectedType = VehicleType.car;
  final _plateCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _customVehicleCtrl = TextEditingController();
  final _customFeeCtrl = TextEditingController();
  late TextEditingController _slotCtrl;
  List<String> _ocrCandidates = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _slotCtrl =
        TextEditingController(text: ref.read(settingsProvider).defaultSlot);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plateCtrl.dispose();
    _ownerCtrl.dispose();
    _customVehicleCtrl.dispose();
    _customFeeCtrl.dispose();
    _slotCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanPlateWithAI() async {
    HapticFeedback.mediumImpact();
    final img = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 92,
    );
    if (img == null) return;

    setState(() => _isScanning = true);
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(img.path));
      await recognizer.close();

      final parsed = PlateOcrParser.parseRecognizedText(recognized);
      if (mounted) {
        setState(() {
          _plateCtrl.text = parsed.best;
          _ocrCandidates = parsed.candidates;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.tr('err_server'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _issueToken() async {
    if (_plateCtrl.text.trim().isEmpty || _ownerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(AppLocalizations.tr('validation_entry')),
        ),
      );
      return;
    }
    if (_selectedType == VehicleType.other &&
        _customVehicleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(AppLocalizations.tr('validation_custom_vehicle')),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final customFee = double.tryParse(_customFeeCtrl.text.trim());
    final ticket = await ref.read(parkingProvider.notifier).issueTicket(
          type: _selectedType,
          customVehicleName: _selectedType == VehicleType.other
              ? _customVehicleCtrl.text.trim()
              : null,
          customBaseFee: _selectedType == VehicleType.other ? customFee : null,
          plateNumber: _plateCtrl.text,
          ownerName: _ownerCtrl.text,
          slot: _slotCtrl.text,
        );
    _plateCtrl.clear();
    _ownerCtrl.clear();
    _customVehicleCtrl.clear();
    _customFeeCtrl.clear();
    setState(() => _ocrCandidates = []);

    if (mounted) {
      if (ticket.isVipPass) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(AppLocalizations.tr('vip_pass_applied')),
          ),
        );
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VipReceiptScreen(ticket: ticket)),
      );
    }
  }

  Future<void> _exportCsv(String branchId) async {
    final csv = ref.read(parkingProvider.notifier).buildCsvReport(branchId);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'smartpark_${branchId}_report.csv',
    );
  }

  Future<void> _exportFinancialPdf(
      BusinessSettings cfg, ParkingState state) async {
    final branchId = cfg.activeBranchId;
    final tickets = state.forBranch(branchId);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '${cfg.businessName} — Financial Audit (${cfg.activeBranch.name})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Today: ${cfg.currency} ${state.todayRevenueForBranch(branchId).toStringAsFixed(2)}  |  '
            'Monthly: ${cfg.currency} ${state.monthlyRevenueForBranch(branchId).toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Token', 'Plate', 'Class', 'Entry', 'Status', 'Fee'],
            data: tickets
                .take(100)
                .map((t) => [
                      t.tokenNumber,
                      t.plateNumber,
                      t.vehicleType.name,
                      DateFormat('MM/dd HH:mm').format(t.entryTime),
                      t.status.name,
                      '${t.currency} ${t.calculateTotalFee().toStringAsFixed(0)}',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Developer: Muhammad Umair Sattar | (c) 2026',
              style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  void _openCountryPicker(AppThemePreset theme) {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final items = WorldCountryPresets.all.where((c) {
            final q = query.toLowerCase();
            return c.countryName.toLowerCase().contains(q) ||
                c.languageLabel.toLowerCase().contains(q) ||
                c.currencySymbol.toLowerCase().contains(q);
          }).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search 55+ Countries / Currency / Language...',
                      prefixIcon: Icon(Icons.public),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return ListTile(
                        leading:
                            Text(c.flag, style: const TextStyle(fontSize: 22)),
                        title: Text(c.countryName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            Text('${c.languageLabel} • ${c.currencySymbol}'),
                        onTap: () async {
                          await ref
                              .read(settingsProvider.notifier)
                              .applyCountryPreset(c);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parkingProvider);
    final cfg = ref.watch(settingsProvider);
    final theme = cfg.activeTheme;
    final style = cfg.activeStyle;
    final branchId = cfg.activeBranchId;
    final activeList = state.activeTicketsForBranch(branchId);

    final enabledVehicles = VehicleType.values
        .where((v) => cfg.rates[v]?.enabled ?? true)
        .toList();
    if (enabledVehicles.isNotEmpty &&
        !enabledVehicles.contains(_selectedType)) {
      _selectedType = enabledVehicles.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cfg.businessName,
              style: GoogleFonts.outfit(
                color: theme.accent,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              '${cfg.activeBranch.name} • ${cfg.activeBranch.id}',
              style: TextStyle(color: theme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.tr('qr_exit'),
            icon: Icon(Icons.qr_code_scanner_rounded, color: theme.secondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrExitScannerScreen()),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.tr('settings'),
            icon: Icon(Icons.tune_rounded, color: theme.accent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Country & Language (55+)',
            icon: Text(
              AppLocalizations.currentLanguage.value.flag,
              style: const TextStyle(fontSize: 19),
            ),
            onPressed: () => _openCountryPicker(theme),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: theme.textMuted, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: AmbientBackdrop(
        theme: theme,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: ExecutiveCard(
                theme: theme,
                style: style,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.tr('revenue').toUpperCase(),
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${cfg.currency} ${state.todayRevenueForBranch(branchId).toStringAsFixed(0)}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: theme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusPill(
                          label:
                              '${activeList.length} ${AppLocalizations.tr('parked')}',
                          color: theme.accent,
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: state.isSyncing
                              ? null
                              : () => ref
                                  .read(parkingProvider.notifier)
                                  .syncPendingQueue(),
                          child: StatusPill(
                            label: state.isSyncing
                                ? 'SYNCING...'
                                : (state.pendingSyncCount > 0
                                    ? '${state.pendingSyncCount} ${AppLocalizations.tr('pending_sync')}'
                                    : 'CLOUD SYNCED'),
                            color: state.pendingSyncCount > 0
                                ? const Color(0xFFF59E0B)
                                : theme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) => SegmentedPillTabs(
                theme: theme,
                currentIndex: _tabController.index,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  _tabController.animateTo(i);
                },
                items: [
                  (
                    label: AppLocalizations.tr('new_entry'),
                    icon: Icons.add_circle_outline,
                  ),
                  (
                    label:
                        '${AppLocalizations.tr('active_tab')} (${activeList.length})',
                    icon: Icons.directions_car_filled_outlined,
                  ),
                  (
                    label: AppLocalizations.tr('analytics_tab'),
                    icon: Icons.analytics_outlined,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEntryTab(
                      state.isLoading, cfg, theme, style, enabledVehicles),
                  _buildActiveTab(activeList, theme, style),
                  _buildAnalyticsTab(cfg, state, theme, style),
                ],
              ),
            ),
            DeveloperWatermark(theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTab(
    bool loading,
    BusinessSettings cfg,
    AppThemePreset theme,
    CardDesignStyle style,
    List<VehicleType> vehicles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _plateCtrl,
            builder: (_, val, __) => EmbossedPlateView(
              plateText: val.text,
              theme: theme,
              style: style,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.tr('select_vehicle'),
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemCount: vehicles.length,
            itemBuilder: (_, i) {
              final type = vehicles[i];
              final sel = type == _selectedType;
              final fee = cfg.rates[type]?.baseFee ?? 0;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedType = type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? theme.accent : theme.bgCard,
                    borderRadius: BorderRadius.circular(style.radius * 0.85),
                    border: Border.all(
                      color: sel ? theme.accent : theme.borderColor,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: theme.accent.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon,
                          color: sel ? theme.textOnAccent : theme.accent,
                          size: 26),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.tr(type.labelKey),
                        style: TextStyle(
                          color: sel ? theme.textOnAccent : theme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${cfg.currency}${fee.toInt()}',
                        style: GoogleFonts.jetBrainsMono(
                          color: sel
                              ? theme.textOnAccent.withValues(alpha: 0.85)
                              : theme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedType == VehicleType.other) ...[
            const SizedBox(height: 14),
            ExecutiveCard(
              theme: theme,
              style: style,
              borderColorOverride: theme.accent,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _customVehicleCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr('custom_vehicle'),
                      prefixIcon: Icon(Icons.edit_note, color: theme.accent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr('custom_fee'),
                      prefixIcon: Icon(Icons.payments_outlined,
                          color: theme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: _isScanning ? null : _scanPlateWithAI,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_rounded),
              label: Text(_isScanning
                  ? AppLocalizations.tr('scanning_plate')
                  : AppLocalizations.tr('scan_plate')),
            ),
          ),
          if (_ocrCandidates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _ocrCandidates
                  .map(
                    (c) => ActionChip(
                      label: Text(c,
                          style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _plateCtrl.text = c),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: AppLocalizations.tr('plate_no'),
              prefixIcon: Icon(Icons.pin, color: theme.accent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerCtrl,
            decoration: InputDecoration(
              labelText: AppLocalizations.tr('owner_name'),
              prefixIcon: Icon(Icons.person, color: theme.accent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slotCtrl,
            decoration: InputDecoration(
              labelText: AppLocalizations.tr('location'),
              prefixIcon: Icon(Icons.location_on, color: theme.accent),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: theme.textOnAccent,
              ),
              onPressed: loading ? null : _issueToken,
              child: Text(
                AppLocalizations.tr('generate_token'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActiveTab(
    List<ParkingTicket> list,
    AppThemePreset theme,
    CardDesignStyle style,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(AppLocalizations.tr('no_active'),
            style: TextStyle(color: theme.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = list[i];
        return ExecutiveCard(
          theme: theme,
          style: style,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.accent.withValues(alpha: 0.14),
                child: Icon(t.vehicleType.icon, color: theme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.plateNumber,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          t.isSynced
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined,
                          size: 14,
                          color: t.isSynced
                              ? theme.secondary
                              : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    Text(
                      '${t.vehicleDisplayName} • ${t.ownerName}',
                      style: TextStyle(color: theme.textMuted, fontSize: 11.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${DateFormat('hh:mm a, dd MMM').format(t.entryTime)} • ${t.currency} ${t.calculateTotalFee().toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        color: theme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  final closed = await ref
                      .read(parkingProvider.notifier)
                      .checkOutTicket(t.tokenNumber);
                  if (closed != null && mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VipReceiptScreen(ticket: closed)),
                    );
                  }
                },
                child: Text(AppLocalizations.tr('exit_btn'),
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(
    BusinessSettings cfg,
    ParkingState state,
    AppThemePreset theme,
    CardDesignStyle style,
  ) {
    final branchId = cfg.activeBranchId;
    final counts = state.vehicleCountsForBranch(branchId);
    final totalUnits = counts.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _miniKpi(
              'Monthly Revenue',
              '${cfg.currency} ${state.monthlyRevenueForBranch(branchId).toStringAsFixed(0)}',
              theme.accent,
              Icons.calendar_month,
              theme,
              style,
            ),
            const SizedBox(width: 10),
            _miniKpi(
              'Total Tickets',
              '$totalUnits',
              theme.secondary,
              Icons.receipt_long,
              theme,
              style,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ExecutiveCard(
          theme: theme,
          style: style,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle Mix Analytics',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              ...VehicleType.values.map((v) {
                final c = counts[v] ?? 0;
                final ratio = totalUnits == 0 ? 0.0 : c / totalUnits;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.tr(v.labelKey)),
                          Text('$c units',
                              style: GoogleFonts.jetBrainsMono(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: theme.bgSurface,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: theme.textOnAccent,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _exportFinancialPdf(cfg, state),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(AppLocalizations.tr('export_pdf')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.accent,
                  side: BorderSide(color: theme.accent),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(style.radius * 0.8)),
                ),
                onPressed: () => _exportCsv(branchId),
                icon: const Icon(Icons.table_chart_outlined),
                label: Text(AppLocalizations.tr('export_csv')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniKpi(String t, String v, Color c, IconData i,
          AppThemePreset theme, CardDesignStyle style) =>
      Expanded(
        child: ExecutiveCard(
          theme: theme,
          style: style,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(i, color: c, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t,
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    Text(v,
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class QrExitScannerScreen extends ConsumerStatefulWidget {
  const QrExitScannerScreen({super.key});

  @override
  ConsumerState<QrExitScannerScreen> createState() =>
      _QrExitScannerScreenState();
}

class _QrExitScannerScreenState extends ConsumerState<QrExitScannerScreen> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _processing = true;
    final verifiedToken = QrCryptoService.verifyAndExtractToken(raw);
    if (verifiedToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(AppLocalizations.tr('err_qr_forged')),
          ),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      _processing = false;
      return;
    }

    final ticket = await ref
        .read(parkingProvider.notifier)
        .checkOutTicket(verifiedToken);
    if (!mounted) return;

    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(AppLocalizations.tr('err_ticket_not_found')),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      _processing = false;
      return;
    }

    HapticFeedback.heavyImpact();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VipReceiptScreen(ticket: ticket)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).activeTheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.tr('qr_exit'))),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: theme.accent, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
