import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  final String? routeName;
  const NotFoundPage({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 - Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Route not found: $routeName'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/admin', (r) => false),
              child: const Text('Về trang Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
