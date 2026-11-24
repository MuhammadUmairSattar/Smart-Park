import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CardDesignStyle {
  luxury('Luxury Gold', 16),
  rounded('Modern Soft', 24),
  sharp('Executive Sharp', 8),
  cyber('Cyber Neon', 14),
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

  Color get textPrimary =>
      isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get textMuted =>
      isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get textOnAccent =>
      accent.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  Color get borderColor =>
      isLight ? const Color(0x1A0F172A) : const Color(0x1AFFFFFF);

  ThemeData toThemeData(CardDesignStyle style) {
    final base = isLight ? ThemeData.light() : ThemeData.dark();
    final bodyTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
    final headingStyle = GoogleFonts.outfit(
      color: textPrimary,
      fontWeight: FontWeight.w800,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accent,
      textTheme: bodyTheme.copyWith(
        headlineMedium: headingStyle.copyWith(fontSize: 24),
        titleLarge: headingStyle.copyWith(fontSize: 20),
        titleMedium: headingStyle.copyWith(fontSize: 16),
      ),
      colorScheme:
          (isLight ? const ColorScheme.light() : const ColorScheme.dark())
              .copyWith(
        primary: accent,
        secondary: secondary,
        surface: bgSurface,
        error: const Color(0xFFEF4444),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSurface.withValues(alpha: 0.94),
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style.radius * 0.8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        labelStyle: TextStyle(color: textMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
