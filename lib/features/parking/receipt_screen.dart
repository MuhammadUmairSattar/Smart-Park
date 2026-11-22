import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_core.dart';
import 'parking_logic.dart';

class LuxuryTicketClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double cutPositionRatio;
  LuxuryTicketClipper({this.holeRadius = 16, this.cutPositionRatio = 0.64});

  @override
  Path getClip(Size size) {
    final cutY = size.height * cutPositionRatio;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cutY - holeRadius)
      ..arcToPoint(
        Offset(size.width, cutY + holeRadius),
        radius: Radius.circular(holeRadius),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cutY + holeRadius)
      ..arcToPoint(
        Offset(0, cutY - holeRadius),
        radius: Radius.circular(holeRadius),
        clockwise: false,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashW = 6.0;
        final count = (constraints.constrainWidth() / (2 * dashW)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashW,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
              ),
            ),
          ),
        );
      },
    );
  }
}

class VipReceiptScreen extends ConsumerWidget {
  final ParkingTicket ticket;
  const VipReceiptScreen({super.key, required this.ticket});

  Future<void> _exportThermalPdf() async {
    final pdf = pw.Document();
    final entryStr =
        DateFormat('dd-MMM-yyyy hh:mm:ss a').format(ticket.entryTime);
    final exitStr = ticket.exitTime != null
        ? DateFormat('dd-MMM-yyyy hh:mm:ss a').format(ticket.exitTime!)
        : 'PARKED';
    final total = ticket.calculateTotalFee().toStringAsFixed(2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              ticket.businessName.toUpperCase(),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Branch: ${ticket.branchId}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Divider(),
            pw.Text(
              ticket.tokenNumber,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (ticket.isVipPass)
              pw.Text('VIP PASS HOLDER',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Vehicle: ${ticket.vehicleType.labelKey.toUpperCase()}'),
            pw.Text('Plate: ${ticket.plateNumber}'),
            pw.Text('Owner: ${ticket.ownerName}'),
            pw.Text('Zone: ${ticket.locationSlot}'),
            pw.Text('Entry: $entryStr'),
            pw.Text('Exit: $exitStr'),
            if (ticket.taxPercent > 0)
              pw.Text('Tax/VAT: ${ticket.taxPercent.toStringAsFixed(1)}%'),
            pw.SizedBox(height: 6),
            pw.Text(
              'TOTAL: ${ticket.currency} $total',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: ticket.signedQrData,
              width: 85,
              height: 85,
            ),
            pw.SizedBox(height: 4),
            pw.Text('HMAC: ${ticket.qrSignature}',
                style: const pw.TextStyle(fontSize: 7)),
            pw.Divider(),
            pw.Text('Developer: Muhammad Umair Sattar',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text('(c) 2026 All Rights Reserved',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider).activeTheme;
    final isClosed = ticket.status == TicketStatus.checkedOut;
    final subtotal = ticket.calculateSubtotal();
    final totalFee = ticket.calculateTotalFee();

    return Scaffold(
      appBar: AppBar(
        title: Text(isClosed ? 'Final Exit Receipt' : 'Signed Parking Pass'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ClipPath(
                      clipper: LuxuryTicketClipper(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${ticket.businessName} (${ticket.branchId})',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isClosed
                                    ? const Color(0x1A10B981)
                                    : const Color(0x1AD4AF37),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ticket.isVipPass
                                    ? 'VIP PASS • ${isClosed ? "EXITED" : "ACTIVE"}'
                                    : (isClosed
                                        ? 'PAID & CHECKED OUT'
                                        : 'ACTIVE SIGNED TOKEN'),
                                style: TextStyle(
                                  color: isClosed
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF9A7B16),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ticket.tokenNumber,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _row('Vehicle Class',
                                AppLocalizations.tr(ticket.vehicleType.labelKey)),
                            _row('Plate Number', ticket.plateNumber),
                            _row('Driver / Owner', ticket.ownerName),
                            _row('Location Bay', ticket.locationSlot),
                            _row(
                              'Entry Time',
                              DateFormat('dd MMM yyyy, hh:mm:ss a')
                                  .format(ticket.entryTime),
                            ),
                            if (ticket.exitTime != null)
                              _row(
                                'Exit Time',
                                DateFormat('dd MMM yyyy, hh:mm:ss a')
                                    .format(ticket.exitTime!),
                              ),
                            if (ticket.taxPercent > 0)
                              _row(
                                'Subtotal + VAT (${ticket.taxPercent.toStringAsFixed(0)}%)',
                                '${ticket.currency} ${subtotal.toStringAsFixed(0)}',
                              ),
                            _row(
                              'Total Fee',
                              '${ticket.currency} ${totalFee.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                            const SizedBox(height: 18),
                            const DashedDivider(),
                            const SizedBox(height: 18),
                            BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: ticket.signedQrData,
                              width: 130,
                              height: 130,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'HMAC Signature: ${ticket.qrSignature}',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Developer: Muhammad Umair Sattar | © 2026',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: theme.textOnAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _exportThermalPdf,
                        icon: const Icon(Icons.print_rounded),
                        label: Text(
                          AppLocalizations.tr('print_receipt'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DeveloperWatermark(theme: theme),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isBold
                    ? const Color(0xFF047857)
                    : const Color(0xFF0F172A),
                fontSize: isBold ? 15.5 : 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
