// admin/pages/verify_otp_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/widgets/auth_scaffold.dart';
import 'package:fpt_final_project_mobile/auths/widgets/otp_input_field.dart';
import 'package:fpt_final_project_mobile/styles/app_theme.dart';
import 'package:provider/provider.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _emailCtrl = TextEditingController();
  String _otpCode = '';

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

      final resp = await api.verifyOtp(_emailCtrl.text.trim(), _otpCode.trim());
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

    return AuthScaffold(
      title: 'Admin Portal',
      onBackPressed: () => Navigator.pop(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12), // Giảm từ 20 xuống 12
            // Welcome text
            const Text(
              'Verify Your Account!',
              style: TextStyle(
                fontSize: 24, // Giảm từ 28 xuống 24
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6), // Giảm từ 8 xuống 6
            const Text(
              'Enter the verification code sent to your email',
              style: TextStyle(
                fontSize: 14, // Giảm từ 16 xuống 14
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24), // Giảm từ 40 xuống 24
            // Email field
            AuthTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'Your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16), // Giảm từ 24 xuống 16
            // OTP field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                OtpInputField(
                  onCompleted: (code) {
                    setState(() {
                      _otpCode = code;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8), // Giảm từ 16 xuống 8
            // Resend OTP
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend ? 'Resend Code' : 'Resend in $_seconds seconds',
                  style: TextStyle(
                    color: canResend ? AppTheme.primary : AppTheme.textMedium,
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Thêm fontSize nhỏ hơn
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Giảm từ 32 xuống 20
            // Verify button
            AuthButton(
              text: 'Verify Code',
              isLoading: _loading,
              onPressed: _verify,
            ),

            const SizedBox(height: 20), // Giảm từ 40 xuống 20
          ],
        ),
      ),
    );
  }
}
