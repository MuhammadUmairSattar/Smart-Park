import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_core.dart';

final sharedPrefsProvider = Provider<SharedPreferences?>((ref) => null);
final initialSessionProvider = Provider<AuthSession?>((ref) => null);
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthState {
  final AuthSession? session;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.session,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    bool clearSession = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final initial = ref.read(initialSessionProvider);
    if (initial != null) {
      Future.microtask(_verifySessionSilently);
      return AuthState(session: initial);
    }
    return const AuthState();
  }

  ApiService get _api => ref.read(apiServiceProvider);

  Future<void> _verifySessionSilently() async {
    final result = await _api.refreshSessionDetailed();
    if (result == RefreshResult.revoked) {
      state = AuthState(
        errorMessage: AppLocalizations.tr('err_session_expired'),
      );
    } else if (result == RefreshResult.refreshed) {
      final updated = await _api.readStoredSession();
      if (updated != null) {
        state = AuthState(session: updated);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _api.login(email, password);
      state = AuthState(session: session, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toLocalizedMessage());
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String branchId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _api.register(
        fullName: fullName,
        email: email,
        password: password,
        branchId: branchId,
      );
      state = AuthState(session: session, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toLocalizedMessage());
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _api.refreshSessionDetailed();
    if (res == RefreshResult.revoked) {
      state = const AuthState(isLoading: false);
      return false;
    }
    final session = await _api.readStoredSession();
    state = AuthState(session: session, isLoading: false);
    return session != null;
  }

  Future<void> logout() async {
    await _api.clearSession();
    state = const AuthState();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

enum VehicleType {
  car('car', Icons.directions_car_rounded),
  motorcycle('motorcycle', Icons.two_wheeler_rounded),
  cycle('cycle', Icons.pedal_bike_rounded),
  rickshaw('rickshaw', Icons.electric_rickshaw_rounded),
  tractor('tractor', Icons.agriculture_rounded),
  mazda('mazda', Icons.local_shipping_outlined),
  dumper('dumper', Icons.fire_truck_rounded),
  truck('truck', Icons.local_shipping_rounded),
  other('other', Icons.category_rounded);

  final String labelKey;
  final IconData icon;
  const VehicleType(this.labelKey, this.icon);
}

class VehicleRateConfig {
  final double baseFee;
  final double hourlyRate;
  final int graceMinutes;
  final bool enabled;

  const VehicleRateConfig({
    this.baseFee = 0,
    this.hourlyRate = 0,
    this.graceMinutes = 0,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'baseFee': baseFee,
        'hourlyRate': hourlyRate,
        'graceMinutes': graceMinutes,
        'enabled': enabled,
      };

  factory VehicleRateConfig.fromJson(Map<String, dynamic> j) =>
      VehicleRateConfig(
        baseFee: (j['baseFee'] as num?)?.toDouble() ?? 0,
        hourlyRate: (j['hourlyRate'] as num?)?.toDouble() ?? 0,
        graceMinutes: (j['graceMinutes'] as num?)?.toInt() ?? 0,
        enabled: j['enabled'] as bool? ?? true,
      );
}

class BranchConfig {
  final String id;
  final String name;
  const BranchConfig({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory BranchConfig.fromJson(Map<String, dynamic> j) => BranchConfig(
        id: j['id'] as String? ?? 'MAIN',
        name: j['name'] as String? ?? 'Site 01',
      );
}
class BusinessSettings {
  final String businessName;
  final String currency;
  final String defaultSlot;
  final bool hourlyBilling;
  final double taxPercent;
  final int themeIndex;
  final int designStyleIndex;
  final String activeBranchId;
  final String countryFlag;
  final List<BranchConfig> branches;
  final Map<VehicleType, VehicleRateConfig> rates;

  const BusinessSettings({
    required this.businessName,
    required this.currency,
    required this.defaultSlot,
    required this.hourlyBilling,
    required this.taxPercent,
    required this.themeIndex,
    required this.designStyleIndex,
    required this.activeBranchId,
    this.countryFlag = '🇵🇰',
    required this.branches,
    required this.rates,
  });

  factory BusinessSettings.initial() => BusinessSettings(
        businessName: 'SmartPark Pro',
        currency: 'Rs.',
        defaultSlot: 'Zone A - Bay 01',
        hourlyBilling: true,
        taxPercent: 0,
        themeIndex: 0,
        designStyleIndex: 0,
        activeBranchId: 'MAIN',
        countryFlag: '🇵🇰',
        branches: const [
          BranchConfig(id: 'MAIN', name: 'Site 01'),
          BranchConfig(id: 'SITE2', name: 'Site 02'),
        ],
        rates: {
          for (final v in VehicleType.values)
            v: const VehicleRateConfig(
                baseFee: 0, hourlyRate: 0, graceMinutes: 0, enabled: true),
        },
      );

  AppThemePreset get activeTheme => AppThemePresets.getByIndex(themeIndex);
  CardDesignStyle get activeStyle => CardDesignStyle
      .values[designStyleIndex.clamp(0, CardDesignStyle.values.length - 1)];

  BranchConfig get activeBranch => branches.firstWhere(
        (b) => b.id == activeBranchId,
        orElse: () => branches.first,
      );

  BusinessSettings copyWith({
    String? businessName,
    String? currency,
    String? defaultSlot,
    bool? hourlyBilling,
    double? taxPercent,
    int? themeIndex,
    int? designStyleIndex,
    String? activeBranchId,
    String? countryFlag,
    List<BranchConfig>? branches,
    Map<VehicleType, VehicleRateConfig>? rates,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      defaultSlot: defaultSlot ?? this.defaultSlot,
      hourlyBilling: hourlyBilling ?? this.hourlyBilling,
      taxPercent: taxPercent ?? this.taxPercent,
      themeIndex: themeIndex ?? this.themeIndex,
      designStyleIndex: designStyleIndex ?? this.designStyleIndex,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      countryFlag: countryFlag ?? this.countryFlag,
      branches: branches ?? this.branches,
      rates: rates ?? this.rates,
    );
  }
}

class SettingsNotifier extends Notifier<BusinessSettings> {
  static const _prefsKey = 'smartpark_business_settings_v4';

  @override
  BusinessSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs != null) return _decodeFromPrefs(prefs);
    return BusinessSettings.initial();
  }

  BusinessSettings _decodeFromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return BusinessSettings.initial();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ratesMap = <VehicleType, VehicleRateConfig>{};
      final rawRates = (map['rates'] as Map<String, dynamic>?) ?? {};
      for (final v in VehicleType.values) {
        ratesMap[v] = rawRates[v.name] != null
            ? VehicleRateConfig.fromJson(
                rawRates[v.name] as Map<String, dynamic>)
            : const VehicleRateConfig();
      }
      final rawBranches = (map['branches'] as List<dynamic>?) ?? [];
      final branches = rawBranches.isNotEmpty
          ? rawBranches
              .map((e) => BranchConfig.fromJson(e as Map<String, dynamic>))
              .toList()
          : BusinessSettings.initial().branches;

      return BusinessSettings(
        businessName: map['businessName'] as String? ?? 'SmartPark Pro',
        currency: map['currency'] as String? ?? 'Rs.',
        defaultSlot: map['defaultSlot'] as String? ?? 'Zone A - Bay 01',
        hourlyBilling: map['hourlyBilling'] as bool? ?? true,
        taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
        themeIndex: map['themeIndex'] as int? ?? 0,
        designStyleIndex: map['designStyleIndex'] as int? ?? 0,
        activeBranchId: map['activeBranchId'] as String? ?? branches.first.id,
        countryFlag: map['countryFlag'] as String? ?? '🇵🇰',
        branches: branches,
        rates: ratesMap,
      );
    } catch (_) {
      return BusinessSettings.initial();
    }
  }

  Future<void> _save(BusinessSettings s) async {
    state = s;
    final prefs =
        ref.read(sharedPrefsProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'businessName': s.businessName,
        'currency': s.currency,
        'defaultSlot': s.defaultSlot,
        'hourlyBilling': s.hourlyBilling,
        'taxPercent': s.taxPercent,
        'themeIndex': s.themeIndex,
        'designStyleIndex': s.designStyleIndex,
        'activeBranchId': s.activeBranchId,
        'countryFlag': s.countryFlag,
        'branches': s.branches.map((b) => b.toJson()).toList(),
        'rates': {for (final e in s.rates.entries) e.key.name: e.value.toJson()},
      }),
    );
  }

  Future<void> updateAll(BusinessSettings updated) => _save(updated);
  Future<void> setTheme(int index) => _save(state.copyWith(themeIndex: index));
  Future<void> setDesignStyle(int index) =>
      _save(state.copyWith(designStyleIndex: index));
  Future<void> setActiveBranch(String id) =>
      _save(state.copyWith(activeBranchId: id));

  Future<void> renameActiveBranch(String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    final updated = state.branches
        .map((b) => b.id == state.activeBranchId
            ? BranchConfig(id: b.id, name: clean)
            : b)
        .toList();
    await _save(state.copyWith(branches: updated));
  }

  Future<void> applyCountryPreset(CountryPreset preset) async {
    await AppLocalizations.setLanguageByCode(preset.languageCode);
    await _save(state.copyWith(
      currency: preset.currencySymbol,
      countryFlag: preset.flag,
    ));
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, BusinessSettings>(SettingsNotifier.new);

class VipPass {
  final String passId;
  final String plateNumber;
  final String ownerName;
  final VehicleType vehicleType;
  final String branchId;
  final DateTime validUntil;

  const VipPass({
    required this.passId,
    required this.plateNumber,
    required this.ownerName,
    required this.vehicleType,
    required this.branchId,
    required this.validUntil,
  });

  bool get isValid => validUntil.isAfter(DateTime.now());

  Map<String, dynamic> toDbMap() => {
        'pass_id': passId,
        'plate_number': plateNumber.toUpperCase(),
        'owner_name': ownerName,
        'vehicle_type': vehicleType.name,
        'branch_id': branchId,
        'valid_until': validUntil.toIso8601String(),
      };

  factory VipPass.fromDbMap(Map<String, dynamic> m) => VipPass(
        passId: m['pass_id'] as String,
        plateNumber: m['plate_number'] as String,
        ownerName: m['owner_name'] as String,
        vehicleType: VehicleType.values.firstWhere(
          (v) => v.name == m['vehicle_type'],
          orElse: () => VehicleType.car,
        ),
        branchId: m['branch_id'] as String,
        validUntil: DateTime.parse(m['valid_until'] as String),
      );
}

enum TicketStatus { parked, checkedOut }

class ParkingTicket {
  final String tokenNumber;
  final String branchId;
  final String businessName;
  final String currency;
  final VehicleType vehicleType;
  final String? customVehicleName;
  final String plateNumber;
  final String ownerName;
  final String locationSlot;
  final double baseFee;
  final double hourlyRate;
  final int graceMinutes;
  final double taxPercent;
  final bool hourlyBilling;
  final bool isVipPass;
  final DateTime entryTime;
  final DateTime? exitTime;
  final TicketStatus status;
  final String qrSignature;
  final bool isSynced;

  const ParkingTicket({
    required this.tokenNumber,
    required this.branchId,
    required this.businessName,
    required this.currency,
    required this.vehicleType,
    this.customVehicleName,
    required this.plateNumber,
    required this.ownerName,
    required this.locationSlot,
    required this.baseFee,
    required this.hourlyRate,
    required this.graceMinutes,
    required this.taxPercent,
    required this.hourlyBilling,
    required this.isVipPass,
    required this.entryTime,
    this.exitTime,
    this.status = TicketStatus.parked,
    required this.qrSignature,
    this.isSynced = false,
  });

  String get vehicleDisplayName =>
      (customVehicleName != null && customVehicleName!.trim().isNotEmpty)
          ? customVehicleName!.trim()
          : AppLocalizations.tr(vehicleType.labelKey);

  String get signedQrData =>
      '${QrCryptoService.buildPayload(tokenNumber: tokenNumber, plateNumber: plateNumber, branchId: branchId, entryTime: entryTime)}|$qrSignature';

  double calculateSubtotal([DateTime? refTime]) {
    if (isVipPass) return 0;
    final end = exitTime ?? refTime ?? DateTime.now();
    final totalMinutes = end.difference(entryTime).inMinutes;
    if (graceMinutes > 0 &&
        status == TicketStatus.checkedOut &&
        totalMinutes <= graceMinutes) {
      return 0;
    }
    if (!hourlyBilling) return baseFee;

    final billableMinutes = totalMinutes - 60;
    if (billableMinutes <= 0) return baseFee;
    final extraHours = (billableMinutes / 60.0).ceil();
    return baseFee + (extraHours * hourlyRate);
  }

  double calculateTotalFee([DateTime? refTime]) {
    final subtotal = calculateSubtotal(refTime);
    if (subtotal <= 0 || taxPercent <= 0) return subtotal;
    return subtotal + (subtotal * (taxPercent / 100.0));
  }

  ParkingTicket copyWith({
    DateTime? exitTime,
    TicketStatus? status,
    bool? isSynced,
  }) {
    return ParkingTicket(
      tokenNumber: tokenNumber,
      branchId: branchId,
      businessName: businessName,
      currency: currency,
      vehicleType: vehicleType,
      customVehicleName: customVehicleName,
      plateNumber: plateNumber,
      ownerName: ownerName,
      locationSlot: locationSlot,
      baseFee: baseFee,
      hourlyRate: hourlyRate,
      graceMinutes: graceMinutes,
      taxPercent: taxPercent,
      hourlyBilling: hourlyBilling,
      isVipPass: isVipPass,
      entryTime: entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
      qrSignature: qrSignature,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'token_number': tokenNumber,
        'branch_id': branchId,
        'business_name': businessName,
        'currency': currency,
        'vehicle_type': vehicleType.name,
        'custom_vehicle_name': customVehicleName,
        'plate_number': plateNumber,
        'owner_name': ownerName,
        'location_slot': locationSlot,
        'base_fee': baseFee,
        'hourly_rate': hourlyRate,
        'grace_minutes': graceMinutes,
        'tax_percent': taxPercent,
        'hourly_billing': hourlyBilling ? 1 : 0,
        'is_vip_pass': isVipPass ? 1 : 0,
        'entry_time': entryTime.toIso8601String(),
        'exit_time': exitTime?.toIso8601String(),
        'total_fee': calculateTotalFee(),
        'status': status.name,
        'qr_signature': qrSignature,
        'is_synced': isSynced ? 1 : 0,
      };

  factory ParkingTicket.fromDbMap(Map<String, dynamic> m) => ParkingTicket(
        tokenNumber: m['token_number'] as String,
        branchId: m['branch_id'] as String,
        businessName: m['business_name'] as String,
        currency: m['currency'] as String,
        vehicleType: VehicleType.values.firstWhere(
          (v) => v.name == m['vehicle_type'],
          orElse: () => VehicleType.car,
        ),
        customVehicleName: m['custom_vehicle_name'] as String?,
        plateNumber: m['plate_number'] as String,
        ownerName: m['owner_name'] as String,
        locationSlot: m['location_slot'] as String,
        baseFee: (m['base_fee'] as num).toDouble(),
        hourlyRate: (m['hourly_rate'] as num).toDouble(),
        graceMinutes: (m['grace_minutes'] as num).toInt(),
        taxPercent: (m['tax_percent'] as num).toDouble(),
        hourlyBilling: (m['hourly_billing'] as num) == 1,
        isVipPass: (m['is_vip_pass'] as num) == 1,
        entryTime: DateTime.parse(m['entry_time'] as String),
        exitTime: m['exit_time'] != null
            ? DateTime.parse(m['exit_time'] as String)
            : null,
        status: m['status'] == TicketStatus.checkedOut.name
            ? TicketStatus.checkedOut
            : TicketStatus.parked,
        qrSignature: m['qr_signature'] as String,
        isSynced: (m['is_synced'] as num) == 1,
      );

  Map<String, dynamic> toApiPayload() => {
        'token_number': tokenNumber,
        'branch_id': branchId,
        'vehicle_type':
            (customVehicleName != null && customVehicleName!.isNotEmpty)
                ? customVehicleName
                : vehicleType.name,
        'plate_number': plateNumber,
        'owner_name': ownerName,
        'location_slot': locationSlot,
        'base_fee': baseFee,
        'hourly_rate': hourlyRate,
        'grace_minutes': graceMinutes,
        'tax_percent': taxPercent,
        'is_vip_pass': isVipPass,
        'entry_time': entryTime.toIso8601String(),
        'exit_time': exitTime?.toIso8601String(),
        'total_fee': calculateTotalFee(),
        'status': status.name,
        'qr_signature': qrSignature,
      };
}
class ParkingDatabase {
  ParkingDatabase._internal([this._db]);
  static final ParkingDatabase instance = ParkingDatabase._internal();

  @visibleForTesting
  factory ParkingDatabase.withDatabase(Database db) =>
      ParkingDatabase._internal(db);

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = p.join(await getDatabasesPath(), 'smart_park_pro_v3.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
    return _db!;
  }

  static Future<void> upgradeSchema(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE tickets ADD COLUMN custom_vehicle_name TEXT');
    }
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets (
        token_number TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        business_name TEXT NOT NULL,
        currency TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        custom_vehicle_name TEXT,
        plate_number TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        location_slot TEXT NOT NULL,
        base_fee REAL NOT NULL,
        hourly_rate REAL NOT NULL,
        grace_minutes INTEGER NOT NULL,
        tax_percent REAL NOT NULL,
        hourly_billing INTEGER NOT NULL,
        is_vip_pass INTEGER NOT NULL,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        total_fee REAL NOT NULL,
        status TEXT NOT NULL,
        qr_signature TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token_number TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE vip_passes (
        pass_id TEXT PRIMARY KEY,
        plate_number TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        valid_until TEXT NOT NULL
      )
    ''');
  }

  Future<List<ParkingTicket>> fetchAllTickets() async {
    final db = await database;
    final rows = await db.query('tickets', orderBy: 'entry_time DESC');
    return rows.map(ParkingTicket.fromDbMap).toList();
  }

  Future<void> insertTicketWithQueue(ParkingTicket ticket) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('tickets', ticket.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('sync_queue', {
        'token_number': ticket.tokenNumber,
        'action': 'CREATE',
        'payload_json': jsonEncode(ticket.toApiPayload()),
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> updateCheckoutWithQueue(ParkingTicket ticket) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('tickets', ticket.toDbMap(),
          where: 'token_number = ?', whereArgs: [ticket.tokenNumber]);
      await txn.insert('sync_queue', {
        'token_number': ticket.tokenNumber,
        'action': 'CHECKOUT',
        'payload_json': jsonEncode(ticket.toApiPayload()),
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchSyncQueue() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> markSynced(int queueId, String tokenNumber) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
      final remaining = await txn.query('sync_queue',
          where: 'token_number = ?', whereArgs: [tokenNumber]);
      if (remaining.isEmpty) {
        await txn.update('tickets', {'is_synced': 1},
            where: 'token_number = ?', whereArgs: [tokenNumber]);
      }
    });
  }

  Future<List<VipPass>> fetchVipPasses() async {
    final db = await database;
    final rows = await db.query('vip_passes', orderBy: 'valid_until DESC');
    return rows.map(VipPass.fromDbMap).toList();
  }

  Future<void> upsertVipPass(VipPass pass) async {
    final db = await database;
    await db.insert('vip_passes', pass.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteVipPass(String passId) async {
    final db = await database;
    await db.delete('vip_passes', where: 'pass_id = ?', whereArgs: [passId]);
  }

  Future<VipPass?> findActiveVipPass(String plateNumber, String branchId) async {
    final db = await database;
    final rows = await db.query('vip_passes',
        where: 'plate_number = ? AND branch_id = ?',
        whereArgs: [plateNumber.toUpperCase().trim(), branchId]);
    for (final row in rows) {
      final pass = VipPass.fromDbMap(row);
      if (pass.isValid) return pass;
    }
    return null;
  }
}

class ParkingState {
  final List<ParkingTicket> tickets;
  final List<VipPass> vipPasses;
  final int pendingSyncCount;
  final bool isLoading;
  final bool isSyncing;

  const ParkingState({
    this.tickets = const [],
    this.vipPasses = const [],
    this.pendingSyncCount = 0,
    this.isLoading = false,
    this.isSyncing = false,
  });

  List<ParkingTicket> forBranch(String branchId) =>
      tickets.where((t) => t.branchId == branchId).toList();

  List<ParkingTicket> activeTicketsForBranch(String branchId) => tickets
      .where((t) => t.branchId == branchId && t.status == TicketStatus.parked)
      .toList();

  double todayRevenueForBranch(String branchId) {
    final now = DateTime.now();
    return tickets
        .where((t) =>
            t.branchId == branchId &&
            t.entryTime.year == now.year &&
            t.entryTime.month == now.month &&
            t.entryTime.day == now.day)
        .fold(0.0, (sum, t) => sum + t.calculateTotalFee());
  }

  double monthlyRevenueForBranch(String branchId) {
    final now = DateTime.now();
    return tickets
        .where((t) =>
            t.branchId == branchId &&
            t.entryTime.year == now.year &&
            t.entryTime.month == now.month)
        .fold(0.0, (sum, t) => sum + t.calculateTotalFee());
  }

  Map<VehicleType, int> vehicleCountsForBranch(String branchId) {
    final counts = <VehicleType, int>{};
    for (final t in forBranch(branchId)) {
      counts[t.vehicleType] = (counts[t.vehicleType] ?? 0) + 1;
    }
    return counts;
  }

  ParkingState copyWith({
    List<ParkingTicket>? tickets,
    List<VipPass>? vipPasses,
    int? pendingSyncCount,
    bool? isLoading,
    bool? isSyncing,
  }) {
    return ParkingState(
      tickets: tickets ?? this.tickets,
      vipPasses: vipPasses ?? this.vipPasses,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

final parkingDbProvider =
    Provider<ParkingDatabase>((ref) => ParkingDatabase.instance);

class ParkingNotifier extends Notifier<ParkingState> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  ParkingState build() {
    ref.onDispose(() => _connSub?.cancel());
    _init();
    return const ParkingState(isLoading: true);
  }

  ParkingDatabase get _db => ref.read(parkingDbProvider);
  ApiService get _api => ref.read(apiServiceProvider);

  Future<void> _init() async {
    await reloadFromDb();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) syncPendingQueue();
    });
    unawaited(syncPendingQueue());
  }

  Future<void> reloadFromDb() async {
    final tickets = await _db.fetchAllTickets();
    final passes = await _db.fetchVipPasses();
    final queue = await _db.fetchSyncQueue();
    state = state.copyWith(
      tickets: tickets,
      vipPasses: passes,
      pendingSyncCount: queue.length,
      isLoading: false,
    );
  }

  Future<ParkingTicket> issueTicket({
    required VehicleType type,
    String? customVehicleName,
    double? customBaseFee,
    required String plateNumber,
    required String ownerName,
    required String slot,
  }) async {
    state = state.copyWith(isLoading: true);
    final cfg = ref.read(settingsProvider);
    final normalizedPlate = plateNumber.toUpperCase().trim();
    final vip = await _db.findActiveVipPass(normalizedPlate, cfg.activeBranchId);
    final rate = cfg.rates[type] ?? const VehicleRateConfig();
    final effectiveBaseFee = customBaseFee ?? rate.baseFee;

    final now = DateTime.now();
    final suffix = (now.microsecondsSinceEpoch % 90000 + 10000).toString();
    final tokenNo =
        'TKN-${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$suffix';

    final payload = QrCryptoService.buildPayload(
      tokenNumber: tokenNo,
      plateNumber: normalizedPlate,
      branchId: cfg.activeBranchId,
      entryTime: now,
    );
    final sig = QrCryptoService.signPayload(payload);

    final ticket = ParkingTicket(
      tokenNumber: tokenNo,
      branchId: cfg.activeBranchId,
      businessName: cfg.businessName,
      currency: cfg.currency,
      vehicleType: type,
      customVehicleName: customVehicleName?.trim(),
      plateNumber: normalizedPlate,
      ownerName: ownerName.trim(),
      locationSlot: slot.trim(),
      baseFee: effectiveBaseFee,
      hourlyRate: rate.hourlyRate,
      graceMinutes: rate.graceMinutes,
      taxPercent: cfg.taxPercent,
      hourlyBilling: cfg.hourlyBilling,
      isVipPass: vip != null,
      entryTime: now,
      qrSignature: sig,
    );

    await _db.insertTicketWithQueue(ticket);
    await reloadFromDb();
    unawaited(syncPendingQueue());
    return ticket;
  }

  Future<ParkingTicket?> checkOutTicket(String tokenNumber) async {
    final idx = state.tickets.indexWhere(
      (t) =>
          t.tokenNumber == tokenNumber && t.status == TicketStatus.parked,
    );
    if (idx == -1) return null;

    final updated = state.tickets[idx].copyWith(
      exitTime: DateTime.now(),
      status: TicketStatus.checkedOut,
      isSynced: false,
    );

    await _db.updateCheckoutWithQueue(updated);
    await reloadFromDb();
    unawaited(syncPendingQueue());
    return updated;
  }

  Future<void> addVipPass(VipPass pass) async {
    await _db.upsertVipPass(pass);
    await reloadFromDb();
  }

  Future<void> removeVipPass(String passId) async {
    await _db.deleteVipPass(passId);
    await reloadFromDb();
  }

  Future<void> syncPendingQueue() async {
    if (state.isSyncing) return;
    final queue = await _db.fetchSyncQueue();
    if (queue.isEmpty) return;

    state = state.copyWith(isSyncing: true);
    try {
      for (final item in queue) {
        final queueId = item['id'] as int;
        final tokenNo = item['token_number'] as String;
        final action = item['action'] as String;
        final payload =
            jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;

        try {
          if (action == 'CREATE') {
            await _api.client.post<void>('/parking/tickets', data: payload);
          } else {
            await _api.client.post<void>(
                '/parking/tickets/$tokenNo/checkout',
                data: payload);
          }
          await _db.markSynced(queueId, tokenNo);
        } on DioException {
          break;
        }
      }
    } finally {
      final tickets = await _db.fetchAllTickets();
      final remaining = await _db.fetchSyncQueue();
      state = state.copyWith(
        tickets: tickets,
        pendingSyncCount: remaining.length,
        isSyncing: false,
      );
    }
  }

  String buildCsvReport(String branchId) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buf = StringBuffer()
      ..writeln(
          'TokenNumber,BranchId,VehicleType,PlateNumber,OwnerName,Zone,EntryTime,ExitTime,Status,VipPass,TotalFee,Currency,Synced');
    for (final t in state.forBranch(branchId)) {
      buf.writeln([
        esc(t.tokenNumber),
        esc(t.branchId),
        esc(t.vehicleDisplayName),
        esc(t.plateNumber),
        esc(t.ownerName),
        esc(t.locationSlot),
        esc(t.entryTime.toIso8601String()),
        esc(t.exitTime?.toIso8601String() ?? ''),
        esc(t.status.name),
        t.isVipPass ? 'YES' : 'NO',
        t.calculateTotalFee().toStringAsFixed(2),
        esc(t.currency),
        t.isSynced ? 'SYNCED' : 'PENDING',
      ].join(','));
    }
    return buf.toString();
  }
}

final parkingProvider =
    NotifierProvider<ParkingNotifier, ParkingState>(ParkingNotifier.new);
