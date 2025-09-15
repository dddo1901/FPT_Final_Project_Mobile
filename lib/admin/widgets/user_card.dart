import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fpt_final_project_mobile/admin/entities/user_entity.dart';
import 'package:fpt_final_project_mobile/auths/api_service.dart';

class UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(child: _infoSection(context)),
              const SizedBox(width: 12),
              _rolePill(user.role),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    return Builder(
      builder: (context) {
        final initial = (user.username.isNotEmpty ? user.username[0] : '?')
            .toUpperCase();
        final raw = user.imageUrl;
        String? fullUrl;
        if (raw != null && raw.trim().isNotEmpty) {
          if (raw.startsWith('http://') || raw.startsWith('https://')) {
            fullUrl = raw;
          } else if (raw.startsWith('/')) {
            // relative path -> prepend baseUrl
            final api = context.read<ApiService>();
            fullUrl = '${api.baseUrl}$raw';
          } else {
            // maybe already partial without leading slash
            final api = context.read<ApiService>();
            fullUrl = '${api.baseUrl}/$raw';
          }
        }
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (fullUrl != null) ? NetworkImage(fullUrl) : null,
          child: (fullUrl == null)
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _infoSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 2),

        // Username
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Email
        Row(
          children: [
            const Icon(Icons.email, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
            ),
          ],
        ),

        if (user.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _rolePill(String rawRole) {
    final role = rawRole.toUpperCase();
    late final Color color;
    switch (role) {
      case 'ADMIN':
        color = Colors.blue;
        break;
      case 'STAFF':
        color = Colors.orange;
        break;
      case 'SHIPPER':
        color = Colors.purple;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
