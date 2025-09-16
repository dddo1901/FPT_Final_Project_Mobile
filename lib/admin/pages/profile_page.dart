// lib/admin/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import '../../auths/api_service.dart';

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
    return svc.getCurrentUser();
  }

  Future<void> _reload() async {
    setState(() {
      _userFuture = _fetchCurrentUser();
    });
  }

  void _navigateToEditProfile(BuildContext context, UserModel user) async {
    final result = await Navigator.pushNamed(
      context,
      '/admin/users/edit',
      arguments: user.id,
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => obscureCurrentPassword = !obscureCurrentPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => obscureNewPassword = !obscureNewPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => obscureConfirmPassword = !obscureConfirmPassword,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _changePassword(
                context,
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              ),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final api = context.read<ApiService>();
      final response = await api.client.put(
        Uri.parse('${api.baseUrl}/api/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"currentPassword": "$currentPassword", "newPassword": "$newPassword"}',
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Basic Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _navigateToEditProfile(context, user),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Profile',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ProfileInfoRow(
                                icon: Icons.person,
                                label: 'Username',
                                value: user.username,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.badge,
                                label: 'Full Name',
                                value: user.name,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: user.email,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: user.phone,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.admin_panel_settings,
                                label: 'Role',
                                value: user.role,
                              ),
                              _ProfileInfoRow(
                                icon: user.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                label: 'Status',
                                value: user.isActive ? 'Active' : 'Inactive',
                                valueColor: user.isActive
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Staff Profile Card (if exists)
                      if (user.staffProfile != null) ...[
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff Information',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                if (user.staffProfile!.position != null)
                                  _ProfileInfoRow(
                                    icon: Icons.work,
                                    label: 'Position',
                                    value: user.staffProfile!.position!,
                                  ),
                                if (user.staffProfile!.shiftType != null)
                                  _ProfileInfoRow(
                                    icon: Icons.schedule,
                                    label: 'Shift Type',
                                    value: user.staffProfile!.shiftType!,
                                  ),
                                if (user.staffProfile!.workLocation != null)
                                  _ProfileInfoRow(
                                    icon: Icons.location_on,
                                    label: 'Work Location',
                                    value: user.staffProfile!.workLocation!,
                                  ),
                                if (user.staffProfile!.status != null)
                                  _ProfileInfoRow(
                                    icon: Icons.info,
                                    label: 'Staff Status',
                                    value: user.staffProfile!.status!,
                                  ),
                                if (user.staffProfile!.gender != null)
                                  _ProfileInfoRow(
                                    icon: Icons.person_outline,
                                    label: 'Gender',
                                    value: user.staffProfile!.gender!,
                                  ),
                                if (user.staffProfile!.dob != null)
                                  _ProfileInfoRow(
                                    icon: Icons.cake,
                                    label: 'Date of Birth',
                                    value: user.staffProfile!.dob!,
                                  ),
                                if (user.staffProfile!.address != null)
                                  _ProfileInfoRow(
                                    icon: Icons.home,
                                    label: 'Address',
                                    value: user.staffProfile!.address!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Actions Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Actions',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(
                                  Icons.lock,
                                  color: Colors.orange,
                                ),
                                title: const Text('Change Password'),
                                subtitle: const Text(
                                  'Update your account password',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _showChangePasswordDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
