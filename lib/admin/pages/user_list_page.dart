import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';
import '../../styles/app_theme.dart';
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<UserModel>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = context.read<UserService>().getUsers();
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<UserService>().getUsers();
    });
  }

  void _navigateToUserDetail(UserModel user) {
    // Show a hint message for better UX
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${user.name}\'s profile...'),
        backgroundColor: AppTheme.info,
        duration: const Duration(milliseconds: 1500),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailPage(userId: user.id)),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    // Check if user is admin - prevent toggling admin users
    if (user.role.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify admin user status'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog first
    _showToggleDialog(user);
  }

  Future<void> _performToggleUserStatus(UserModel user) async {
    try {
      final api = context.read<ApiService>();
      final response = await api.client.put(
        Uri.parse('${api.baseUrl}/api/auth/users/${user.id}/toggle-status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Refresh the list
        await _reload();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${user.isActive ? "deactivated" : "activated"} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TOGGLE USER STATUS ERROR] $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showToggleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Action',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to ${user.isActive ? "deactivate" : "activate"} '
          '${user.name}?\n\n'
          '${user.isActive ? "Deactivating will prevent this user from logging in and accessing the system." : "Activating will restore this user's access to the system."}',
          style: TextStyle(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMedium),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performToggleUserStatus(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive
                  ? AppTheme.danger
                  : AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
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
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  hintText: 'Search by username/email...',
                  hintStyle: TextStyle(color: AppTheme.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snap.error}',
                            style: TextStyle(color: AppTheme.danger),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  final list = (snap.data ?? [])
                      .where(
                        (u) =>
                            _search.isEmpty ||
                            u.username.toLowerCase().contains(
                              _search.toLowerCase(),
                            ) ||
                            u.email.toLowerCase().contains(
                              _search.toLowerCase(),
                            ),
                      )
                      .toList();
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _reload,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final u = list[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                            border: u.role.toLowerCase() == 'admin'
                                ? Border.all(
                                    color: AppTheme.warning.withOpacity(0.3),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardHeaderGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  u.username.isNotEmpty
                                      ? u.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    u.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: u.isActive
                                        ? AppTheme.success.withOpacity(0.1)
                                        : AppTheme.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    u.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: u.isActive
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  '${u.email}',
                                  style: TextStyle(color: AppTheme.textMedium),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: u.role.toLowerCase() == 'admin'
                                        ? AppTheme.warning.withOpacity(0.1)
                                        : AppTheme.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        u.role.toUpperCase(),
                                        style: TextStyle(
                                          color: u.role.toLowerCase() == 'admin'
                                              ? AppTheme.warning
                                              : AppTheme.info,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (u.role.toLowerCase() == 'staff') ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.touch_app,
                                          size: 12,
                                          color: AppTheme.info,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: u.role.toLowerCase() == 'admin'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: AppTheme.warning,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.lock,
                                        color: AppTheme.textLight,
                                        size: 24,
                                      ),
                                    ],
                                  )
                                : Icon(
                                    u.isActive
                                        ? Icons.toggle_on
                                        : Icons.toggle_off,
                                    color: u.isActive
                                        ? AppTheme.success
                                        : AppTheme.textLight,
                                    size: 32,
                                  ),
                            onTap: u.role.toLowerCase() == 'admin'
                                ? null // Disable tap for admin users
                                : () => _toggleUserStatus(u),
                            onLongPress: u.role.toLowerCase() == 'staff'
                                ? () => _navigateToUserDetail(u)
                                : null, // Only enable long press for staff users
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showHelpDialog,
        backgroundColor: AppTheme.info,
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.info),
            const SizedBox(width: 8),
            const Text('User List Guide'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to interact with users:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _helpItem(
              Icons.touch_app,
              'Tap',
              'Toggle active/inactive status (Staff only)',
            ),
            const SizedBox(height: 8),
            _helpItem(
              Icons.touch_app,
              'Long Press',
              'View staff details (Staff only)',
              color: AppTheme.info,
            ),
            const SizedBox(height: 8),
            _helpItem(
              Icons.lock,
              'Admin Users',
              'Protected from status changes',
              color: AppTheme.warning,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(
    IconData icon,
    String action,
    String description, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.textMedium),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: AppTheme.textDark, fontSize: 14),
              children: [
                TextSpan(
                  text: '$action: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
