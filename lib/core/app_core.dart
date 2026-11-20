import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgPrimary = Color(0xFF07090E);
  static const Color bgSurface = Color(0xFF101522);
  static const Color bgCard = Color(0xFF161D2F);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color emerald = Color(0xFF10B981);
  static const Color cyanAI = Color(0xFF06B6D4);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkLuxuryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: goldAccent,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: emerald,
        surface: bgSurface,
        error: danger,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: goldAccent, width: 1.5),
        ),
      ),
    );
  }
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
      ValueNotifier(supportedLanguages[1]); // Default Urdu

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
      // سرور سے جوڑنے کے لیے: await _dio.post(isSignUp ? '/auth/register' : '/auth/login', data: {...});
      await Future.delayed(const Duration(milliseconds: 600));
      await _storage.write(key: 'access_token', value: 'jwt_enterprise_token_2026');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class DeveloperWatermark extends StatelessWidget {
  const DeveloperWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF04060A),
        border: Border(top: BorderSide(color: Color(0x33D4AF37))),
      ),
      child: Text(
        AppLocalizations.tr('watermark'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.goldAccent, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
