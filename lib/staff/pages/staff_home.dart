import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/widgets/ui_actions.dart';
import 'package:provider/provider.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/models/claims.dart';
import '../../styles/app_theme.dart';

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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification Icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _go(context, '/staff/requests');
                  },
                ),
                // Badge for notification count
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '2', // TODO: Replace with actual count
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/staff/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  _initials(displayName ?? 'Unknown'),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.ultraLightBlue, AppTheme.surface],
            stops: [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1, // Tỷ lệ để tránh overflow
            children: [
              _StaffCard(
                icon: Icons.table_restaurant,
                title: 'Tables',
                subtitle: 'List & detail',
                color: AppTheme.info,
                onTap: () => _go(context, '/staff/tables'),
              ),
              _StaffCard(
                icon: Icons.fastfood,
                title: 'Foods',
                subtitle: 'Menu & status',
                color: AppTheme.warning,
                onTap: () => _go(context, '/staff/foods'),
              ),
              _StaffCard(
                icon: Icons.receipt_long,
                title: 'Orders',
                subtitle: 'Incoming & history',
                color: AppTheme.primary,
                onTap: () => _go(context, '/staff/orders'),
              ),
              _StaffCard(
                icon: Icons.assignment,
                title: 'Requests',
                subtitle: 'Leave, swap & overtime',
                color: AppTheme.success,
                onTap: () => _go(context, '/staff/requests'),
              ),
            ],
          ),
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
                backgroundColor: Colors.white,
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
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              accountName: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              accountEmail: Text(role),
              decoration: const BoxDecoration(
                gradient: AppTheme.cardHeaderGradient,
              ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12), // Giảm từ 20 xuống 12
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
          children: [
            Container(
              width: 32, // Giảm từ 48 xuống 32
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), // Giảm từ 12 xuống 8
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 18, color: color), // Giảm từ 24 xuống 18
            ),
            const SizedBox(height: 8), // Giảm từ 16 xuống 8
            Flexible(
              // Thay đổi Text thành Flexible
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Giảm từ 18 xuống 14
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Giảm từ 4 xuống 2
            Flexible(
              // Thay đổi Text thành Flexible
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12, // Giảm từ 14 xuống 12
                  color: AppTheme.textMedium,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8), // Thay Spacer bằng SizedBox cố định
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24, // Giảm từ 32 xuống 24
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Giảm từ 8 xuống 6
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12, // Giảm từ 16 xuống 12
                  color: color,
                ),
              ),
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
