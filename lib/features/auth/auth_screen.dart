import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/app_core.dart';
import '../parking/dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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

  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      builder: (_) => ListView.builder(
        itemCount: AppLocalizations.supportedLanguages.length,
        itemBuilder: (ctx, i) {
          final l = AppLocalizations.supportedLanguages[i];
          return ListTile(
            leading: Text(l.flag, style: const TextStyle(fontSize: 22)),
            title: Text(l.name),
            trailing: AppLocalizations.currentLanguage.value.code == l.code ? const Icon(Icons.check_circle, color: AppTheme.goldAccent) : null,
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
                  onPressed: _pickLanguage,
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
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded, size: 60, color: AppTheme.goldAccent),
                        const SizedBox(height: 10),
                        Text(AppLocalizations.tr('app_name'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        Text(AppLocalizations.tr('login_sub'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 24),
                        TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: AppLocalizations.tr('email'), prefixIcon: const Icon(Icons.person_outline, color: AppTheme.goldAccent))),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.tr('password'),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldAccent),
                            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            onPressed: _loading ? null : _submit,
                            child: _loading ? const CircularProgressIndicator(color: Colors.black) : Text(_isLogin ? AppLocalizations.tr('login_btn') : AppLocalizations.tr('signup_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.goldAccent, side: const BorderSide(color: AppTheme.goldAccent), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
            const DeveloperWatermark(),
          ],
        ),
      ),
    );
  }
}
