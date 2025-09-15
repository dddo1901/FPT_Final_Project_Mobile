// lib/admin/pages/user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/admin/widgets/user_card.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
  }

  Future<UserModel> _fetchUserDetails() async {
    final svc = context.read<UserService>();
    return svc.getUserById(widget.userId);
  }

  Future<void> _reload() async {
    setState(() {
      _userFuture = _fetchUserDetails();
    });
  }

  void _navigateToUserForm(BuildContext context) async {
    // Đi theo route edit, truyền userId qua arguments
    final result = await Navigator.pushNamed(
      context,
      '/admin/users/edit',
      arguments: widget.userId,
    );

    // Nếu form báo thành công -> reload
    if (result == true && mounted) {
      _reload();
    }
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${user.name.isNotEmpty ? user.name : user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final userService = context.read<UserService>();

              navigator.pop(); // close dialog
              try {
                await userService.deleteUser(user.id);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
                navigator.pop(); // back to list
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(UserModel user) {
    final userForCard = user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======= Header card =======
          UserCard(
            user: userForCard, // UserEntity/UserModel tuỳ bạn đã khai báo
            onTap: () {
              // cho trải nghiệm giống yêu cầu
              Navigator.pop(context);
              _navigateToUserForm(context);
            },
            onLongPress: () => _showDeleteConfirmation(context, user),
          ),

          const SizedBox(height: 16),
          const Divider(height: 32),

          // ======= Account section =======
          const _SectionTitle('Account'),
          _InfoTile('Username', user.username),
          _InfoTile('Email', user.email),
          _InfoTile('Role', user.role),

          const Divider(height: 32),

          const _SectionTitle('Personal'),
          _InfoTile('Full name', user.name),
          _InfoTile('Phone', user.phone),

          const Divider(height: 32),

          if (user.staffProfile != null) ...[
            const _SectionTitle('Work'),
            _InfoTile('Position', user.staffProfile!.position ?? '—'),
            _InfoTile('Shift', user.staffProfile!.shiftType ?? '—'),
            _InfoTile('Work Location', user.staffProfile!.workLocation ?? '—'),
            _InfoTile('Address', user.staffProfile!.address ?? '—'),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToUserForm(context);
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: () => _showDeleteConfirmation(context, user),
              ),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToUserForm(context),
          ),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return _buildUserDetails(user);
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoTile(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.trim().isEmpty) ? '—' : value!;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(display),
    );
  }
}
