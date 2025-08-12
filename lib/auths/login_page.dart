import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';
import '../widgets/loading_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = '';
    });
    print('>>>>>');

    final result = await ApiService.login(_user.text, _pass.text);
    setState(() {
      loading = false;
    });

    if (result.success) {
      Navigator.pushReplacementNamed(
        context,
        '/verify',
        arguments: {'username': _user.text},
      );
    } else {
      setState(() {
        error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Pizza',
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _user,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : _login,
                    child: const Text('Login'),
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
        ),
        if (loading) const LoadingOverlay(),
      ],
    );
  }
}
