import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_core.dart';
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
          content: Text(AppLocalizations.tr('validation_entry')),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final ticket = await ref.read(parkingProvider.notifier).issueTicket(
          type: _selectedType,
          plateNumber: _plateCtrl.text,
          ownerName: _ownerCtrl.text,
          slot: _slotCtrl.text,
        );
    _plateCtrl.clear();
    _ownerCtrl.clear();
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
              style: TextStyle(
                color: theme.accent,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              '${cfg.activeBranch.name} (${cfg.activeBranch.id})',
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
            icon: Text(
              AppLocalizations.currentLanguage.value.flag,
              style: const TextStyle(fontSize: 19),
            ),
            onPressed: () {
              final list = AppLocalizations.supportedLanguages;
              final nextIdx =
                  (list.indexOf(AppLocalizations.currentLanguage.value) + 1) %
                      list.length;
              AppLocalizations.setLanguage(list[nextIdx]);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: theme.textMuted, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.accent,
          labelColor: theme.accent,
          unselectedLabelColor: theme.textMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.add_circle_outline),
              text: AppLocalizations.tr('new_entry'),
            ),
            Tab(
              icon: const Icon(Icons.directions_car_filled_outlined),
              text:
                  '${AppLocalizations.tr('active_tab')} (${activeList.length})',
            ),
            Tab(
              icon: const Icon(Icons.analytics_outlined),
              text: AppLocalizations.tr('analytics_tab'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: theme.bgSurface,
            child: Row(
              children: [
                _kpi(
                  AppLocalizations.tr('revenue'),
                  '${cfg.currency} ${state.todayRevenueForBranch(branchId).toStringAsFixed(0)}',
                  theme.secondary,
                  Icons.trending_up,
                  theme,
                  style,
                ),
                const SizedBox(width: 8),
                _kpi(
                  AppLocalizations.tr('parked'),
                  '${activeList.length}',
                  theme.accent,
                  Icons.local_parking,
                  theme,
                  style,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: state.isSyncing
                        ? null
                        : () => ref
                            .read(parkingProvider.notifier)
                            .syncPendingQueue(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.bgCard,
                        borderRadius: BorderRadius.circular(style.radius),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.tr('pending_sync'),
                            style:
                                TextStyle(color: theme.textMuted, fontSize: 10),
                          ),
                          Text(
                            state.isSyncing
                                ? '...'
                                : '${state.pendingSyncCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: state.pendingSyncCount > 0
                                  ? const Color(0xFFF59E0B)
                                  : theme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    );
  }
Widget _kpi(String t, String v, Color c, IconData i, AppThemePreset theme,
          CardDesignStyle style) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(style.radius),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Icon(i, color: c, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t,
                        style: TextStyle(color: theme.textMuted, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                    Text(v,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEntryTab(
    bool loading,
    BusinessSettings cfg,
    AppThemePreset theme,
    CardDesignStyle style,
    List<VehicleType> vehicles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('select_vehicle'),
            style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: vehicles.length,
            itemBuilder: (_, i) {
              final type = vehicles[i];
              final sel = type == _selectedType;
              final fee = cfg.rates[type]?.baseFee ?? 0;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? theme.accent : theme.bgCard,
                    borderRadius: BorderRadius.circular(style.radius * 0.85),
                    border: Border.all(
                        color: sel ? theme.accent : theme.borderColor),
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${cfg.currency}${fee.toInt()}',
                        style: TextStyle(
                          color: sel
                              ? theme.textOnAccent.withValues(alpha: 0.8)
                              : theme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(style.radius * 0.85)),
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
              label: Text(
                _isScanning
                    ? AppLocalizations.tr('scanning_plate')
                    : AppLocalizations.tr('scan_plate'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(style.radius)),
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
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(style.radius),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.accent.withValues(alpha: 0.15),
                child: Icon(t.vehicleType.icon, color: theme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${t.plateNumber} • ${t.tokenNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                    Text('${t.ownerName} | ${t.locationSlot}',
                        style: TextStyle(color: theme.textMuted, fontSize: 12)),
                    Text(
                      '${DateFormat('hh:mm a, dd MMM').format(t.entryTime)} • ${t.currency} ${t.calculateTotalFee().toStringAsFixed(0)}',
                      style: TextStyle(color: theme.secondary, fontSize: 11),
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
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
            _kpi(
              'Monthly Revenue',
              '${cfg.currency} ${state.monthlyRevenueForBranch(branchId).toStringAsFixed(0)}',
              theme.accent,
              Icons.calendar_month,
              theme,
              style,
            ),
            const SizedBox(width: 10),
            _kpi(
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(style.radius),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle Mix Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: theme.bgSurface,
                        color: theme.accent,
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.tr('qr_exit'))),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
