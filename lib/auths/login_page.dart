import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/jwt_claims.dart';
import 'package:fpt_final_project_mobile/auths/widgets/auth_scaffold.dart';
import 'package:fpt_final_project_mobile/styles/app_theme.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthProvider>();

      final resp = await api.login(_userCtrl.text.trim(), _passCtrl.text);
      final token = (resp['token'] ?? resp['accessToken'] ?? resp['jwt'] ?? '')
          .toString();
      if (token.isEmpty) throw Exception('Token is empty.');
      final claims = parseJwtClaims(token);
      final role = pickPrimaryRole(claims.roles);
      final email = claims.email ?? _userCtrl.text.trim();

      await auth.login(token: token, role: role);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/verify', arguments: {'email': email, 'role': role});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Admin Portal',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12), // Giảm từ 20 xuống 12
            // Welcome text
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 24, // Giảm từ 28 xuống 24
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6), // Giảm từ 8 xuống 6
            const Text(
              'Sign in to continue to your account',
              style: TextStyle(
                fontSize: 14, // Giảm từ 16 xuống 14
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24), // Giảm từ 40 xuống 24
            // Username field
            AuthTextField(
              controller: _userCtrl,
              label: 'Username',
              hint: 'Enter your username',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16), // Giảm từ 24 xuống 16
            // Password field
            AuthTextField(
              controller: _passCtrl,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              isPassword: true,
              showPassword: _showPassword,
              onTogglePassword: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
            const SizedBox(height: 8), // Giảm từ 16 xuống 8
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/verify-otp');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Thêm fontSize nhỏ hơn
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Giảm từ 32 xuống 20
            // Login button
            AuthButton(text: 'Sign In', isLoading: _loading, onPressed: _login),

            const SizedBox(height: 20), // Giảm từ 40 xuống 20
          ],
        ),
      ),
    );
  }
}
