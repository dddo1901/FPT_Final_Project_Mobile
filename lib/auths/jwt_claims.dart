import 'dart:convert';

class JwtClaims {
  final String? email; // từ `sub`
  final Set<String> roles; // từ `authorities` (đã bỏ ROLE_)
  const JwtClaims({this.email, this.roles = const {}});
}

String _normRole(String r) => r.replaceAll('ROLE_', '').toUpperCase();

Map<String, dynamic> _decodePayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return {};
  final payloadB64 = base64Url.normalize(parts[1]);
  final payloadStr = utf8.decode(base64Url.decode(payloadB64));
  return jsonDecode(payloadStr) as Map<String, dynamic>;
}

/// Parse đúng yêu cầu: email = sub; roles = authorities (bỏ ROLE_)
JwtClaims parseJwtClaims(String token) {
  try {
    final p = _decodePayload(token);

    // email theo sub
    final email = (p['sub']?.toString().isNotEmpty ?? false)
        ? p['sub'].toString()
        : null;

    // roles theo authorities
    final roles = <String>{};
    final authorities = p['authorities'];

    if (authorities is List) {
      for (final a in authorities) {
        if (a is String && a.isNotEmpty) {
          roles.add(_normRole(a));
        } else if (a is Map &&
            a['authority'] is String &&
            a['authority'].toString().isNotEmpty) {
          roles.add(_normRole(a['authority'] as String));
        }
      }
    }

    return JwtClaims(email: email, roles: roles);
  } catch (_) {
    return const JwtClaims();
  }
}

/// Chọn role chính để điều hướng/hiển thị
String pickPrimaryRole(Set<String> roles) {
  if (roles.contains('ADMIN')) return 'ADMIN';
  if (roles.contains('STAFF')) return 'STAFF';
  return roles.isNotEmpty ? roles.first : 'UNKNOWN';
}
