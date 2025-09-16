import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:provider/provider.dart';
import '../../auths/api_service.dart';

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

  Future<void> _toggleUserStatus(UserModel user) async {
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
        title: const Text('Confirm Action'),
        content: Text(
          'Are you sure you want to ${user.isActive ? "deactivate" : "activate"} '
          '${user.name}?\n\n'
          '${user.isActive ? "Deactivating will prevent this user from logging in and accessing the system." : "Activating will restore this user\'s access to the system."}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performToggleUserStatus(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
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
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by username/email...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final list = (snap.data ?? [])
                    .where(
                      (u) =>
                          _search.isEmpty ||
                          u.username.toLowerCase().contains(
                            _search.toLowerCase(),
                          ) ||
                          u.email.toLowerCase().contains(_search.toLowerCase()),
                    )
                    .toList();
                if (list.isEmpty) return const Center(child: Text('No users'));
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            u.username.isNotEmpty
                                ? u.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                u.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: u.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('${u.email} • ${u.role}'),
                        onTap: () => _toggleUserStatus(u),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
