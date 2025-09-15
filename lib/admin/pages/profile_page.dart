// lib/admin/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/admin/widgets/user_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchCurrentUser();
  }

  Future<UserModel> _fetchCurrentUser() async {
    final svc = context.read<UserService>();
    return svc.getCurrentUser(); // Use the new getCurrentUser method
  }

  Future<void> _reload() async {
    setState(() {
      _userFuture = _fetchCurrentUser();
    });
  }

  void _navigateToUserForm(BuildContext context) async {
    // Note: Profile editing might need different logic since it's current user
    final result = await Navigator.pushNamed(
      context,
      '/admin/users/edit',
      arguments: 'me', // Special argument for current user
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          FilledButton.tonalIcon(
            onPressed: () => _navigateToUserForm(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: UserCard(
              user: user,
              onTap: () {}, // Empty callback for profile view
              onLongPress: () {}, // Empty callback for profile view
            ),
          );
        },
      ),
    );
  }
}
