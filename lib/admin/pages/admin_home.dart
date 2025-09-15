import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void _go(BuildContext context, String route, {Object? args}) {
    debugPrint(
      '➡️ AdminHome._go: route=$route args=$args',
    ); // Thêm log để debug
    try {
      final result = Navigator.pushNamed(context, route, arguments: args);
      result.then(
        (value) => debugPrint('✅ Điều hướng thành công: $route'),
        onError: (error) => debugPrint('❌ Điều hướng thất bại: $error'),
      );
    } catch (e) {
      debugPrint('❌ Lỗi điều hướng: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi điều hướng: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final claims = _claimsFromJwt(auth.token);

    // Define these variables from claims
    final displayName = claims.name ?? claims.email ?? 'Unknown';
    final role = claims.role?.toUpperCase() ?? 'UNKNOWN';
    final avatarUrl = claims.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          GestureDetector(
            onTap: () {
              // Navigate to profile page instead of user detail
              _go(context, '/admin/profile');
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null ? Text(_initials(displayName)) : null,
              ),
            ),
          ),
        ],
      ),

      drawer: _AdminDrawer(
        onNavigate: (route, {args}) => _go(context, route, args: args),
        displayName: displayName,
        role: role,
        avatarUrl: avatarUrl,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _AdminCard(
              icon: Icons.group,
              title: 'Users',
              subtitle: 'Manage users & roles',
              color: Colors.indigo,
              onTap: () => _go(context, '/admin/users'),
            ),
            _AdminCard(
              icon: Icons.table_restaurant,
              title: 'Tables',
              subtitle: 'List, detail & QR',
              color: Colors.teal,
              onTap: () => _go(context, '/admin/tables'),
            ),
            _AdminCard(
              icon: Icons.fastfood,
              title: 'Foods',
              subtitle: 'Menu & status',
              color: Colors.orange,
              onTap: () => _go(context, '/admin/foods'),
            ),
            _AdminCard(
              icon: Icons.receipt_long,
              title: 'Orders',
              subtitle: 'View & manage',
              color: Colors.purple,
              onTap: () => _go(context, '/admin/orders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final void Function(String route, {Object? args}) onNavigate;
  final String displayName;
  final String role;
  final String? avatarUrl;

  const _AdminDrawer({
    required this.onNavigate,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null ? Text(_initials(displayName)) : null,
              ),
              accountName: Text(displayName),
              accountEmail: Text(role),
              decoration: const BoxDecoration(color: Colors.indigo),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_restaurant),
              title: const Text('Tables'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin/tables');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('Foods'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin/foods');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin/orders');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout'),
              onTap: () => confirmAndLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void confirmAndLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigate('/');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Helpers (JWT decode mini)
class _Claims {
  final String? userId; // Changed to String since sub is email
  final String? role;
  final String? name;
  final String? email;
  final String? avatarUrl;

  const _Claims({
    this.userId,
    this.role,
    this.name,
    this.email,
    this.avatarUrl,
  });
}

_Claims _claimsFromJwt(String? token) {
  if (token == null || token.isEmpty) return const _Claims();
  try {
    final parts = token.split('.');
    if (parts.length != 3) return const _Claims();

    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = json.decode(decoded);

    debugPrint('Raw JWT payload: $payload');

    // Extract email from sub claim
    final email = payload['sub']?.toString();

    // Extract role from authorities array
    String? role;
    if (payload['authorities'] is List) {
      role = (payload['authorities'] as List)
          .firstWhere(
            (auth) => auth.toString().startsWith('ROLE_'),
            orElse: () => '',
          )
          .toString()
          .replaceAll('ROLE_', '');
    }

    debugPrint('''
      Extracted claims:
      - userId: $email
      - email: $email
      - name: $email
      - role: $role
      - avatarUrl: null
    ''');

    return _Claims(
      userId: email, // Use email as userId
      role: role,
      name: email, // Use email as display name for now
      email: email,
      avatarUrl: null, // No avatar URL in this JWT
    );
  } catch (e, stack) {
    debugPrint('JWT parse error: $e');
    debugPrint('Stack trace: $stack');
    return const _Claims();
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
