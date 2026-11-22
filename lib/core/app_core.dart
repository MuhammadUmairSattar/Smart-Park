import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'themes.dart';
export 'themes.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.smartpark-enterprise.com/v1',
  );

  static const String qrHmacSecret = String.fromEnvironment(
    'QR_HMAC_SECRET',
    defaultValue: 'CHANGE_ME_IN_PRODUCTION_VIA_DART_DEFINE',
  );
}

class LanguageModel {
  final String code;
  final String name;
  final String flag;
  final bool isRtl;
  const LanguageModel(this.code, this.name, this.flag, {this.isRtl = false});
}

class AppLocalizations {
  static const _langPrefsKey = 'smartpark_selected_lang';
  static SharedPreferences? _prefs;

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel('en', 'English', '🇺🇸'),
    LanguageModel('ur', 'اردو', '🇵🇰', isRtl: true),
    LanguageModel('ar', 'العربية', '🇸🇦', isRtl: true),
  ];

  static final ValueNotifier<LanguageModel> currentLanguage =
      ValueNotifier(supportedLanguages[0]);

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final savedCode = prefs.getString(_langPrefsKey);
    if (savedCode != null) {
      currentLanguage.value = supportedLanguages.firstWhere(
        (l) => l.code == savedCode,
        orElse: () => supportedLanguages[0],
      );
    }
  }

  static Future<void> setLanguage(LanguageModel lang) async {
    currentLanguage.value = lang;
    await _prefs?.setString(_langPrefsKey, lang.code);
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app_name': 'SmartPark Pro',
      'login_sub': 'Enterprise Parking Operations Portal',
      'email': 'Operator Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'branch_code': 'Site / Branch ID',
      'login_btn': 'Sign In',
      'signup_btn': 'Register Operator',
      'toggle_signup': 'Need an operator account? Register',
      'toggle_login': 'Already registered? Sign In',
      'biometric': 'Unlock with Biometrics',
      'biometric_reason': 'Verify your identity to unlock your active session',
      'biometric_unavailable':
          'Biometric unlock is unavailable or not yet enabled for a signed-in session.',
      'select_vehicle': 'SELECT VEHICLE CLASS',
      'scan_plate': 'SCAN LICENSE PLATE (OCR)',
      'scanning_plate': 'ANALYZING PLATE...',
      'plate_no': 'Registration Plate Number',
      'owner_name': 'Driver / Owner Name',
      'location': 'Parking Bay / Zone',
      'generate_token': 'ISSUE PARKING TOKEN',
      'new_entry': 'Entry',
      'active_tab': 'Active',
      'analytics_tab': 'Admin',
      'settings': 'Rates, Branches & 50 Themes',
      'qr_exit': 'QR Exit Scanner',
      'exit_btn': 'CHECK OUT',
      'revenue': 'Today Revenue',
      'parked': 'Active Units',
      'pending_sync': 'Pending Sync',
      'no_active': 'No active vehicles parked.',
      'validation_entry':
          'Please enter both Registration Plate and Driver Name.',
      'validation_auth':
          'Please enter a valid email and a password of at least 6 characters.',
      'err_network': 'Network unreachable. Please check your connection.',
      'err_invalid_creds': 'Invalid email or password.',
      'err_session_expired':
          'Your session expired. Please sign in with your password.',
      'err_server': 'Server error occurred. Please try again shortly.',
      'err_qr_forged': 'Security Alert: Invalid or tampered QR ticket signature!',
      'err_ticket_not_found': 'Ticket not found or already checked out.',
      'vip_pass_applied': 'Active VIP Pass detected — Entry fee waived.',
      'export_pdf': 'Export PDF Report',
      'export_csv': 'Export CSV Report',
      'print_receipt': 'PRINT THERMAL RECEIPT / PDF',
      'watermark':
          'Developer: Muhammad Umair Sattar | © 2026 All Rights Reserved',
      'car': 'Car',
      'motorcycle': 'Motorcycle',
      'cycle': 'Cycle',
      'rickshaw': 'Rickshaw',
      'tractor': 'Tractor',
      'mazda': 'Mazda',
      'dumper': 'Dumper',
      'truck': 'Heavy Truck',
    },
    'ur': {
      'app_name': 'اسمارٹ پارک پرو',
      'login_sub': 'انٹرپرائز پارکنگ آپریشنز پورٹل',
      'email': 'آپریٹر ای میل',
      'password': 'پاس ورڈ',
      'full_name': 'مکمل نام',
      'branch_code': 'برانچ / سائٹ آئی ڈی',
      'login_btn': 'سائن ان کریں',
      'signup_btn': 'آپریٹر رجسٹر کریں',
      'toggle_signup': 'نیا اکاؤنٹ بنانا ہے؟ رجسٹر کریں',
      'toggle_login': 'پہلے سے اکاؤنٹ ہے؟ سائن ان کریں',
      'biometric': 'بایومیٹرک سے ان لاک کریں',
      'biometric_reason': 'اپنے فعال سیشن کو ان لاک کرنے کے لیے تصدیق کریں',
      'biometric_unavailable':
          'بایومیٹرک دستیاب نہیں یا ابھی کسی فعال سیشن کے لیے سیٹ نہیں ہے۔',
      'select_vehicle': 'گاڑی کی قسم منتخب کریں',
      'scan_plate': 'نمبر پلیٹ اسکین کریں (OCR)',
      'scanning_plate': 'پلیٹ اسکین ہو رہی ہے...',
      'plate_no': 'گاڑی نمبر پلیٹ',
      'owner_name': 'ڈرائیور / مالک کا نام',
      'location': 'پارکنگ زون / بے',
      'generate_token': 'پارکنگ ٹوکن جاری کریں',
      'new_entry': 'انٹری',
      'active_tab': 'فعال',
      'analytics_tab': 'ایڈمن',
      'settings': 'فیس، برانچز اور 50 تھیمز',
      'qr_exit': 'QR ایگزٹ اسکینر',
      'exit_btn': 'چیک آؤٹ',
      'revenue': 'آج کی آمدنی',
      'parked': 'کھڑی گاڑیاں',
      'pending_sync': 'سنک باقی',
      'no_active': 'اس وقت کوئی گاڑی کھڑی نہیں ہے۔',
      'validation_entry': 'براہ کرم گاڑی نمبر اور ڈرائیور کا نام درج کریں۔',
      'validation_auth': 'درست ای میل اور کم از کم 6 حروف کا پاس ورڈ درج کریں۔',
      'err_network': 'انٹرنیٹ دستیاب نہیں۔ کنکشن چیک کریں۔',
      'err_invalid_creds': 'ای میل یا پاس ورڈ غلط ہے۔',
      'err_session_expired':
          'آپ کا سیشن ختم ہو گیا۔ دوبارہ پاس ورڈ سے لاگ ان کریں۔',
      'err_server': 'سرور میں مسئلہ آیا۔ کچھ دیر بعد کوشش کریں۔',
      'err_qr_forged': 'سیکیورٹی الرٹ: جعلی یا تبدیل شدہ QR ٹوکن مسترد!',
      'err_ticket_not_found': 'ٹوکن نہیں ملا یا پہلے ہی چیک آؤٹ ہو چکا ہے۔',
      'vip_pass_applied': 'فعال VIP پاس موجود ہے — انٹری فیس معاف۔',
      'export_pdf': 'PDF رپورٹ ایکسپورٹ',
      'export_csv': 'CSV رپورٹ ایکسپورٹ',
      'print_receipt': 'تھرمل رسید پرنٹ / PDF',
      'watermark': 'ڈویلپر: محمد عمیر ستار | جملہ حقوق محفوظ ہیں © 2026',
      'car': 'کار',
      'motorcycle': 'موٹر سائیکل',
      'cycle': 'سائیکل',
      'rickshaw': 'رکشہ',
      'tractor': 'ٹریکٹر',
      'mazda': 'مزدہ',
      'dumper': 'ڈمپر',
      'truck': 'بڑا ٹرک',
    },
    'ar': {
      'app_name': 'سمارت بارك برو',
      'login_sub': 'بوابة إدارة المواقف المؤسسية',
      'email': 'البريد الإلكتروني للمشغل',
      'password': 'كلمة المرور',
      'full_name': 'الاسم الكامل',
      'branch_code': 'معرف الفرع / الموقع',
      'login_btn': 'تسجيل الدخول',
      'signup_btn': 'تسجيل مشغل جديد',
      'toggle_signup': 'تحتاج إلى حساب مشغل؟ سجل الآن',
      'toggle_login': 'مسجل بالفعل؟ تسجيل الدخول',
      'biometric': 'فتح بالبصمة / الوجه',
      'biometric_reason': 'تحقق من هويتك لفتح جلستك النشطة',
      'biometric_unavailable':
          'المصادقة البيومترية غير متاحة أو غير مفعلة لجلسة نشطة.',
      'select_vehicle': 'اختر فئة المركبة',
      'scan_plate': 'مسح لوحة المركبة (OCR)',
      'scanning_plate': 'جاري تحليل اللوحة...',
      'plate_no': 'رقم لوحة المركبة',
      'owner_name': 'اسم السائق / المالك',
      'location': 'الموقع / الموقف',
      'generate_token': 'إصدار تذكرة وقوف',
      'new_entry': 'دخول',
      'active_tab': 'نشط',
      'analytics_tab': 'الإدارة',
      'settings': 'الأسعار والفروع و 50 ثيم',
      'qr_exit': 'ماسح الخروج QR',
      'exit_btn': 'تسجيل خروج',
      'revenue': 'إيرادات اليوم',
      'parked': 'المركبات النشطة',
      'pending_sync': 'بانتظار المزامنة',
      'no_active': 'لا توجد مركبات متوقفة حالياً.',
      'validation_entry': 'يرجى إدخال رقم اللوحة واسم السائق.',
      'validation_auth':
          'يرجى إدخال بريد إلكتروني صحيح وكلمة مرور من 6 أحرف على الأقل.',
      'err_network': 'لا يوجد اتصال بالإنترنت.',
      'err_invalid_creds': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
      'err_session_expired': 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
      'err_server': 'حدث خطأ في الخادم. حاول لاحقاً.',
      'err_qr_forged': 'تنبيه أمني: توقيع رمز QR غير صالح أو مزور!',
      'err_ticket_not_found': 'التذكرة غير موجودة أو تم تسجيل خروجها مسبقاً.',
      'vip_pass_applied': 'تصريح VIP نشط — تم إعفاء رسوم الدخول.',
      'export_pdf': 'تصدير تقرير PDF',
      'export_csv': 'تصدير تقرير CSV',
      'print_receipt': 'طباعة الإيصال / PDF',
      'watermark': 'المطور: محمد عمير ستار | جميع الحقوق محفوظة © 2026',
      'car': 'سيارة',
      'motorcycle': 'دراجة نارية',
      'cycle': 'دراجة',
      'rickshaw': 'توك توك',
      'tractor': 'جرار',
      'mazda': 'مازدا',
      'dumper': 'قلاب',
      'truck': 'شاحنة ثقيلة',
    },
  };

  static String tr(String key) {
    final code = currentLanguage.value.code;
    return _values[code]?[key] ?? _values['en']?[key] ?? key;
  }
}

class AuthSession {
  final String operatorId;
  final String email;
  final String role;
  final String branchId;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.operatorId,
    required this.email,
    required this.role,
    required this.branchId,
    required this.accessToken,
    required this.refreshToken,
  });
}

enum RefreshResult { refreshed, offline, revoked }

class AuthException implements Exception {
  final String translationKey;
  final String? serverMessage;
  const AuthException(this.translationKey, [this.serverMessage]);

  String toLocalizedMessage() {
    if (serverMessage != null && serverMessage!.isNotEmpty) {
      return serverMessage!;
    }
    return AppLocalizations.tr(translationKey);
  }
}

class ApiService {
  static const _kAccessToken = 'sp_access_token';
  static const _kRefreshToken = 'sp_refresh_token';
  static const _kOperatorEmail = 'sp_operator_email';
  static const _kOperatorId = 'sp_operator_id';
  static const _kOperatorRole = 'sp_operator_role';
  static const _kBranchId = 'sp_branch_id';
  static const _kBiometricEnabled = 'sp_biometric_enabled';

  final FlutterSecureStorage _storage;
  late final Dio _dio;
  late final Dio _refreshDio;
  Future<RefreshResult>? _refreshInFlight;

  ApiService({FlutterSecureStorage? storage, Dio? dioOverride})
      : _storage = storage ?? const FlutterSecureStorage() {
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio = dioOverride ?? Dio(baseOptions);
    _refreshDio = Dio(baseOptions);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _kAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/')) {
            final res = await refreshSessionDetailed();
            if (res == RefreshResult.refreshed) {
              final newAccess = await _storage.read(key: _kAccessToken);
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccess';
              try {
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  Future<AuthSession> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      return _persistAuthResponse(res.data ?? const {}, fallbackEmail: email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String branchId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'branch_id': branchId.trim(),
        },
      );
      return _persistAuthResponse(res.data ?? const {}, fallbackEmail: email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<RefreshResult> refreshSessionDetailed() async {
    if (_refreshInFlight != null) return _refreshInFlight!;
    _refreshInFlight = _executeRefresh();
    try {
      return await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<RefreshResult> _executeRefresh() async {
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshResult.revoked;
    }
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data ?? const {};
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String? ?? refreshToken;
      if (newAccess == null || newAccess.isEmpty) {
        await clearSession();
        return RefreshResult.revoked;
      }
      await _storage.write(key: _kAccessToken, value: newAccess);
      await _storage.write(key: _kRefreshToken, value: newRefresh);
      return RefreshResult.refreshed;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await clearSession();
        return RefreshResult.revoked;
      }
      return RefreshResult.offline;
    }
  }

  Future<bool> hasBiometricEnabledSession() async {
    final enabled = await _storage.read(key: _kBiometricEnabled);
    final refresh = await _storage.read(key: _kRefreshToken);
    return enabled == 'true' && refresh != null && refresh.isNotEmpty;
  }

  Future<AuthSession?> readStoredSession() async {
    try {
      final access = await _storage.read(key: _kAccessToken);
      final refresh = await _storage.read(key: _kRefreshToken);
      final email = await _storage.read(key: _kOperatorEmail);
      final id = await _storage.read(key: _kOperatorId);
      final role = await _storage.read(key: _kOperatorRole);
      final branch = await _storage.read(key: _kBranchId);

      if (access == null || refresh == null || email == null) return null;
      return AuthSession(
        operatorId: id ?? '',
        email: email,
        role: role ?? 'operator',
        branchId: branch ?? 'MAIN',
        accessToken: access,
        refreshToken: refresh,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kBiometricEnabled);
  }

  Future<AuthSession> _persistAuthResponse(
    Map<String, dynamic> data, {
    required String fallbackEmail,
  }) async {
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const AuthException('err_server');
    }

    final user = (data['user'] as Map<String, dynamic>?) ?? const {};
    final session = AuthSession(
      operatorId: (user['id'] ?? data['operator_id'] ?? '').toString(),
      email: (user['email'] as String?) ?? fallbackEmail.trim(),
      role: (user['role'] as String?) ?? 'operator',
      branchId: (user['branch_id'] as String?) ?? 'MAIN',
      accessToken: access,
      refreshToken: refresh,
    );

    await _storage.write(key: _kAccessToken, value: session.accessToken);
    await _storage.write(key: _kRefreshToken, value: session.refreshToken);
    await _storage.write(key: _kOperatorEmail, value: session.email);
    await _storage.write(key: _kOperatorId, value: session.operatorId);
    await _storage.write(key: _kOperatorRole, value: session.role);
    await _storage.write(key: _kBranchId, value: session.branchId);
    await _storage.write(key: _kBiometricEnabled, value: 'true');
    return session;
  }

  AuthException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AuthException('err_network');
    }
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final serverMsg =
        body is Map<String, dynamic> ? (body['message'] as String?) : null;
    if (status == 401 || status == 403) {
      return AuthException('err_invalid_creds', serverMsg);
    }
    return AuthException('err_server', serverMsg);
  }
}

class QrCryptoService {
  static String buildPayload({
    required String tokenNumber,
    required String plateNumber,
    required String branchId,
    required DateTime entryTime,
  }) {
    final epochMs = entryTime.toUtc().millisecondsSinceEpoch;
    return '$tokenNumber|$plateNumber|$branchId|$epochMs';
  }

  static String signPayload(
    String payload, {
    String secret = AppConfig.qrHmacSecret,
  }) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(payload)).toString().substring(0, 16);
  }

  static String encodeSignedQr({
    required String tokenNumber,
    required String plateNumber,
    required String branchId,
    required DateTime entryTime,
    String secret = AppConfig.qrHmacSecret,
  }) {
    final payload = buildPayload(
      tokenNumber: tokenNumber,
      plateNumber: plateNumber,
      branchId: branchId,
      entryTime: entryTime,
    );
    final sig = signPayload(payload, secret: secret);
    return '$payload|$sig';
  }

  static String? verifyAndExtractToken(
    String rawQr, {
    String secret = AppConfig.qrHmacSecret,
  }) {
    final parts = rawQr.trim().split('|');
    if (parts.length != 5) return null;

    final token = parts[0];
    final plate = parts[1];
    final branch = parts[2];
    final epochStr = parts[3];
    final providedSig = parts[4];

    if (token.isEmpty || plate.isEmpty || int.tryParse(epochStr) == null) {
      return null;
    }

    final payload = '$token|$plate|$branch|$epochStr';
    final expectedSig = signPayload(payload, secret: secret);
    return _constantTimeEquals(providedSig, expectedSig) ? token : null;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class DeveloperWatermark extends StatelessWidget {
  final AppThemePreset? theme;
  const DeveloperWatermark({super.key, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? AppThemePresets.all[0];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: t.isLight ? const Color(0xFFF1F5F9) : const Color(0xFF04060A),
        border: Border(top: BorderSide(color: t.accent.withValues(alpha: 0.35))),
      ),
      child: Text(
        AppLocalizations.tr('watermark'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: t.accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
