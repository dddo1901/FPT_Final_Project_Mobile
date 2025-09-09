import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/jwt_claims.dart';
import 'package:provider/provider.dart';
import './styles/login_style.dart';

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
    return Scaffold(
      body: Stack(
        children: [
          // Animated background using GIF
          // Positioned.fill(
          //   child: Image.asset(
          //     'assets/images/login-background.gif',
          //     fit: BoxFit.cover,
          //     // Add color filter to darken the background if needed
          //     color: Colors.black.withOpacity(0.2),
          //     colorBlendMode: BlendMode.darken,
          //   ),
          // ),

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
                      'Log in',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login form
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username field
                          const Text(
                            'Username',
                            style: LoginStyle.textStyleLabel,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _userCtrl,
                            decoration: LoginStyle.decorationInput,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          const Text(
                            'Password',
                            style: LoginStyle.textStyleLabel,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passCtrl,
                            obscureText: !_showPassword,
                            decoration: LoginStyle.decorationInput.copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFF3B82F6)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: LoginStyle.buttonStyle,
                              onPressed: _loading ? null : _login,
                              child: Text(
                                _loading ? 'Logging in...' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // User type toggle
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
