// admin/pages/verify_otp_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:provider/provider.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _loading = false;
  int _seconds = 60;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final email = (args['email'] ?? '').toString();
      if (email.isNotEmpty && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = email;
      }
    }
    // Bắt đầu đếm ngay lần đầu vào
    _startCountdown(resetTo: 60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown({int resetTo = 60}) {
    _timer?.cancel();
    setState(() => _seconds = resetTo);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthProvider>();

      final resp = await api.verifyOtp(
        _emailCtrl.text.trim(),
        _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp['message']?.toString() ?? 'Verify success'),
        ),
      );

      final role = auth.role;

      _goHomeByRole(role!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verify failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final api = context.read<ApiService>();
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email is empty')));
        return;
      }
      final resp = await api.resendOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp['message']?.toString() ?? 'OTP sent')),
      );
      _startCountdown(resetTo: 60); // reset countdown
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resend failed: $e')));
    }
  }

  void _goHomeByRole(String role) {
    switch (role) {
      case 'ADMIN':
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
        break;
      case 'STAFF':
        Navigator.of(context).pushNamedAndRemoveUntil('/staff', (_) => false);
        break;
      case 'SHIPPER':
        Navigator.of(context).pushNamedAndRemoveUntil('/shipper', (_) => false);
        break;
      default:
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _seconds == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              readOnly: true, // luôn dùng email đã login
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Countdown + Resend
            Row(
              children: [
                Expanded(
                  child: Text(
                    canResend ? 'Otp can resend.' : 'After: $_seconds s',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: canResend ? _resend : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resend OTP'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: Text(_loading ? 'Verifying...' : 'Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
