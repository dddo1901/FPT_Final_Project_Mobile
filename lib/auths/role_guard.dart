import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowed;
  final Widget child;
  final bool requireAuth;

  const RoleGuard({
    super.key,
    required this.allowed,
    required this.child,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (requireAuth && !auth.isAuthenticated) {
      final navigator = Navigator.of(context);
      Future.microtask(() {
        navigator.pushNamedAndRemoveUntil('/', (_) => false);
      });
      return const SizedBox.shrink();
    }
    if (auth.role != null && allowed.contains(auth.role)) {
      return child;
    }
    return const Scaffold(body: Center(child: Text('403 - Unauthorized')));
  }
}
