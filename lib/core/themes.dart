import 'package:flutter/material.dart';
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

  void _pickLanguage(AppThemePreset theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: AppLocalizations.supportedLanguages.length,
        itemBuilder: (ctx, i) {
          final l = AppLocalizations.supportedLanguages[i];
          final selected = AppLocalizations.currentLanguage.value.code == l.code;
          return ListTile(
            leading: Text(l.flag, style: const TextStyle(fontSize: 22)),
            title: Text(l.name,
                style: TextStyle(
                    color: theme.textPrimary, fontWeight: FontWeight.w600)),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: theme.accent)
                : null,
            onTap: () async {
              await AppLocalizations.setLanguage(l);
              if (ctx.mounted) Navigator.pop(ctx);
            },
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
                      label: 'ENTERPRISE v3',
                      color: theme.secondary,
                    ),
                    ActionChip(
                      backgroundColor: theme.bgCard,
                      side: BorderSide(color: theme.borderColor),
                      avatar: Text(AppLocalizations.currentLanguage.value.flag),
                      label: Text(
                        AppLocalizations.currentLanguage.value.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _pickLanguage(theme),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    child: ExecutiveCard(
                      theme: theme,
                      style: style,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.accent.withValues(alpha: 0.14),
                              border: Border.all(
                                  color: theme.accent.withValues(alpha: 0.5)),
                            ),
                            child: Icon(Icons.shield_rounded,
                                size: 36, color: theme.accent),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            settings.businessName,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.tr('login_sub'),
                            style:
                                TextStyle(color: theme.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
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
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.tr('branch_code'),
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
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.accent,
                                foregroundColor: theme.textOnAccent,
                              ),
                              onPressed: authState.isLoading ? null : _submit,
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
                                          ? AppLocalizations.tr('signup_btn')
                                          : AppLocalizations.tr('login_btn'),
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
                                  borderRadius:
                                      BorderRadius.circular(style.radius * 0.8),
                                ),
                              ),
                              onPressed:
                                  authState.isLoading ? null : _biometricLogin,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(AppLocalizations.tr('biometric')),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp
                                  ? AppLocalizations.tr('toggle_login')
                                  : AppLocalizations.tr('toggle_signup'),
                            ),
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
      ),
    );
  }
}
