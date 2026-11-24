import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_park_pro/core/app_core.dart';
import 'package:smart_park_pro/features/auth/auth_screen.dart';
import 'package:smart_park_pro/features/parking/parking_logic.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Parking Fee & Tariff Calculations', () {
    test('Waives fee within grace period', () {
      final entry = DateTime(2026, 11, 21, 10, 0);
      final exit = DateTime(2026, 11, 21, 10, 12);
      final ticket = ParkingTicket(
        tokenNumber: 'TKN-1',
        branchId: 'MAIN',
        businessName: 'Test Plaza',
        currency: 'Rs.',
        vehicleType: VehicleType.car,
        plateNumber: 'LEA-2026',
        ownerName: 'Ali',
        locationSlot: 'A1',
        baseFee: 100,
        hourlyRate: 50,
        graceMinutes: 15,
        taxPercent: 10,
        hourlyBilling: true,
        isVipPass: false,
        entryTime: entry,
        exitTime: exit,
        qrSignature: 'sig',
      );
      expect(ticket.calculateTotalFee(), 0);
    });

    test('Calculates base + overtime + VAT accurately', () {
      final entry = DateTime(2026, 11, 21, 10, 0);
      final exit = DateTime(2026, 11, 21, 12, 30);
      final ticket = ParkingTicket(
        tokenNumber: 'TKN-2',
        branchId: 'MAIN',
        businessName: 'Test Plaza',
        currency: 'Rs.',
        vehicleType: VehicleType.car,
        plateNumber: 'ICT-991',
        ownerName: 'Omar',
        locationSlot: 'B2',
        baseFee: 100,
        hourlyRate: 50,
        graceMinutes: 15,
        taxPercent: 10,
        hourlyBilling: true,
        isVipPass: false,
        entryTime: entry,
        exitTime: exit,
        qrSignature: 'sig',
      );
      expect(ticket.calculateSubtotal(), 200);
      expect(ticket.calculateTotalFee(), 220);
    });

    test('VIP pass waives all parking fees', () {
      final entry = DateTime(2026, 11, 21, 8, 0);
      final exit = DateTime(2026, 11, 21, 18, 0);
      final ticket = ParkingTicket(
        tokenNumber: 'TKN-3',
        branchId: 'MAIN',
        businessName: 'Test Plaza',
        currency: 'Rs.',
        vehicleType: VehicleType.truck,
        plateNumber: 'VIP-001',
        ownerName: 'VIP Member',
        locationSlot: 'VIP-1',
        baseFee: 500,
        hourlyRate: 200,
        graceMinutes: 0,
        taxPercent: 15,
        hourlyBilling: true,
        isVipPass: true,
        entryTime: entry,
        exitTime: exit,
        status: TicketStatus.checkedOut,
        qrSignature: 'sig',
      );
      expect(ticket.calculateTotalFee(), 0);
    });
  });

  group('Cryptographic HMAC QR Verification', () {
    test('Verifies valid signed QR and rejects tampered plate', () {
      final entry = DateTime.utc(2026, 11, 21, 12, 0);
      final signed = QrCryptoService.encodeSignedQr(
        tokenNumber: 'TKN-261121-12345',
        plateNumber: 'LEA-2026',
        branchId: 'MAIN',
        entryTime: entry,
        secret: 'unit_test_secret_key',
      );

      expect(
        QrCryptoService.verifyAndExtractToken(signed,
            secret: 'unit_test_secret_key'),
        'TKN-261121-12345',
      );

      final tampered = signed.replaceFirst('LEA-2026', 'FAKE-999');
      expect(
        QrCryptoService.verifyAndExtractToken(tampered,
            secret: 'unit_test_secret_key'),
        isNull,
      );
    });
  });

  group('SQLite Persistence & Offline Sync Queue', () {
    test('Persists ticket check-in, check-out, and offline queue', () async {
      final rawDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: ParkingDatabase.createSchema,
      );
      final db = ParkingDatabase.withDatabase(rawDb);

      final ticket = ParkingTicket(
        tokenNumber: 'TKN-TEST-1',
        branchId: 'MAIN',
        businessName: 'Plaza',
        currency: 'Rs.',
        vehicleType: VehicleType.motorcycle,
        plateNumber: 'RIW-55',
        ownerName: 'Zain',
        locationSlot: 'M-04',
        baseFee: 30,
        hourlyRate: 15,
        graceMinutes: 10,
        taxPercent: 0,
        hourlyBilling: true,
        isVipPass: false,
        entryTime: DateTime.now().subtract(const Duration(minutes: 45)),
        qrSignature: 'abcd1234abcd1234',
      );

      await db.insertTicketWithQueue(ticket);
      var all = await db.fetchAllTickets();
      var queue = await db.fetchSyncQueue();
      expect(all.length, 1);
      expect(queue.length, 1);
      expect(queue.first['action'], 'CREATE');

      final closed = ticket.copyWith(
        exitTime: DateTime.now(),
        status: TicketStatus.checkedOut,
      );
      await db.updateCheckoutWithQueue(closed);
      all = await db.fetchAllTickets();
      queue = await db.fetchSyncQueue();
      expect(all.first.status, TicketStatus.checkedOut);
      expect(queue.length, 2);

      await rawDb.close();
    });
  });

  group('AuthScreen Widget Flow', () {
    testWidgets('Shows friendly validation error on empty submit',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(
        find.text(AppLocalizations.tr('validation_auth')),
        findsOneWidget,
      );
    });
  });
}
