import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConf = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _cityCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final state = context.read<AppState>();
      // Step 1: Register via backend admin API (email is pre-confirmed automatically)
      await state.service.registerViaBackend(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
      );
      // Step 2: Now sign in normally (works because email is already confirmed)
      // Add a timeout to avoid indefinite loading when network/backend is unreachable
      await state.service
          .signIn(_emailCtrl.text.trim(), _passwordCtrl.text)
          .timeout(const Duration(seconds: 15));
      await state.loadUserData();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OTPScreen()));
      }
    } catch (e) {
      final raw = e.toString();
      String friendly;
      if (raw.contains('TimeoutException') || raw.contains('timed out') || raw.contains('SocketException') || raw.contains('AuthRetryableFetchException')) {
        friendly = 'Network error: Unable to reach authentication server. Check your internet connection and backend/supabase configuration.';
      } else {
        friendly = raw.replaceAll('Exception: ', '');
      }
      setState(() => _errorMsg = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController ctrl, String label, {IconData? icon, TextInputType? type, bool obscure = false, VoidCallback? toggleObscure, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: toggleObscure != null
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: toggleObscure)
            : null,
      ),
      validator: validator ?? (v) => v != null && v.isNotEmpty ? null : '$label is required',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.local_library_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              Text('Create account', style: theme.textTheme.displayLarge?.copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              Text('Join LibHub and start reading', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _field(_firstCtrl, 'First Name', icon: Icons.person_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_lastCtrl, 'Last Name')),
                    ]),
                    const SizedBox(height: 14),
                    _field(_emailCtrl, 'Email', icon: Icons.email_outlined, type: TextInputType.emailAddress,
                        validator: (v) => v != null && v.contains('@') ? null : 'Valid email required'),
                    const SizedBox(height: 14),
                    _field(_phoneCtrl, 'Phone', icon: Icons.phone_outlined, type: TextInputType.phone),
                    const SizedBox(height: 14),
                    _field(_addressCtrl, 'Address', icon: Icons.home_outlined),
                    const SizedBox(height: 14),
                    _field(_cityCtrl, 'City', icon: Icons.location_city_outlined),
                    const SizedBox(height: 14),
                    _field(_passwordCtrl, 'Password', icon: Icons.lock_outlined, obscure: _obscurePw,
                        toggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                        validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters'),
                    const SizedBox(height: 14),
                    _field(_confirmCtrl, 'Confirm Password', icon: Icons.lock_outlined, obscure: _obscureConf,
                        toggleObscure: () => setState(() => _obscureConf = !_obscureConf),
                        validator: (v) => v != null && v.isNotEmpty ? null : 'Confirm your password'),
                  ],
                ),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
