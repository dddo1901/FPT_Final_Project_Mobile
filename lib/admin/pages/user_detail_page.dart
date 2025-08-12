import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_form_page.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/admin/widgets/user_card.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final UserService userService;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userService,
  });

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<UserModel> _userFuture;
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
  }

  Future<UserModel> _fetchUserDetails() async {
    return await widget.userService.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _navigateToUserForm(context),
          ),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          final user = snapshot.data!;
          return _buildUserDetails(user);
        },
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
            user: userForCard,
            onTap: () {
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
          _InfoTile('Email', user.email ?? '—'),
          _InfoTile('Role', user.role ?? '—'),

          const Divider(height: 32),

          const _SectionTitle('Personal'),
          _InfoTile('Full name', user.name ?? '—'),
          _InfoTile('Phone', user.phone ?? '—'),

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

  void _navigateToUserForm(BuildContext context) async {
    final user = await _userFuture;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(
          userService: widget.userService, // Thêm dòng này
          initialUser: user,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _userFuture = _fetchUserDetails();
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${user.name ?? user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteUser(user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value?.isNotEmpty == true ? value! : '—'),
    );
  }
}
