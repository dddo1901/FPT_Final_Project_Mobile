// lib/admin/pages/user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/admin/widgets/user_card.dart';
import '../../styles/app_theme.dart';

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

  Widget _buildUserDetails(UserModel user) {
    final userForCard = user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======= User Profile Card =======
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: UserCard(
              user: userForCard,
              onTap: () {}, // Empty function - no action
              onLongPress: () {}, // Empty function - no action
            ),
          ),

          const SizedBox(height: 16),

          // ======= Account Information Card =======
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Account Information'),
                const SizedBox(height: 12),
                _InfoTile('Username', user.username),
                _InfoTile('Email', user.email),
                _InfoTile('Role', user.role),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======= Personal Information Card =======
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Personal Information'),
                const SizedBox(height: 12),
                _InfoTile('Full name', user.name),
                _InfoTile('Phone', user.phone),
              ],
            ),
          ),

          // ======= Work Information Card (if staff) =======
          if (user.staffProfile != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Work Information'),
                  const SizedBox(height: 12),
                  _InfoTile('Position', user.staffProfile!.position ?? '—'),
                  _InfoTile('Shift', user.staffProfile!.shiftType ?? '—'),
                  _InfoTile(
                    'Work Location',
                    user.staffProfile!.workLocation ?? '—',
                  ),
                  _InfoTile('Address', user.staffProfile!.address ?? '—'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ultraLightBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            final user = snapshot.data;
            if (user == null) {
              return const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return _buildUserDetails(user);
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
