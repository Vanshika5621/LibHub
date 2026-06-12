import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _ctrls = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(4, (_) => FocusNode());
  bool _sending = false;
  bool _verifying = false;
  String? _error;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _foci) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() { _sending = true; _error = null; });
    final result = await context.read<AppState>().service.sendOTP();
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
        if (result['error'] != null) _error = result['error'].toString();
      });
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _ctrls.map((c) => c.text).join();
    if (otp.length != 4) {
      setState(() => _error = 'Enter all 4 digits');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    final result = await context.read<AppState>().service.verifyOTP(otp);
    if (mounted) {
      setState(() => _verifying = false);
      if (result['success'] == true) {
        // Reload profile to get updated email_verified flag
        await context.read<AppState>().loadUserData();
        if (mounted) Navigator.of(context).pop(); // pop back to main
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Verification failed');
      }
    }
  }

  void _onDigitInput(int index, String value) {
    if (value.length == 1 && index < 3) {
      _foci[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _foci[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.primaryColor, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Check your email', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to ${state.currentUser?.email ?? 'your email'}.\nIt expires in 5 minutes.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            // OTP Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 64, height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextFormField(
                    controller: _ctrls[i],
                    focusNode: _foci[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _ctrls[i].text.isNotEmpty ? AppTheme.primaryColor : AppTheme.lightBorder,
                          width: _ctrls[i].text.isNotEmpty ? 2 : 1,
                        ),
                      ),
                    ),
                    onChanged: (v) => _onDigitInput(i, v),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verifyOTP,
                child: _verifying
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Email'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(_sending ? 'Sending...' : 'Resend Code'),
              onPressed: _sending ? null : _sendOTP,
            ),
          ],
        ),
      ),
    );
  }
}
