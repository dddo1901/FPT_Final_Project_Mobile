// admin/pages/verify_otp_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:provider/provider.dart';
import './styles/login_style.dart';

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
      body: Stack(
        children: [
          // Logo
          Positioned(
            top: 20,
            left: 20,
            child: Image.asset(
              'assets/images/Logo.png',
              height: 100,
              width: 100,
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Verify form
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          const Text('Email', style: LoginStyle.textStyleLabel),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailCtrl,
                            readOnly: true,
                            decoration: LoginStyle.decorationInput,
                          ),
                          const SizedBox(height: 16),

                          // OTP field
                          const Text(
                            'OTP Code',
                            style: LoginStyle.textStyleLabel,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _codeCtrl,
                            decoration: LoginStyle.decorationInput,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Countdown + Resend
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    canResend
                                        ? 'OTP can be resent'
                                        : 'Resend after: $_seconds s',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: canResend ? _resend : null,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.refresh, size: 18),
                                      SizedBox(width: 8),
                                      Text('Resend OTP'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: LoginStyle.buttonStyle,
                              onPressed: _loading ? null : _verify,
                              child: Text(
                                _loading ? 'Verifying...' : 'Verify',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
