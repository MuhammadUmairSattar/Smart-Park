import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/app_core.dart';
import '../../core/luxury_ui.dart';
import '../parking/parking_logic.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _branchCtrl = TextEditingController(text: 'MAIN');
  final _localAuth = LocalAuthentication();

  bool _isSignUp = false;
  bool _obscure = true;
  bool _canBiometricUnlock = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final hasSession =
          await ref.read(apiServiceProvider).hasBiometricEnabledSession();
      if (mounted) {
        setState(() => _canBiometricUnlock = deviceSupported && hasSession);
      }
    } catch (_) {
      if (mounted) setState(() => _canBiometricUnlock = false);
    }
  }

  Future<void> _biometricLogin() async {
    if (!_canBiometricUnlock) {
      _showFriendlyError(AppLocalizations.tr('biometric_unavailable'));
      return;
    }
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: AppLocalizations.tr('biometric_reason'),
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) return;

      final ok = await ref.read(authProvider.notifier).unlockWithBiometrics();
      if (!ok && mounted) {
        setState(() => _canBiometricUnlock = false);
        _showFriendlyError(AppLocalizations.tr('err_session_expired'));
      }
    } catch (_) {
      _showFriendlyError(AppLocalizations.tr('biometric_unavailable'));
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (!email.contains('@') || pass.length < 6) {
      _showFriendlyError(AppLocalizations.tr('validation_auth'));
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    if (_isSignUp) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showFriendlyError(AppLocalizations.tr('validation_auth'));
        return;
      }
      await notifier.register(
        fullName: _nameCtrl.text.trim(),
        email: email,
        password: pass,
        branchId: _branchCtrl.text.trim().isEmpty
            ? 'MAIN'
            : _branchCtrl.text.trim().toUpperCase(),
      );
    } else {
      await notifier.login(email, pass);
    }
  }

  void _showFriendlyError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openGlobalRegionPicker(AppThemePreset theme) {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final items = WorldCountryPresets.all.where((c) {
            final q = query.toLowerCase();
            return c.countryName.toLowerCase().contains(q) ||
                c.languageLabel.toLowerCase().contains(q) ||
                c.currencySymbol.toLowerCase().contains(q);
          }).toList();

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search 55+ Countries / Currency / Language...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(c.countryName,
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('${c.languageLabel} • ${c.currencySymbol}',
                            style: TextStyle(color: theme.textMuted, fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.currencySymbol.trim(),
                            style: TextStyle(
                                color: theme.accent,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        onTap: () async {
                          await ref
                              .read(settingsProvider.notifier)
                              .applyCountryPreset(c);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final theme = settings.activeTheme;
    final style = settings.activeStyle;
    final lang = AppLocalizations.currentLanguage.value;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        _showFriendlyError(next.errorMessage!);
      }
    });

    return Scaffold(
      body: AmbientBackdrop(
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusPill(
                      label: 'GLOBAL • ${settings.currency.trim()}',
                      color: theme.secondary,
                    ),
                    ActionChip(
                      backgroundColor: theme.bgCard,
                      side: BorderSide(color: theme.borderColor),
                      avatar: Text(lang.flag),
                      label: Text(
                        '${lang.name} • 55+',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      onPressed: () => _openGlobalRegionPicker(theme),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [theme.accent, theme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withValues(alpha: 0.38),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(Icons.shield_rounded,
                            size: 40, color: theme.textOnAccent),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        settings.businessName,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.tr('login_sub'),
                        style: TextStyle(color: theme.textMuted, fontSize: 12.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          StatusPill(
                              label: 'AI ANPR',
                              color: theme.accent,
                              showDot: false,
                              icon: Icons.document_scanner),
                          StatusPill(
                              label: 'HMAC QR',
                              color: theme.secondary,
                              showDot: false,
                              icon: Icons.qr_code_2),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ExecutiveCard(
                        theme: theme,
                        style: style,
                        padding: const EdgeInsets.all(20),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.bgSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    _modeTab(
                                      label: AppLocalizations.tr('login_btn'),
                                      selected: !_isSignUp,
                                      theme: theme,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isSignUp = false);
                                      },
                                    ),
                                    _modeTab(
                                      label: AppLocalizations.tr('signup_btn'),
                                      selected: _isSignUp,
                                      theme: theme,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isSignUp = true);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_isSignUp) ...[
                                TextField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.tr('full_name'),
                                    prefixIcon: Icon(Icons.badge_outlined,
                                        color: theme.accent),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _branchCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.tr('branch_code'),
                                    prefixIcon: Icon(Icons.apartment_rounded,
                                        color: theme.accent),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.tr('email'),
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: theme.accent),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.tr('password'),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: theme.accent),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.accent,
                                    foregroundColor: theme.textOnAccent,
                                  ),
                                  onPressed:
                                      authState.isLoading ? null : _submit,
                                  child: authState.isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: theme.textOnAccent,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isSignUp
                                              ? AppLocalizations.tr(
                                                  'signup_btn')
                                              : AppLocalizations.tr(
                                                  'login_btn'),
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                ),
                              ),
                              if (_canBiometricUnlock && !_isSignUp) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.accent,
                                    side: BorderSide(color: theme.accent),
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          style.radius * 0.8),
                                    ),
                                  ),
                                  onPressed: authState.isLoading
                                      ? null
                                      : _biometricLogin,
                                  icon: const Icon(Icons.fingerprint),
                                  label: Text(AppLocalizations.tr('biometric')),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DeveloperWatermark(theme: theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required bool selected,
    required AppThemePreset theme,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? theme.textOnAccent : theme.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
