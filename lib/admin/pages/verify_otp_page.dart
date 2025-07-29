import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/utils/api_service.dart';
import '../widgets/loading_overlay.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});
  @override
  _VerifyOtpPageState createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otp = TextEditingController();
  bool loading = false;
  String error = '';
  String username = '';
  int timer = 60;
  late Timer _countdown;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    username = args['username'];
    _startTimer();
    super.didChangeDependencies();
  }

  void _startTimer() {
    timer = 60;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() {
          timer--;
        });
      }
    });
  }

  Future<void> _resend() async {
    await ApiService.resendOtp(username);
    _startTimer();
  }

  Future<void> _verify() async {
    setState(() {
      loading = true;
      error = '';
    });
    final result = await ApiService.verifyOtp(_otp.text);

    setState(() {
      loading = false;
    });

    if (result.success) {
      if (result.role == 'ADMIN') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/customer');
      }
    } else {
      setState(() {
        error = result.message;
      });
    }
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('OTP sent via email'),
                  TextField(
                    controller: _otp,
                    decoration: const InputDecoration(labelText: 'OTP'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : _verify,
                    child: const Text('Verify'),
                  ),
                  const SizedBox(height: 16),
                  timer > 0
                      ? Text('Resend in $timer s')
                      : TextButton(
                          onPressed: _resend,
                          child: const Text('Resend OTP'),
                        ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (loading) const LoadingOverlay(),
        ],
      ),
    );
  }
}
