import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().service.sendPasswordResetEmail(email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text('Email Sent!', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
                  const SizedBox(height: 12),
                  Text(
                    'Check your inbox for a password reset link.\nFollow the link to set a new password.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Sign In'),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock_reset_outlined, color: AppTheme.primaryColor, size: 36),
                  ),
                  const SizedBox(height: 24),
                  Text('Reset your password', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text("Enter your email and we'll send you a reset link.", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send Reset Link'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
