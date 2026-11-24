import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'themes.dart';

class AmbientBackdrop extends StatelessWidget {
  final AppThemePreset theme;
  final Widget child;
  const AmbientBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: theme.bgPrimary),
        Positioned(
          top: -90,
          right: -70,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.accent.withValues(alpha: theme.isLight ? 0.14 : 0.18),
                    theme.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.secondary
                        .withValues(alpha: theme.isLight ? 0.10 : 0.14),
                    theme.secondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class ExecutiveCard extends StatelessWidget {
  final AppThemePreset theme;
  final CardDesignStyle style;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColorOverride;

  const ExecutiveCard({
    super.key,
    required this.theme,
    required this.style,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isCyber = style == CardDesignStyle.cyber;
    final isGlass = style == CardDesignStyle.glass;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isGlass
            ? theme.bgCard.withValues(alpha: theme.isLight ? 0.88 : 0.72)
            : theme.bgCard,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(
          color: borderColorOverride ??
              (isCyber
                  ? theme.accent.withValues(alpha: 0.65)
                  : theme.borderColor),
          width: isCyber ? 1.3 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCyber ? theme.accent : Colors.black)
                .withValues(alpha: theme.isLight ? 0.06 : 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class EmbossedPlateView extends StatelessWidget {
  final String plateText;
  final AppThemePreset theme;
  final CardDesignStyle style;

  const EmbossedPlateView({
    super.key,
    required this.plateText,
    required this.theme,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final clean = plateText.trim().toUpperCase();
    final hasText = clean.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0D111A),
        borderRadius: BorderRadius.circular(style.radius * 0.75),
        border: Border.all(
          color: hasText ? theme.accent : theme.borderColor,
          width: hasText ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_filled,
                    size: 13, color: theme.textOnAccent),
                const SizedBox(height: 2),
                Text(
                  'REG',
                  style: TextStyle(
                    color: theme.textOnAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hasText ? clean : 'LEA • 2026',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: hasText
                    ? theme.textPrimary
                    : theme.textMuted.withValues(alpha: 0.45),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasText)
            Icon(Icons.verified_rounded, color: theme.secondary, size: 18),
        ],
      ),
    );
  }
}

class SegmentedPillTabs extends StatelessWidget {
  final List<({String label, IconData icon})> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppThemePreset theme;

  const SegmentedPillTabs({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          final item = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  color: selected ? theme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: selected ? theme.textOnAccent : theme.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              selected ? theme.textOnAccent : theme.textMuted,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
