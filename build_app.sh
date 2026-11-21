set -e
mkdir -p lib/core lib/features/auth lib/features/parking

cat << 'END_PUBSPEC' > pubspec.yaml
name: SmartPark
description: SmartPark Parking & Token Management System
publish_to: 'none'
version: 2.0.0+2

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  google_fonts: ^6.2.1
  dio: ^5.7.0
  flutter_secure_storage: ^10.0.0
  shared_preferences: ^2.3.3
  local_auth: ^3.0.2
  google_mlkit_text_recognition: ^0.17.1
  image_picker: ^1.1.2
  mobile_scanner: ^7.4.3
  barcode_widget: ^2.0.4
  pdf: ^3.11.1
  printing: ^5.13.3
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
END_PUBSPEC

cat << 'END_CORE' > lib/core/app_core.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

enum CardDesignStyle {
  luxury('Luxury Gold Frame', 16),
  rounded('Modern Pill Soft', 24),
  sharp('Sharp Executive', 6),
  cyber('Neon Cyber Border', 14),
  glass('Crystal Frosted', 20);

  final String label;
  final double radius;
  const CardDesignStyle(this.label, this.radius);
}

class AppThemePreset {
  final String name;
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgCard;
  final Color accent;
  final Color secondary;
  final bool isLight;

  const AppThemePreset(
    this.name,
    this.bgPrimary,
    this.bgSurface,
    this.bgCard,
    this.accent,
    this.secondary, {
    this.isLight = false,
  });

  Color get textPrimary => isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get textMuted => isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get textOnAccent => accent.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  Color get borderColor => isLight ? const Color(0x1F0F172A) : const Color(0x1FFFFFFF);

  ThemeData toThemeData(CardDesignStyle style) {
    final base = isLight ? ThemeData.light() : ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accent,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: (isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
        primary: accent,
        secondary: secondary,
        surface: bgSurface,
        error: const Color(0xFFEF4444),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        labelStyle: TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.radius * 0.8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.radius * 0.8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.radius * 0.8),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}

class AppThemePresets {
  static const List<AppThemePreset> all = [
    AppThemePreset('01. Obsidian Gold (Signature)', Color(0xFF07090E), Color(0xFF101522), Color(0xFF161D2F), Color(0xFFD4AF37), Color(0xFF10B981)),
    AppThemePreset('02. Dubai Royal Sapphire', Color(0xFF060B18), Color(0xFF0E172A), Color(0xFF172542), Color(0xFF38BDF8), Color(0xFFF59E0B)),
    AppThemePreset('03. Emerald Carbon', Color(0xFF06100C), Color(0xFF0D1F18), Color(0xFF132D23), Color(0xFF10B981), Color(0xFFD4AF37)),
    AppThemePreset('04. Crimson Titanium', Color(0xFF110709), Color(0xFF1E0D11), Color(0xFF2B1419), Color(0xFFF43F5E), Color(0xFFFB923C)),
    AppThemePreset('05. Midnight Amethyst', Color(0xFF0B0714), Color(0xFF160E29), Color(0xFF21163D), Color(0xFFA855F7), Color(0xFF2DD4BF)),
    AppThemePreset('06. AMOLED Pure Gold', Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF141414), Color(0xFFFFD700), Color(0xFF00E676)),
    AppThemePreset('07. Cyber Neon Cyan', Color(0xFF030712), Color(0xFF0B1120), Color(0xFF111827), Color(0xFF00F5D4), Color(0xFFF72585)),
    AppThemePreset('08. Sunset Copper', Color(0xFF120B07), Color(0xFF20130C), Color(0xFF2E1C12), Color(0xFFF97316), Color(0xFFFACC15)),
    AppThemePreset('09. Rose Gold Velvet', Color(0xFF130B0E), Color(0xFF211319), Color(0xFF301C24), Color(0xFFF472B6), Color(0xFFFBBF24)),
    AppThemePreset('10. Arctic Night', Color(0xFF080E14), Color(0xFF101C26), Color(0xFF172836), Color(0xFF22D3EE), Color(0xFF34D399)),
    AppThemePreset('11. Royal Indigo', Color(0xFF09091A), Color(0xFF121230), Color(0xFF1C1C45), Color(0xFF818CF8), Color(0xFF34D399)),
    AppThemePreset('12. Forest Jade', Color(0xFF07110E), Color(0xFF0F211B), Color(0xFF163028), Color(0xFF34D399), Color(0xFFFBBF24)),
    AppThemePreset('13. Desert Amber', Color(0xFF120F07), Color(0xFF211B0D), Color(0xFF302713), Color(0xFFF59E0B), Color(0xFF10B981)),
    AppThemePreset('14. Electric Magenta', Color(0xFF120713), Color(0xFF210D24), Color(0xFF2F1333), Color(0xFFE879F9), Color(0xFF38BDF8)),
    AppThemePreset('15. Graphite Silver', Color(0xFF0D0F12), Color(0xFF171A20), Color(0xFF222730), Color(0xFFE2E8F0), Color(0xFF38BDF8)),
    AppThemePreset('16. Cobalt Executive', Color(0xFF050A18), Color(0xFF0C1633), Color(0xFF13224D), Color(0xFF60A5FA), Color(0xFFFBBF24)),
    AppThemePreset('17. Ruby Noir', Color(0xFF12060A), Color(0xFF210B12), Color(0xFF30101A), Color(0xFFFB7185), Color(0xFF2DD4BF)),
    AppThemePreset('18. Teal Horizon', Color(0xFF051112), Color(0xFF0B2022), Color(0xFF102E31), Color(0xFF2DD4BF), Color(0xFFF59E0B)),
    AppThemePreset('19. Matrix Lime', Color(0xFF060E07), Color(0xFF0C1C0E), Color(0xFF132A16), Color(0xFF84CC16), Color(0xFF22D3EE)),
    AppThemePreset('20. Espresso Bronze', Color(0xFF110C09), Color(0xFF1F1610), Color(0xFF2C2017), Color(0xFFD97706), Color(0xFF10B981)),
    AppThemePreset('21. Deep Ocean', Color(0xFF040D1A), Color(0xFF081930), Color(0xFF0D2547), Color(0xFF0EA5E9), Color(0xFF10B981)),
    AppThemePreset('22. Plum Majesty', Color(0xFF100814), Color(0xFF1D0F24), Color(0xFF2B1636), Color(0xFFC084FC), Color(0xFFF472B6)),
    AppThemePreset('23. Stealth Slate', Color(0xFF090D16), Color(0xFF131A29), Color(0xFF1D273B), Color(0xFF94A3B8), Color(0xFF10B981)),
    AppThemePreset('24. Lava Gold', Color(0xFF140906), Color(0xFF24110B), Color(0xFF361910), Color(0xFFFB923C), Color(0xFFFACC15)),
    AppThemePreset('25. Neon Violet', Color(0xFF090514), Color(0xFF130B29), Color(0xFF1D113D), Color(0xFFA78BFA), Color(0xFF22D3EE)),
    AppThemePreset('26. Carbon Turquoise', Color(0xFF080E10), Color(0xFF101C20), Color(0xFF182A30), Color(0xFF06B6D4), Color(0xFFF59E0B)),
    AppThemePreset('27. Imperial Maroon', Color(0xFF14070B), Color(0xFF240C14), Color(0xFF33121C), Color(0xFFFBBF24), Color(0xFFFB7185)),
    AppThemePreset('28. Nordic Frost Dark', Color(0xFF0B1117), Color(0xFF161B22), Color(0xFF21262D), Color(0xFF58A6FF), Color(0xFF3FB950)),
    AppThemePreset('29. Olive Tactical', Color(0xFF0C1009), Color(0xFF171E11), Color(0xFF222C19), Color(0xFFA3E635), Color(0xFFFACC15)),
    AppThemePreset('30. Cherry Blossom Dark', Color(0xFF140A0F), Color(0xFF24131B), Color(0xFF341C27), Color(0xFFF9A8D4), Color(0xFF34D399)),
    AppThemePreset('31. Platinum White (Light)', Color(0xFFF1F5F9), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF0F172A), Color(0xFF10B981), isLight: true),
    AppThemePreset('32. Ivory Gold (Light)', Color(0xFFFAF8F5), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFB45309), Color(0xFF059669), isLight: true),
    AppThemePreset('33. Sky Corporate (Light)', Color(0xFFF0F9FF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF0284C7), Color(0xFF0D9488), isLight: true),
    AppThemePreset('34. Mint Clean (Light)', Color(0xFFECFDF5), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF059669), Color(0xFF0284C7), isLight: true),
    AppThemePreset('35. Royal Lavender (Light)', Color(0xFFF5F3FF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF7C3AED), Color(0xFFEC4899), isLight: true),
    AppThemePreset('36. Pearl Rose (Light)', Color(0xFFFFF1F2), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFE11D48), Color(0xFFF59E0B), isLight: true),
    AppThemePreset('37. Sand Executive (Light)', Color(0xFFFFFBEB), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFD97706), Color(0xFF059669), isLight: true),
    AppThemePreset('38. Crisp Indigo (Light)', Color(0xFFEEF2FF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF4F46E5), Color(0xFF10B981), isLight: true),
    AppThemePreset('39. Aqua Breeze (Light)', Color(0xFFF0FDFA), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF0D9488), Color(0xFF2563EB), isLight: true),
    AppThemePreset('40. Silver Minimal (Light)', Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFF334155), Color(0xFF0284C7), isLight: true),
    AppThemePreset('41. Sunset Coral (Light)', Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFEA580C), Color(0xFF16A34A), isLight: true),
    AppThemePreset('42. Sapphire Crisp (Light)', Color(0xFFEFF6FF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF1D4ED8), Color(0xFFD97706), isLight: true),
    AppThemePreset('43. Emerald Clean (Light)', Color(0xFFF0FDF4), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF15803D), Color(0xFF0284C7), isLight: true),
    AppThemePreset('44. Orchid Silk (Light)', Color(0xFFFDF4FF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFA21CAF), Color(0xFF0D9488), isLight: true),
    AppThemePreset('45. Warm Cream (Light)', Color(0xFFFEFCE8), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFCA8A04), Color(0xFF16A34A), isLight: true),
    AppThemePreset('46. Midnight Blue Gold', Color(0xFF040814), Color(0xFF0A1229), Color(0xFF111C3D), Color(0xFFFFD166), Color(0xFF06D6A0)),
    AppThemePreset('47. Obsidian Crimson', Color(0xFF0A0A0C), Color(0xFF141418), Color(0xFF1E1E24), Color(0xFFEF4444), Color(0xFFF59E0B)),
    AppThemePreset('48. Deep Space Mint', Color(0xFF050B0E), Color(0xFF0B161C), Color(0xFF11212B), Color(0xFF34D399), Color(0xFF38BDF8)),
    AppThemePreset('49. Luxury Bronze', Color(0xFF0F0B08), Color(0xFF1C150F), Color(0xFF291F16), Color(0xFFE5A93C), Color(0xFF34D399)),
    AppThemePreset('50. Kyoto Sakura Blush', Color(0xFFFFF0F5), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFDB2777), Color(0xFF059669), isLight: true),
  ];

  static AppThemePreset getByIndex(int i) => all[i.clamp(0, all.length - 1)];
}

class LanguageModel {
  final String code;
  final String name;
  final String flag;
  final bool isRtl;
  const LanguageModel(this.code, this.name, this.flag, {this.isRtl = false});
}

class AppLocalizations {
  static const List<LanguageModel> supportedLanguages = [
    LanguageModel('en', 'English (International)', '🇺🇸'),
    LanguageModel('ur', 'اردو (پاکستان)', '🇵🇰', isRtl: true),
    LanguageModel('ar', 'العربية (UAE/KSA)', '🇸🇦', isRtl: true),
    LanguageModel('hi', 'हिन्दी (India)', '🇮🇳'),
    LanguageModel('zh', '中文 (Chinese)', '🇨🇳'),
    LanguageModel('es', 'Español (Spanish)', '🇪🇸'),
    LanguageModel('fr', 'Français (French)', '🇫🇷'),
    LanguageModel('de', 'Deutsch (German)', '🇩🇪'),
    LanguageModel('tr', 'Türkçe (Turkish)', '🇹🇷'),
    LanguageModel('ru', 'Русский (Russian)', '🇷🇺'),
    LanguageModel('pt', 'Português (Portuguese)', '🇵🇹'),
    LanguageModel('ja', '日本語 (Japanese)', '🇯🇵'),
    LanguageModel('ko', '한국어 (Korean)', '🇰🇷'),
    LanguageModel('it', 'Italiano (Italian)', '🇮🇹'),
    LanguageModel('id', 'Bahasa Indonesia', '🇮🇩'),
    LanguageModel('ms', 'Bahasa Melayu', '🇲🇾'),
    LanguageModel('bn', 'বাংলা (Bengali)', '🇧🇩'),
    LanguageModel('fa', 'فارسی (Persian)', '🇮🇷', isRtl: true),
    LanguageModel('th', 'ไทย (Thai)', '🇹🇭'),
    LanguageModel('vi', 'Tiếng Việt', '🇻🇳'),
    LanguageModel('nl', 'Nederlands (Dutch)', '🇳🇱'),
    LanguageModel('pl', 'Polski (Polish)', '🇵🇱'),
  ];

  static final ValueNotifier<LanguageModel> currentLanguage =
      ValueNotifier(supportedLanguages[1]);

  static final Map<String, Map<String, String>> _values = {
    'en': {
      'app_name': 'SmartPark Pro AI',
      'login_sub': 'Enterprise Parking Security Portal',
      'email': 'Email / Operator ID',
      'password': 'Password',
      'login_btn': 'Secure Sign In',
      'signup_btn': 'Create Operator Account',
      'biometric': 'Biometric / Face ID Login',
      'select_vehicle': 'SELECT VEHICLE CLASS',
      'scan_plate': 'AI SCAN NUMBER PLATE (ANPR)',
      'plate_no': 'Vehicle Registration Plate (Scan or Manual)',
      'owner_name': 'Driver / Owner Full Name',
      'location': 'Parking Zone / Bay Slot',
      'generate_token': 'ISSUE SMART PARKING TOKEN',
      'settings': 'Tariff & 50-Theme Studio',
      'watermark': 'Developer: Muhammad Umair Sattar  |  © 2026 All Rights Reserved',
      'car': 'Car', 'motorcycle': 'Motorcycle', 'cycle': 'Cycle', 'rickshaw': 'Rickshaw',
      'tractor': 'Tractor', 'mazda': 'Mazda', 'dumper': 'Dumper', 'truck': 'Heavy Truck',
    },
    'ur': {
      'app_name': 'اسمارٹ پارک پرو AI',
      'login_sub': 'انٹرپرائز پارکنگ سیکیورٹی پورٹل',
      'email': 'ای میل / آپریٹر آئی ڈی',
      'password': 'پاس ورڈ',
      'login_btn': 'محفوظ لاگ ان کریں',
      'signup_btn': 'نیا اکاؤنٹ بنائیں',
      'biometric': 'فنگر پرنٹ / فیس آئی ڈی لاگ ان',
      'select_vehicle': 'گاڑی کی قسم منتخب کریں',
      'scan_plate': 'نمبر پلیٹ اسکین کریں (AI)',
      'plate_no': 'گاڑی نمبر پلیٹ (اسکین یا مینول)',
      'owner_name': 'ڈرائیور / مالک کا نام',
      'location': 'پارکنگ مقام / زون',
      'generate_token': 'سمارٹ ٹوکن تیار کریں',
      'settings': 'فیس اور 50 تھیمز سیٹنگز',
      'watermark': 'ڈویلپر: محمد عمیر ستار  |  جملہ حقوق محفوظ ہیں © 2026',
      'car': 'کار', 'motorcycle': 'موٹر سائیکل', 'cycle': 'سائیکل', 'rickshaw': 'رکشہ',
      'tractor': 'ٹریکٹر', 'mazda': 'مزدہ', 'dumper': 'ڈمپر', 'truck': 'بڑا ٹرک',
    },
    'ar': {
      'app_name': 'سمارت بارك برو AI',
      'login_sub': 'بوابة أمن المواقف الذكية',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login_btn': 'تسجيل الدخول الآمن',
      'signup_btn': 'إنشاء حساب جديد',
      'biometric': 'الدخول بالبصمة / الوجه',
      'select_vehicle': 'اختر فئة المركبة',
      'scan_plate': 'مسح لوحة المركبة بالذكاء الاصطناعي',
      'plate_no': 'رقم لوحة المركبة',
      'owner_name': 'اسم السائق / المالك',
      'location': 'الموقع / المنطقة',
      'generate_token': 'إصدار التذكرة الذكية',
      'settings': 'الأسعار و 50 ثيم',
      'watermark': 'المطور: محمد عمير ستار  |  جميع الحقوق محفوظة © 2026',
      'car': 'سيارة', 'motorcycle': 'دراجة نارية', 'cycle': 'دراجة', 'rickshaw': 'توك توك',
      'tractor': 'جرار', 'mazda': 'مازدا', 'dumper': 'قلاب', 'truck': 'شاحنة',
    },
  };

  static String tr(String key) {
    final code = currentLanguage.value.code;
    return _values[code]?[key] ?? _values['en']?[key] ?? key;
  }
}

class ApiService {
  static const String _baseUrl = 'https://api.smartpark-enterprise.com/v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }

  Future<bool> authenticate(String email, String password, {bool isSignUp = false}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _storage.write(key: 'access_token', value: 'jwt_enterprise_token_2026');
      return true;
    } catch (_) {
      return false;
    }
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
        style: TextStyle(color: t.accent, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
END_CORE
cat << 'END_LOGIC' > lib/features/parking/parking_logic.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_core.dart';

enum VehicleType {
  car('car', Icons.directions_car_rounded),
  motorcycle('motorcycle', Icons.two_wheeler_rounded),
  cycle('cycle', Icons.pedal_bike_rounded),
  rickshaw('rickshaw', Icons.electric_rickshaw_rounded),
  tractor('tractor', Icons.agriculture_rounded),
  mazda('mazda', Icons.local_shipping_outlined),
  dumper('dumper', Icons.fire_truck_rounded),
  truck('truck', Icons.local_shipping_rounded);

  final String labelKey;
  final IconData icon;
  const VehicleType(this.labelKey, this.icon);
}

class VehicleRateConfig {
  final double baseFee;
  final double hourlyRate;
  final bool enabled;
  const VehicleRateConfig({this.baseFee = 0, this.hourlyRate = 0, this.enabled = true});

  Map<String, dynamic> toJson() => {'baseFee': baseFee, 'hourlyRate': hourlyRate, 'enabled': enabled};
  factory VehicleRateConfig.fromJson(Map<String, dynamic> j) => VehicleRateConfig(
        baseFee: (j['baseFee'] as num?)?.toDouble() ?? 0,
        hourlyRate: (j['hourlyRate'] as num?)?.toDouble() ?? 0,
        enabled: j['enabled'] as bool? ?? true,
      );
}

class BusinessSettings {
  final String businessName;
  final String currency;
  final String defaultSlot;
  final bool hourlyBilling;
  final int themeIndex;
  final int designStyleIndex;
  final Map<VehicleType, VehicleRateConfig> rates;

  const BusinessSettings({
    required this.businessName,
    required this.currency,
    required this.defaultSlot,
    required this.hourlyBilling,
    required this.themeIndex,
    required this.designStyleIndex,
    required this.rates,
  });

  factory BusinessSettings.initial() => BusinessSettings(
        businessName: 'SmartPark Pro Plaza',
        currency: 'Rs.',
        defaultSlot: 'Zone A - Bay 01',
        hourlyBilling: true,
        themeIndex: 0,
        designStyleIndex: 0,
        rates: {for (final v in VehicleType.values) v: const VehicleRateConfig(baseFee: 0, hourlyRate: 0, enabled: true)},
      );

  AppThemePreset get activeTheme => AppThemePresets.getByIndex(themeIndex);
  CardDesignStyle get activeStyle => CardDesignStyle.values[designStyleIndex.clamp(0, CardDesignStyle.values.length - 1)];

  BusinessSettings copyWith({
    String? businessName,
    String? currency,
    String? defaultSlot,
    bool? hourlyBilling,
    int? themeIndex,
    int? designStyleIndex,
    Map<VehicleType, VehicleRateConfig>? rates,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      defaultSlot: defaultSlot ?? this.defaultSlot,
      hourlyBilling: hourlyBilling ?? this.hourlyBilling,
      themeIndex: themeIndex ?? this.themeIndex,
      designStyleIndex: designStyleIndex ?? this.designStyleIndex,
      rates: rates ?? this.rates,
    );
  }
}

class SettingsNotifier extends Notifier<BusinessSettings> {
  static const _prefsKey = 'smartpark_business_settings_v2';

  @override
  BusinessSettings build() {
    _load();
    return BusinessSettings.initial();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ratesMap = <VehicleType, VehicleRateConfig>{};
      final rawRates = (map['rates'] as Map<String, dynamic>?) ?? {};
      for (final v in VehicleType.values) {
        ratesMap[v] = rawRates[v.name] != null
            ? VehicleRateConfig.fromJson(rawRates[v.name] as Map<String, dynamic>)
            : const VehicleRateConfig();
      }
      state = BusinessSettings(
        businessName: map['businessName'] as String? ?? 'SmartPark Pro Plaza',
        currency: map['currency'] as String? ?? 'Rs.',
        defaultSlot: map['defaultSlot'] as String? ?? 'Zone A - Bay 01',
        hourlyBilling: map['hourlyBilling'] as bool? ?? true,
        themeIndex: map['themeIndex'] as int? ?? 0,
        designStyleIndex: map['designStyleIndex'] as int? ?? 0,
        rates: ratesMap,
      );
    } catch (_) {}
  }

  Future<void> _save(BusinessSettings s) async {
    state = s;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'businessName': s.businessName,
      'currency': s.currency,
      'defaultSlot': s.defaultSlot,
      'hourlyBilling': s.hourlyBilling,
      'themeIndex': s.themeIndex,
      'designStyleIndex': s.designStyleIndex,
      'rates': {for (final e in s.rates.entries) e.key.name: e.value.toJson()},
    });
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> updateAll(BusinessSettings updated) => _save(updated);
  Future<void> setTheme(int index) => _save(state.copyWith(themeIndex: index));
  Future<void> setDesignStyle(int index) => _save(state.copyWith(designStyleIndex: index));
}

final settingsProvider = NotifierProvider<SettingsNotifier, BusinessSettings>(SettingsNotifier.new);

enum TicketStatus { parked, checkedOut }

class ParkingTicket {
  final String tokenNumber;
  final String businessName;
  final String currency;
  final VehicleType vehicleType;
  final String plateNumber;
  final String ownerName;
  final String locationSlot;
  final double baseFee;
  final double hourlyRate;
  final bool hourlyBilling;
  final DateTime entryTime;
  final DateTime? exitTime;
  final TicketStatus status;

  const ParkingTicket({
    required this.tokenNumber,
    required this.businessName,
    required this.currency,
    required this.vehicleType,
    required this.plateNumber,
    required this.ownerName,
    required this.locationSlot,
    required this.baseFee,
    required this.hourlyRate,
    required this.hourlyBilling,
    required this.entryTime,
    this.exitTime,
    this.status = TicketStatus.parked,
  });

  double calculateTotalFee([DateTime? refTime]) {
    if (!hourlyBilling) return baseFee;
    final end = exitTime ?? refTime ?? DateTime.now();
    final hours = end.difference(entryTime).inMinutes / 60.0;
    if (hours <= 1.0) return baseFee;
    return baseFee + ((hours - 1.0).ceil() * hourlyRate);
  }

  ParkingTicket copyWith({DateTime? exitTime, TicketStatus? status}) {
    return ParkingTicket(
      tokenNumber: tokenNumber,
      businessName: businessName,
      currency: currency,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      ownerName: ownerName,
      locationSlot: locationSlot,
      baseFee: baseFee,
      hourlyRate: hourlyRate,
      hourlyBilling: hourlyBilling,
      entryTime: entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
    );
  }
}

class ParkingState {
  final List<ParkingTicket> tickets;
  final bool isLoading;
  const ParkingState({this.tickets = const [], this.isLoading = false});

  List<ParkingTicket> get activeTickets =>
      tickets.where((t) => t.status == TicketStatus.parked).toList();

  double get todayRevenue => tickets.fold(0.0, (sum, t) => sum + t.calculateTotalFee());

  ParkingState copyWith({List<ParkingTicket>? tickets, bool? isLoading}) {
    return ParkingState(tickets: tickets ?? this.tickets, isLoading: isLoading ?? this.isLoading);
  }
}

class ParkingNotifier extends Notifier<ParkingState> {
  @override
  ParkingState build() => const ParkingState();

  Future<ParkingTicket> issueTicket({
    required VehicleType type,
    required String plateNumber,
    required String ownerName,
    required String slot,
  }) async {
    state = state.copyWith(isLoading: true);
    final cfg = ref.read(settingsProvider);
    final rate = cfg.rates[type] ?? const VehicleRateConfig();
    final now = DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 9000 + 1000).toString();
    final tokenNo = 'TKN-${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}-$suffix';

    final ticket = ParkingTicket(
      tokenNumber: tokenNo,
      businessName: cfg.businessName,
      currency: cfg.currency,
      vehicleType: type,
      plateNumber: plateNumber.toUpperCase().trim(),
      ownerName: ownerName.trim(),
      locationSlot: slot.trim(),
      baseFee: rate.baseFee,
      hourlyRate: rate.hourlyRate,
      hourlyBilling: cfg.hourlyBilling,
      entryTime: now,
    );

    state = state.copyWith(tickets: [ticket, ...state.tickets], isLoading: false);
    return ticket;
  }

  ParkingTicket? checkOutTicket(String tokenNumber) {
    final idx = state.tickets.indexWhere((t) => t.tokenNumber == tokenNumber);
    if (idx == -1) return null;
    final updated = state.tickets[idx].copyWith(exitTime: DateTime.now(), status: TicketStatus.checkedOut);
    final updatedList = [...state.tickets];
    updatedList[idx] = updated;
    state = state.copyWith(tickets: updatedList);
    return updated;
  }
}

final parkingProvider = NotifierProvider<ParkingNotifier, ParkingState>(ParkingNotifier.new);
END_LOGIC

cat << 'END_RECEIPT' > lib/features/parking/receipt_screen.dart
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
      ..arcToPoint(Offset(size.width, cutY + holeRadius), radius: Radius.circular(holeRadius), clockwise: false)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cutY + holeRadius)
      ..arcToPoint(Offset(0, cutY - holeRadius), radius: Radius.circular(holeRadius), clockwise: false)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const dashW = 6.0;
      final count = (constraints.constrainWidth() / (2 * dashW)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(count, (_) => const SizedBox(width: dashW, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black26)))),
      );
    });
  }
}

class VipReceiptScreen extends ConsumerWidget {
  final ParkingTicket ticket;
  const VipReceiptScreen({super.key, required this.ticket});

  Future<void> _exportThermalPdf() async {
    final pdf = pw.Document();
    final entryStr = DateFormat('dd-MMM-yyyy hh:mm:ss a').format(ticket.entryTime);
    final exitStr = ticket.exitTime != null ? DateFormat('dd-MMM-yyyy hh:mm:ss a').format(ticket.exitTime!) : 'PARKED';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(ticket.businessName.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text(ticket.tokenNumber, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Vehicle: ${ticket.vehicleType.labelKey.toUpperCase()}'),
            pw.Text('Plate: ${ticket.plateNumber}'),
            pw.Text('Owner: ${ticket.ownerName}'),
            pw.Text('Zone: ${ticket.locationSlot}'),
            pw.Text('Entry: $entryStr'),
            pw.Text('Exit: $exitStr'),
            pw.SizedBox(height: 6),
            pw.Text('TOTAL: ${ticket.currency} ${ticket.calculateTotalFee().toInt()}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: ticket.tokenNumber, width: 75, height: 75),
            pw.Divider(),
            pw.Text('Developer: Muhammad Umair Sattar', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('(c) 2026 All Rights Reserved', style: const pw.TextStyle(fontSize: 8)),
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
    final totalFee = ticket.calculateTotalFee();

    return Scaffold(
      appBar: AppBar(title: Text(isClosed ? 'Final Exit Receipt' : 'VIP Parking Pass')),
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
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                        child: Column(
                          children: [
                            Text(ticket.businessName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isClosed ? const Color(0x1A10B981) : const Color(0x1AD4AF37),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isClosed ? 'PAID & CHECKED OUT' : 'ACTIVE PARKING TOKEN',
                                style: TextStyle(color: isClosed ? const Color(0xFF10B981) : const Color(0xFF9A7B16), fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(ticket.tokenNumber, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 14),
                            _row('Vehicle Class', AppLocalizations.tr(ticket.vehicleType.labelKey)),
                            _row('Plate Number', ticket.plateNumber),
                            _row('Driver / Owner', ticket.ownerName),
                            _row('Location Bay', ticket.locationSlot),
                            _row('Date', DateFormat('dd MMM yyyy').format(ticket.entryTime)),
                            _row('Entry Time', DateFormat('hh:mm:ss a').format(ticket.entryTime)),
                            if (ticket.exitTime != null) _row('Exit Time', DateFormat('hh:mm:ss a').format(ticket.exitTime!)),
                            _row('Total Fee', '${ticket.currency} ${totalFee.toInt()}', isBold: true),
                            const SizedBox(height: 20),
                            const DashedDivider(),
                            const SizedBox(height: 20),
                            BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: '${ticket.tokenNumber}|${ticket.plateNumber}',
                              width: 130,
                              height: 130,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 10),
                            const Text('Developer: Muhammad Umair Sattar | © 2026', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: theme.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: _exportThermalPdf,
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('PRINT THERMAL RECEIPT / PDF', style: TextStyle(fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(v, style: TextStyle(color: isBold ? const Color(0xFF047857) : const Color(0xFF0F172A), fontSize: isBold ? 16 : 13.5, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
    );
  }
}
END_RECEIPT
cat << 'END_SETTINGS' > lib/features/parking/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_core.dart';
import 'parking_logic.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late TextEditingController _bizCtrl;
  late TextEditingController _currCtrl;
  late TextEditingController _slotCtrl;
  late bool _hourlyBilling;
  final Map<VehicleType, TextEditingController> _baseCtrls = {};
  final Map<VehicleType, TextEditingController> _hourCtrls = {};
  final Map<VehicleType, bool> _enabledMap = {};
  String _themeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final s = ref.read(settingsProvider);
    _bizCtrl = TextEditingController(text: s.businessName);
    _currCtrl = TextEditingController(text: s.currency);
    _slotCtrl = TextEditingController(text: s.defaultSlot);
    _hourlyBilling = s.hourlyBilling;
    for (final v in VehicleType.values) {
      final r = s.rates[v] ?? const VehicleRateConfig();
      _baseCtrls[v] = TextEditingController(text: r.baseFee == 0 ? '' : r.baseFee.toInt().toString());
      _hourCtrls[v] = TextEditingController(text: r.hourlyRate == 0 ? '' : r.hourlyRate.toInt().toString());
      _enabledMap[v] = r.enabled;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bizCtrl.dispose();
    _currCtrl.dispose();
    _slotCtrl.dispose();
    for (final c in _baseCtrls.values) c.dispose();
    for (final c in _hourCtrls.values) c.dispose();
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
        enabled: _enabledMap[v] ?? true,
      );
    }
    await ref.read(settingsProvider.notifier).updateAll(cur.copyWith(
          businessName: _bizCtrl.text.trim().isEmpty ? 'SmartPark Pro Plaza' : _bizCtrl.text.trim(),
          currency: _currCtrl.text.trim().isEmpty ? 'Rs.' : _currCtrl.text.trim(),
          defaultSlot: _slotCtrl.text.trim().isEmpty ? 'Zone A - Bay 01' : _slotCtrl.text.trim(),
          hourlyBilling: _hourlyBilling,
          rates: updatedRates,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: cur.activeTheme.secondary, content: const Text('Rates & Business Settings Saved Permanently!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final theme = s.activeTheme;
    final style = s.activeStyle;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('settings'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.accent,
          labelColor: theme.accent,
          unselectedLabelColor: theme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.payments_outlined), text: 'Rates & Setup'),
            Tab(icon: Icon(Icons.palette_outlined), text: '50 Themes Studio'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildRatesTab(theme, style), _buildThemesTab(s, theme, style)],
            ),
          ),
          DeveloperWatermark(theme: theme),
        ],
      ),
    );
  }

  Widget _buildRatesTab(AppThemePreset theme, CardDesignStyle style) {
    final currencies = ['Rs.', 'PKR', 'AED', 'SAR', '\$', '€', '£', '₹'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('BUSINESS & CURRENCY', style: TextStyle(color: theme.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 10),
        TextField(controller: _bizCtrl, decoration: const InputDecoration(labelText: 'Plaza / Business Name (Shown on Receipt)', prefixIcon: Icon(Icons.storefront))),
        const SizedBox(height: 10),
        TextField(controller: _slotCtrl, decoration: const InputDecoration(labelText: 'Default Parking Zone / Location', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 10),
        TextField(controller: _currCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. Rs., AED, \$)', prefixIcon: Icon(Icons.currency_exchange))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: currencies.map((c) => ActionChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            onPressed: () => setState(() => _currCtrl.text = c),
          )).toList(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hourly Overtime Billing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(_hourlyBilling ? 'Base fee + extra per hour after 1st hour' : 'Fixed flat fee per entry only', style: TextStyle(color: theme.textMuted, fontSize: 12)),
          value: _hourlyBilling,
          activeThumbColor: theme.accent,
          onChanged: (v) => setState(() => _hourlyBilling = v),
        ),
        const Divider(height: 24),
        Text('CUSTOM VEHICLE TARIFFS (SET YOUR OWN PRICES)', style: TextStyle(color: theme.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...VehicleType.values.map((v) => Container(
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
                      Expanded(child: Text(AppLocalizations.tr(v.labelKey), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
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
                          decoration: const InputDecoration(labelText: 'Base / Fixed Fee', hintText: '0'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _hourCtrls[v],
                          keyboardType: TextInputType.number,
                          enabled: _hourlyBilling,
                          decoration: const InputDecoration(labelText: 'Per Extra Hr', hintText: '0'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: theme.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.radius))),
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded),
            label: const Text('SAVE ALL RATES & SETTINGS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildThemesTab(BusinessSettings s, AppThemePreset activeTheme, CardDesignStyle activeStyle) {
    final filtered = AppThemePresets.all.asMap().entries.where((e) {
      if (_themeFilter == 'Dark') return !e.value.isLight;
      if (_themeFilter == 'Light') return e.value.isLight;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text('UI CARD DESIGN STYLE', style: TextStyle(color: activeTheme.accent, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: CardDesignStyle.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final st = CardDesignStyle.values[i];
              final sel = s.designStyleIndex == i;
              return ChoiceChip(
                label: Text(st.label, style: TextStyle(color: sel ? activeTheme.textOnAccent : activeTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                selected: sel,
                selectedColor: activeTheme.accent,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setDesignStyle(i);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: ['All', 'Dark', 'Light'].map((f) {
              final sel = _themeFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$f (${f == 'All' ? 50 : f == 'Dark' ? 34 : 16})'),
                  selected: sel,
                  selectedColor: activeTheme.accent,
                  labelStyle: TextStyle(color: sel ? activeTheme.textOnAccent : activeTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                  onSelected: (_) => setState(() => _themeFilter = f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8),
            itemCount: filtered.length,
            itemBuilder: (_, idx) {
              final entry = filtered[idx];
              final t = entry.value;
              final sel = s.themeIndex == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setTheme(entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.bgCard,
                    borderRadius: BorderRadius.circular(activeStyle.radius),
                    border: Border.all(color: sel ? t.accent : t.borderColor, width: sel ? 2.5 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 9, backgroundColor: t.accent),
                          const SizedBox(width: 5),
                          CircleAvatar(radius: 9, backgroundColor: t.secondary),
                          const Spacer(),
                          if (sel) Icon(Icons.check_circle, color: t.accent, size: 18),
                        ],
                      ),
                      Text(t.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
END_SETTINGS
cat << 'END_AUTH' > lib/features/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/app_core.dart';
import '../parking/dashboard_screen.dart';
import '../parking/parking_logic.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _api = ApiService();
  final _localAuth = LocalAuthentication();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  Future<void> _biometricLogin() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return;
      final ok = await _localAuth.authenticate(
        localizedReason: AppLocalizations.tr('biometric'),
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProDashboardScreen()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth: $e')));
    }
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final ok = await _api.authenticate(_emailCtrl.text, _passCtrl.text, isSignUp: !_isLogin);
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProDashboardScreen()));
    }
  }

  void _pickLanguage(AppThemePreset theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgSurface,
      builder: (_) => ListView.builder(
        itemCount: AppLocalizations.supportedLanguages.length,
        itemBuilder: (ctx, i) {
          final l = AppLocalizations.supportedLanguages[i];
          return ListTile(
            leading: Text(l.flag, style: const TextStyle(fontSize: 22)),
            title: Text(l.name, style: TextStyle(color: theme.textPrimary)),
            trailing: AppLocalizations.currentLanguage.value.code == l.code ? Icon(Icons.check_circle, color: theme.accent) : null,
            onTap: () {
              AppLocalizations.currentLanguage.value = l;
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final theme = s.activeTheme;
    final style = s.activeStyle;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ActionChip(
                  avatar: Text(AppLocalizations.currentLanguage.value.flag),
                  label: Text(AppLocalizations.currentLanguage.value.name.split(' ').first),
                  onPressed: () => _pickLanguage(theme),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.bgCard,
                      borderRadius: BorderRadius.circular(style.radius),
                      border: Border.all(color: style == CardDesignStyle.cyber ? theme.accent : theme.borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 60, color: theme.accent),
                        const SizedBox(height: 10),
                        Text(s.businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(AppLocalizations.tr('login_sub'), style: TextStyle(color: theme.textMuted, fontSize: 12)),
                        const SizedBox(height: 24),
                        TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('email'), prefixIcon: Icon(Icons.person_outline, color: theme.accent))),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.tr('password'),
                            prefixIcon: Icon(Icons.lock_outline, color: theme.accent),
                            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: theme.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.radius * 0.8))),
                            onPressed: _loading ? null : _submit,
                            child: _loading ? CircularProgressIndicator(color: theme.textOnAccent) : Text(_isLogin ? AppLocalizations.tr('login_btn') : AppLocalizations.tr('signup_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: theme.accent, side: BorderSide(color: theme.accent), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.radius * 0.8))),
                          onPressed: _biometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(AppLocalizations.tr('biometric')),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? AppLocalizations.tr('signup_btn') : AppLocalizations.tr('login_btn')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DeveloperWatermark(theme: theme),
          ],
        ),
      ),
    );
  }
}
END_AUTH

cat << 'END_MAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_core.dart';
import 'features/auth/auth_screen.dart';
import 'features/parking/parking_logic.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SmartParkEnterpriseApp()));
}

class SmartParkEnterpriseApp extends ConsumerWidget {
  const SmartParkEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeData = settings.activeTheme.toThemeData(settings.activeStyle);

    return ValueListenableBuilder<LanguageModel>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: settings.businessName,
          theme: themeData,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLanguages.map((e) => Locale(e.code)),
          locale: Locale(lang.code),
          builder: (context, child) => Directionality(
            textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const AuthScreen(),
        );
      },
    );
  }
}
END_MAIN
cat << 'END_DASH' > lib/features/parking/dashboard_screen.dart
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
import 'settings_screen.dart';

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
  late TextEditingController _slotCtrl;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _slotCtrl = TextEditingController(text: ref.read(settingsProvider).defaultSlot);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFEF4444), content: Text('Enter Plate Number & Owner Name!')));
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
    final cfg = ref.watch(settingsProvider);
    final theme = cfg.activeTheme;
    final style = cfg.activeStyle;
    final enabledVehicles = VehicleType.values.where((v) => cfg.rates[v]?.enabled ?? true).toList();
    if (enabledVehicles.isNotEmpty && !enabledVehicles.contains(_selectedType)) {
      _selectedType = enabledVehicles.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cfg.businessName, style: TextStyle(color: theme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Settings & 50 Themes',
            icon: Icon(Icons.tune_rounded, color: theme.accent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            tooltip: 'QR Exit Scanner',
            icon: Icon(Icons.qr_code_scanner_rounded, color: theme.secondary),
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
          indicatorColor: theme.accent,
          labelColor: theme.accent,
          unselectedLabelColor: theme.textMuted,
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
            color: theme.bgSurface,
            child: Row(
              children: [
                _kpi('Revenue', '${cfg.currency} ${state.todayRevenue.toInt()}', theme.secondary, Icons.trending_up, theme, style),
                const SizedBox(width: 12),
                _kpi('Parked', '${state.activeTickets.length} Units', theme.accent, Icons.local_parking, theme, style),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEntryTab(state.isLoading, cfg, theme, style, enabledVehicles), _buildActiveTab(state.activeTickets, cfg, theme, style)],
            ),
          ),
          DeveloperWatermark(theme: theme),
        ],
      ),
    );
  }

  Widget _kpi(String t, String v, Color c, IconData i, AppThemePreset theme, CardDesignStyle style) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(style.radius),
            border: Border.all(color: style == CardDesignStyle.cyber ? c : theme.borderColor),
          ),
          child: Row(children: [
            CircleAvatar(backgroundColor: c.withValues(alpha: 0.15), child: Icon(i, color: c, size: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: TextStyle(color: theme.textMuted, fontSize: 11)),
                Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );

  Widget _buildEntryTab(bool loading, BusinessSettings cfg, AppThemePreset theme, CardDesignStyle style, List<VehicleType> vehicles) {
    final allZero = vehicles.every((v) => (cfg.rates[v]?.baseFee ?? 0) == 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allZero)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(style.radius),
                  border: Border.all(color: theme.accent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: theme.accent),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Tap here to set your custom Vehicle Fees & 50 Themes in Settings!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          Text(AppLocalizations.tr('select_vehicle'), style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
            itemCount: vehicles.length,
            itemBuilder: (ctx, i) {
              final type = vehicles[i];
              final sel = type == _selectedType;
              final fee = cfg.rates[type]?.baseFee ?? 0;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? theme.accent : theme.bgCard,
                    borderRadius: BorderRadius.circular(style.radius * 0.85),
                    border: Border.all(color: sel ? theme.accent : (style == CardDesignStyle.cyber ? theme.secondary : theme.borderColor)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(type.icon, color: sel ? theme.textOnAccent : theme.accent, size: 26),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.tr(type.labelKey), style: TextStyle(color: sel ? theme.textOnAccent : theme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(fee == 0 ? 'Set Fee' : '${cfg.currency}${fee.toInt()}', style: TextStyle(color: sel ? theme.textOnAccent.withValues(alpha: 0.8) : theme.textMuted, fontSize: 9.5)),
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
              style: ElevatedButton.styleFrom(backgroundColor: theme.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.radius * 0.85))),
              onPressed: _isScanning ? null : _scanPlateWithAI,
              icon: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.document_scanner_rounded),
              label: Text(AppLocalizations.tr('scan_plate'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _plateCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: AppLocalizations.tr('plate_no'), prefixIcon: Icon(Icons.pin, color: theme.accent))),
          const SizedBox(height: 12),
          TextField(controller: _ownerCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('owner_name'), prefixIcon: Icon(Icons.person, color: theme.accent))),
          const SizedBox(height: 12),
          TextField(controller: _slotCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('location'), prefixIcon: Icon(Icons.location_on, color: theme.accent))),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: theme.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.radius))),
              onPressed: loading ? null : _issueToken,
              child: Text(AppLocalizations.tr('generate_token'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(List<ParkingTicket> list, BusinessSettings cfg, AppThemePreset theme, CardDesignStyle style) {
    if (list.isEmpty) return Center(child: Text('No active vehicles parked.', style: TextStyle(color: theme.textMuted)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final t = list[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: theme.bgCard, borderRadius: BorderRadius.circular(style.radius), border: Border.all(color: theme.borderColor)),
          child: Row(children: [
            CircleAvatar(backgroundColor: theme.accent.withValues(alpha: 0.15), child: Icon(t.vehicleType.icon, color: theme.accent)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t.plateNumber} • ${t.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${t.ownerName} | ${t.locationSlot}', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                Text(DateFormat('hh:mm a, dd MMM').format(t.entryTime), style: TextStyle(color: theme.secondary, fontSize: 11)),
              ]),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.secondary, foregroundColor: Colors.white),
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
        if (_scanned || capture.barcodes.isEmpty) return;
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
END_DASH

grep -rl "FlutterActivity" android/app/src/main/kotlin | xargs -r sed -i 's/FlutterActivity/FlutterFragmentActivity/g' || true
[ -f android/app/build.gradle.kts ] && sed -i 's/minSdk = 23/minSdk = 24/g; s/minSdk = flutter.minSdkVersion/minSdk = 24/g' android/app/build.gradle.kts || true
[ -f android/app/build.gradle ] && sed -i 's/minSdkVersion 23/minSdkVersion 24/g; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 24/g' android/app/build.gradle || true

flutter pub get
flutter build apk --release
