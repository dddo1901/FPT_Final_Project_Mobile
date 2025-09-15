import 'dart:convert';
import 'package:flutter/material.dart';

/// JWT Claims helper class for extracting user info from JWT tokens
class Claims {
  final String? email; // Email from JWT 'sub' field
  final String? role; // Role from JWT 'authorities' field
  final String? name; // Display name (defaults to email)
  final String? avatarUrl; // Avatar URL (not in JWT, always null)
  final String? userId; // User ID fetched from /api/auth/me

  const Claims({this.email, this.role, this.name, this.avatarUrl, this.userId});

  /// Extract claims from JWT token
  static Claims fromJwt(String? token) {
    if (token == null || token.isEmpty) return const Claims();

    try {
      final parts = token.split('.');
      if (parts.length != 3) return const Claims();

      // Decode JWT payload
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> claims = json.decode(decoded);

      debugPrint('Raw JWT payload: $claims');

      // Helper to pick first non-null value
      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = claims[k];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
        return null;
      }

      // Extract email from 'sub' field (this is what JWT actually contains)
      final email = pick(['sub']);

      // Extract role from authorities array
      String? role = pick(['role', 'ROLE']);
      if (role == null && claims['authorities'] is List) {
        final authorities = claims['authorities'] as List;
        if (authorities.isNotEmpty) {
          String auth = authorities.first.toString();
          // Remove ROLE_ prefix if present
          role = auth.startsWith('ROLE_') ? auth.substring(5) : auth;
        }
      }

      final result = Claims(
        email: email, // Email from JWT 'sub'
        role: role, // Role from JWT 'authorities'
        name: email, // Use email as display name for now
        avatarUrl: null, // Not in JWT
        userId: null, // Will be fetched separately via /api/auth/me
      );

      debugPrint('      Extracted claims:');
      debugPrint('      - email: ${result.email}');
      debugPrint('      - role: ${result.role}');
      debugPrint('      - name: ${result.name}');
      debugPrint('      - avatarUrl: ${result.avatarUrl}');
      debugPrint('      - userId: ${result.userId} (will be fetched from /me)');
      debugPrint('');

      return result;
    } catch (e) {
      debugPrint('JWT parse error: $e');
      return const Claims();
    }
  }

  /// Create a copy with updated userId (after fetching from /api/auth/me)
  Claims copyWith({
    String? email,
    String? role,
    String? name,
    String? avatarUrl,
    String? userId,
  }) {
    return Claims(
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Claims(email: $email, role: $role, name: $name, avatarUrl: $avatarUrl, userId: $userId)';
  }
}
