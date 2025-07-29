import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/entities/user_entity.dart';

class UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const UserCard({
    required this.user,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildAvatar(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(user.email ?? 'No email'),
                  ],
                ),
              ),
              _buildRoleBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (user.imageUrl != null && user.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(user.imageUrl!),
        onBackgroundImageError: (_, __) => Icon(Icons.error),
      );
    } else {
      final initials = user.name != null
          ? user.name!
                .split(' ')
                .map((n) => n[0])
                .join('')
                .substring(0, 2)
                .toUpperCase()
          : user.username.substring(0, 2).toUpperCase();

      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(initials, style: TextStyle(color: Colors.white)),
        radius: 20,
      );
    }
  }

  Widget _buildRoleBadge() {
    final color = user.role == 'ADMIN' ? Colors.blue : Colors.green;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.role,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
