import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/widgets/ui_actions.dart';
import 'package:provider/provider.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/models/claims.dart';

class StaffHome extends StatelessWidget {
  final String userId; // staff hiện tại
  const StaffHome({super.key, required this.userId});

  void _go(BuildContext context, String route, {Object? args}) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final cross = isWide ? 3 : 2;

    final auth = context.watch<AuthProvider>();
    final claims = Claims.fromJwt(auth.token ?? '');
    final displayName = claims.email;
    final role = (claims.role ?? 'STAFF').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/staff/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                child: Text(_initials(displayName ?? 'Unknown')),
              ),
            ),
          ),
        ],
      ),

      drawer: _StaffDrawer(
        onNavigate: (route, {args}) => _go(context, route, args: args),
        displayName: displayName ?? 'Unknown',
        role: role,
        avatarUrl: null,
        userId: userId,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: cross,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StaffCard(
              icon: Icons.table_restaurant,
              title: 'Tables',
              subtitle: 'List & detail',
              color: Colors.teal,
              onTap: () => _go(context, '/staff/tables'),
            ),
            _StaffCard(
              icon: Icons.fastfood,
              title: 'Foods',
              subtitle: 'Menu & status',
              color: Colors.orange,
              onTap: () => _go(context, '/staff/foods'),
            ),
            _StaffCard(
              icon: Icons.receipt_long,
              title: 'Orders',
              subtitle: 'Incoming & history',
              color: Colors.purple,
              onTap: () => _go(context, '/staff/orders'),
            ),
            _StaffCard(
              icon: Icons.assignment,
              title: 'Requests',
              subtitle: 'Leave, swap & overtime',
              color: Colors.deepOrange,
              onTap: () => _go(context, '/staff/requests'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDrawer extends StatelessWidget {
  final void Function(String route, {Object? args}) onNavigate;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final String userId;

  const _StaffDrawer({
    required this.onNavigate,
    required this.displayName,
    required this.role,
    required this.avatarUrl,
    required this.userId,
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
                backgroundImage:
                    (avatarUrl != null && avatarUrl!.startsWith('http'))
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || !avatarUrl!.startsWith('http'))
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              accountName: Text(displayName),
              accountEmail: Text(role),
              decoration: const BoxDecoration(color: Colors.indigo),
              onDetailsPressed: () =>
                  Navigator.pushNamed(context, '/staff/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/staff/profile');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.table_restaurant),
              title: const Text('Tables'),
              onTap: () {
                Navigator.pop(context);
                onNavigate('/admin/tables');
              },
            ),
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
}

class _StaffCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StaffCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.12);
    final fg = color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: fg),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_ios, size: 16, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// Helpers (JWT decode mini)
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
