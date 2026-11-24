class CountryPreset {
  final String countryName;
  final String flag;
  final String languageCode;
  final String languageLabel;
  final String currencySymbol;
  final bool isRtl;

  const CountryPreset({
    required this.countryName,
    required this.flag,
    required this.languageCode,
    required this.languageLabel,
    required this.currencySymbol,
    this.isRtl = false,
  });
}

class WorldCountryPresets {
  static const List<CountryPreset> all = [
    CountryPreset(countryName: 'Pakistan', flag: '🇵🇰', languageCode: 'ur', languageLabel: 'اردو', currencySymbol: 'Rs.', isRtl: true),
    CountryPreset(countryName: 'Saudi Arabia', flag: '🇸🇦', languageCode: 'ar', languageLabel: 'العربية (السعودية)', currencySymbol: 'SAR ', isRtl: true),
    CountryPreset(countryName: 'UAE (Dubai)', flag: '🇦🇪', languageCode: 'ar', languageLabel: 'العربية (الإمارات)', currencySymbol: 'AED ', isRtl: true),
    CountryPreset(countryName: 'Bahrain', flag: '🇧🇭', languageCode: 'ar', languageLabel: 'العربية (البحرين)', currencySymbol: 'BHD ', isRtl: true),
    CountryPreset(countryName: 'Qatar', flag: '🇶🇦', languageCode: 'ar', languageLabel: 'العربية (قطر)', currencySymbol: 'QAR ', isRtl: true),
    CountryPreset(countryName: 'Kuwait', flag: '🇰🇼', languageCode: 'ar', languageLabel: 'العربية (الكويت)', currencySymbol: 'KWD ', isRtl: true),
    CountryPreset(countryName: 'Oman', flag: '🇴🇲', languageCode: 'ar', languageLabel: 'العربية (عُمان)', currencySymbol: 'OMR ', isRtl: true),
    CountryPreset(countryName: 'Egypt', flag: '🇪🇬', languageCode: 'ar', languageLabel: 'العربية (مصر)', currencySymbol: 'EGP ', isRtl: true),
    CountryPreset(countryName: 'Jordan', flag: '🇯🇴', languageCode: 'ar', languageLabel: 'العربية (الأردن)', currencySymbol: 'JOD ', isRtl: true),
    CountryPreset(countryName: 'Iraq', flag: '🇮🇶', languageCode: 'ar', languageLabel: 'العربية (العراق)', currencySymbol: 'IQD ', isRtl: true),
    CountryPreset(countryName: 'Türkiye', flag: '🇹🇷', languageCode: 'tr', languageLabel: 'Türkçe', currencySymbol: '₺'),
    CountryPreset(countryName: 'China', flag: '🇨🇳', languageCode: 'zh', languageLabel: '中文 (简体)', currencySymbol: '¥'),
    CountryPreset(countryName: 'Spain', flag: '🇪🇸', languageCode: 'es', languageLabel: 'Español', currencySymbol: '€'),
    CountryPreset(countryName: 'France', flag: '🇫🇷', languageCode: 'fr', languageLabel: 'Français', currencySymbol: '€'),
    CountryPreset(countryName: 'Germany', flag: '🇩🇪', languageCode: 'de', languageLabel: 'Deutsch', currencySymbol: '€'),
    CountryPreset(countryName: 'United Kingdom', flag: '🇬🇧', languageCode: 'en', languageLabel: 'English (UK)', currencySymbol: '£'),
    CountryPreset(countryName: 'United States', flag: '🇺🇸', languageCode: 'en', languageLabel: 'English (US)', currencySymbol: '\$'),
    CountryPreset(countryName: 'Canada (EN)', flag: '🇨🇦', languageCode: 'en', languageLabel: 'English (Canada)', currencySymbol: 'C\$'),
    CountryPreset(countryName: 'Canada (FR)', flag: '🇨🇦', languageCode: 'fr', languageLabel: 'Français (Canada)', currencySymbol: 'C\$'),
    CountryPreset(countryName: 'Australia', flag: '🇦🇺', languageCode: 'en', languageLabel: 'English (AU)', currencySymbol: 'A\$'),
    CountryPreset(countryName: 'New Zealand', flag: '🇳🇿', languageCode: 'en', languageLabel: 'English (NZ)', currencySymbol: 'NZ\$'),
    CountryPreset(countryName: 'Ireland', flag: '🇮🇪', languageCode: 'en', languageLabel: 'English (IE)', currencySymbol: '€'),
    CountryPreset(countryName: 'Singapore', flag: '🇸🇬', languageCode: 'en', languageLabel: 'English (SG)', currencySymbol: 'S\$'),
    CountryPreset(countryName: 'India', flag: '🇮🇳', languageCode: 'hi', languageLabel: 'हिन्दी', currencySymbol: '₹'),
    CountryPreset(countryName: 'Iran', flag: '🇮🇷', languageCode: 'fa', languageLabel: 'فارسی', currencySymbol: 'IRR ', isRtl: true),
    CountryPreset(countryName: 'Afghanistan', flag: '🇦🇫', languageCode: 'fa', languageLabel: 'دری / فارسی', currencySymbol: 'AFN ', isRtl: true),
    CountryPreset(countryName: 'Italy', flag: '🇮🇹', languageCode: 'it', languageLabel: 'Italiano', currencySymbol: '€'),
    CountryPreset(countryName: 'Portugal', flag: '🇵🇹', languageCode: 'pt', languageLabel: 'Português (PT)', currencySymbol: '€'),
    CountryPreset(countryName: 'Brazil', flag: '🇧🇷', languageCode: 'pt', languageLabel: 'Português (BR)', currencySymbol: 'R\$'),
    CountryPreset(countryName: 'Russia', flag: '🇷🇺', languageCode: 'ru', languageLabel: 'Русский', currencySymbol: '₽'),
    CountryPreset(countryName: 'Japan', flag: '🇯🇵', languageCode: 'ja', languageLabel: '日本語', currencySymbol: '¥'),
    CountryPreset(countryName: 'South Korea', flag: '🇰🇷', languageCode: 'ko', languageLabel: '한국어', currencySymbol: '₩'),
    CountryPreset(countryName: 'Switzerland (DE)', flag: '🇨🇭', languageCode: 'de', languageLabel: 'Deutsch (CH)', currencySymbol: 'CHF '),
    CountryPreset(countryName: 'Switzerland (FR)', flag: '🇨🇭', languageCode: 'fr', languageLabel: 'Français (CH)', currencySymbol: 'CHF '),
    CountryPreset(countryName: 'Austria', flag: '🇦🇹', languageCode: 'de', languageLabel: 'Deutsch (AT)', currencySymbol: '€'),
    CountryPreset(countryName: 'Belgium', flag: '🇧🇪', languageCode: 'fr', languageLabel: 'Français (BE)', currencySymbol: '€'),
    CountryPreset(countryName: 'Morocco', flag: '🇲🇦', languageCode: 'ar', languageLabel: 'العربية (المغرب)', currencySymbol: 'MAD ', isRtl: true),
    CountryPreset(countryName: 'Algeria', flag: '🇩🇿', languageCode: 'ar', languageLabel: 'العربية (الجزائر)', currencySymbol: 'DZD ', isRtl: true),
    CountryPreset(countryName: 'Tunisia', flag: '🇹🇳', languageCode: 'ar', languageLabel: 'العربية (تونس)', currencySymbol: 'TND ', isRtl: true),
    CountryPreset(countryName: 'Lebanon', flag: '🇱🇧', languageCode: 'ar', languageLabel: 'العربية (لبنان)', currencySymbol: 'LBP ', isRtl: true),
    CountryPreset(countryName: 'Mexico', flag: '🇲🇽', languageCode: 'es', languageLabel: 'Español (MX)', currencySymbol: 'MX\$'),
    CountryPreset(countryName: 'Argentina', flag: '🇦🇷', languageCode: 'es', languageLabel: 'Español (AR)', currencySymbol: 'AR\$'),
    CountryPreset(countryName: 'Colombia', flag: '🇨🇴', languageCode: 'es', languageLabel: 'Español (CO)', currencySymbol: 'COP '),
    CountryPreset(countryName: 'Chile', flag: '🇨🇱', languageCode: 'es', languageLabel: 'Español (CL)', currencySymbol: 'CLP '),
    CountryPreset(countryName: 'Hong Kong', flag: '🇭🇰', languageCode: 'zh', languageLabel: '中文 (香港)', currencySymbol: 'HK\$'),
    CountryPreset(countryName: 'Taiwan', flag: '🇹🇼', languageCode: 'zh', languageLabel: '中文 (台灣)', currencySymbol: 'NT\$'),
    CountryPreset(countryName: 'Kazakhstan', flag: '🇰🇿', languageCode: 'ru', languageLabel: 'Русский (KZ)', currencySymbol: '₸'),
    CountryPreset(countryName: 'Malaysia', flag: '🇲🇾', languageCode: 'en', languageLabel: 'English / MY', currencySymbol: 'RM '),
    CountryPreset(countryName: 'Indonesia', flag: '🇮🇩', languageCode: 'en', languageLabel: 'English / ID', currencySymbol: 'Rp '),
    CountryPreset(countryName: 'Bangladesh', flag: '🇧🇩', languageCode: 'en', languageLabel: 'English / BD', currencySymbol: '৳'),
    CountryPreset(countryName: 'Philippines', flag: '🇵🇭', languageCode: 'en', languageLabel: 'English (PH)', currencySymbol: '₱'),
    CountryPreset(countryName: 'South Africa', flag: '🇿🇦', languageCode: 'en', languageLabel: 'English (ZA)', currencySymbol: 'R '),
    CountryPreset(countryName: 'Nigeria', flag: '🇳🇬', languageCode: 'en', languageLabel: 'English (NG)', currencySymbol: '₦'),
    CountryPreset(countryName: 'Kenya', flag: '🇰🇪', languageCode: 'en', languageLabel: 'English (KE)', currencySymbol: 'KSh '),
    CountryPreset(countryName: 'Pakistan (English)', flag: '🇵🇰', languageCode: 'en', languageLabel: 'English (PK)', currencySymbol: 'PKR '),
  ];
}
