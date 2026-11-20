import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_core.dart';
import 'parking_logic.dart';
import 'receipt_screen.dart';

class ProDashboardScreen extends ConsumerStatefulWidget {
  const ProDashboardScreen({super.key});
  @override
  ConsumerState<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends ConsumerState<ProDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VehicleType _selectedType = VehicleType.car;
  final _plateCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _slotCtrl = TextEditingController(text: 'VIP Zone A - Bay 01');
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _scanPlateWithAI() async {
    HapticFeedback.mediumImpact();
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    if (img == null) return;
    setState(() => _isScanning = true);
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(InputImage.fromFilePath(img.path));
      await recognizer.close();
      final raw = result.text.replaceAll('\n', ' ').toUpperCase();
      final match = RegExp(r'[A-Z]{1,4}[-\s]?\d{1,5}').firstMatch(raw);
      setState(() => _plateCtrl.text = match != null ? match.group(0)! : raw.trim());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR Error: $e')));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _issueToken() async {
    if (_plateCtrl.text.trim().isEmpty || _ownerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.danger, content: Text('Enter Plate Number & Owner Name!')));
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
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => VipReceiptScreen(ticket: ticket)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parkingProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Text(AppLocalizations.tr('app_name'), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'QR Exit Scanner',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.emerald),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrExitScannerScreen())),
          ),
          IconButton(
            icon: Text(AppLocalizations.currentLanguage.value.flag, style: const TextStyle(fontSize: 20)),
            onPressed: () {
              final list = AppLocalizations.supportedLanguages;
              AppLocalizations.currentLanguage.value = list[(list.indexOf(AppLocalizations.currentLanguage.value) + 1) % 3];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          tabs: [
            const Tab(icon: Icon(Icons.add_circle_outline), text: 'New Entry'),
            Tab(icon: const Icon(Icons.directions_car_filled_outlined), text: 'Active (${state.activeTickets.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgSurface,
            child: Row(
              children: [
                _kpi('Revenue', 'Rs. ${state.todayRevenue.toInt()}', AppTheme.emerald, Icons.trending_up),
                const SizedBox(width: 12),
                _kpi('Parked', '${state.activeTickets.length} Units', AppTheme.goldAccent, Icons.local_parking),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEntryTab(state.isLoading), _buildActiveTab(state.activeTickets)],
            ),
          ),
          const DeveloperWatermark(),
        ],
      ),
    );
  }

  Widget _kpi(String t, String v, Color c, IconData i) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Row(children: [
            CircleAvatar(backgroundColor: c.withOpacity(0.15), child: Icon(i, color: c, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ]),
        ),
      );

  Widget _buildEntryTab(bool loading) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.tr('select_vehicle'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
              itemCount: VehicleType.values.length,
              itemBuilder: (ctx, i) {
                final type = VehicleType.values[i];
                final sel = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.goldAccent : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppTheme.goldLight : const Color(0x14FFFFFF)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(type.icon, color: sel ? Colors.black : AppTheme.goldAccent, size: 26),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.tr(type.labelKey), style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('Rs.${type.baseFee.toInt()}', style: TextStyle(color: sel ? Colors.black87 : AppTheme.textMuted, fontSize: 9.5)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyanAI, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isScanning ? null : _scanPlateWithAI,
                icon: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.document_scanner_rounded),
                label: Text(AppLocalizations.tr('scan_plate'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _plateCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: AppLocalizations.tr('plate_no'), prefixIcon: const Icon(Icons.pin, color: AppTheme.goldAccent))),
            const SizedBox(height: 12),
            TextField(controller: _ownerCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('owner_name'), prefixIcon: const Icon(Icons.person, color: AppTheme.goldAccent))),
            const SizedBox(height: 12),
            TextField(controller: _slotCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('location'), prefixIcon: const Icon(Icons.location_on, color: AppTheme.goldAccent))),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: loading ? null : _issueToken,
                child: Text(AppLocalizations.tr('generate_token'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      );

  Widget _buildActiveTab(List<ParkingTicket> list) {
    if (list.isEmpty) return const Center(child: Text('No active vehicles parked.', style: TextStyle(color: AppTheme.textMuted)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final t = list[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            CircleAvatar(backgroundColor: const Color(0x26D4AF37), child: Icon(t.vehicleType.icon, color: AppTheme.goldAccent)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t.plateNumber} • ${t.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${t.ownerName} | ${t.locationSlot}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text(DateFormat('hh:mm a, dd MMM').format(t.entryTime), style: const TextStyle(color: AppTheme.emerald, fontSize: 11)),
              ]),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.black),
              onPressed: () {
                final closed = ref.read(parkingProvider.notifier).checkOutTicket(t.tokenNumber);
                if (closed != null) Navigator.push(context, MaterialPageRoute(builder: (_) => VipReceiptScreen(ticket: closed)));
              },
              child: const Text('EXIT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        );
      },
    );
  }
}

class QrExitScannerScreen extends ConsumerStatefulWidget {
  const QrExitScannerScreen({super.key});
  @override
  ConsumerState<QrExitScannerScreen> createState() => _QrExitScannerScreenState();
}

class _QrExitScannerScreenState extends ConsumerState<QrExitScannerScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Token for Exit')),
      body: MobileScanner(onDetect: (capture) {
        if (_scanned) return;
        final code = capture.barcodes.first.rawValue;
        if (code == null) return;
        final tokenNo = code.split('|').first.trim();
        final ticket = ref.read(parkingProvider.notifier).checkOutTicket(tokenNo);
        if (ticket != null) {
          _scanned = true;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VipReceiptScreen(ticket: ticket)));
        }
      }),
    );
  }
}
