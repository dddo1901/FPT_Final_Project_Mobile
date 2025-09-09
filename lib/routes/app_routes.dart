import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';

import 'package:fpt_final_project_mobile/admin/pages/admin_home.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_form_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_list_page.dart';

import 'package:fpt_final_project_mobile/admin/pages/user_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_form_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_detail_page.dart';

import 'package:fpt_final_project_mobile/admin/pages/table_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/table_form_page.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/login_page.dart';
import 'package:fpt_final_project_mobile/auths/not_found_page.dart';
import 'package:fpt_final_project_mobile/auths/role_guard.dart';
import 'package:fpt_final_project_mobile/auths/verify_otp_page.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_home.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_order_list_page.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_table_list_page.dart';
import 'package:provider/provider.dart';

// Claims helper class
class _Claims {
  final int? userId;
  final String? role;
  final String? name;
  final String? avatarUrl;

  const _Claims({this.userId, this.role, this.name, this.avatarUrl});
}

// JWT claims extractor
_Claims _claimsFromJwt(String? token) {
  if (token == null || token.isEmpty) return const _Claims();
  try {
    final parts = token.split('.');
    if (parts.length != 3) return const _Claims();

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    // Helper to pick first non-null value
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = payload[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    // Extract user ID as integer
    final userIdStr = pick(['sub', 'userId', 'id']);
    final userId = userIdStr != null ? int.tryParse(userIdStr) : null;

    // Extract role
    String? role = pick(['role', 'ROLE']);
    if (role == null && payload['roles'] is List) {
      final roles = payload['roles'] as List;
      if (roles.isNotEmpty) role = roles.first.toString();
    }

    return _Claims(
      userId: userId,
      role: role,
      name: pick(['name', 'fullName', 'username']),
      avatarUrl: pick(['avatar', 'avatarUrl', 'image']),
    );
  } catch (e) {
    debugPrint('JWT parse error: $e');
    return const _Claims();
  }
}

// ==================== STATIC ROUTES (no arguments) ====================
final Map<String, WidgetBuilder> appRoutes = {
  // 🔐 Auth
  '/': (_) => const LoginPage(),
  '/verify': (_) => const VerifyOtpPage(),

  // ==================== ADMIN ====================

  // 🔐 Admin Home
  '/admin': (_) => const RoleGuard(allowed: ['ADMIN'], child: AdminHome()),

  // 🔐 Admin Profile
  '/admin/profile': (_) => RoleGuard(
    allowed: const ['ADMIN'],
    child: Builder(
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        final claims = _claimsFromJwt(auth.token);
        final userId = claims.userId;

        if (userId == null) {
          debugPrint('Missing userId in claims for /admin/profile');
          return const NotFoundPage(
            routeName: '/admin/profile (missing userId)',
          );
        }

        return UserDetailPage(userId: userId.toString());
      },
    ),
  ),

  // 🔐 Admin Users
  '/admin/users': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: UserListPage()),
  '/admin/users/create': (_) => RoleGuard(
    allowed: const ['ADMIN'],
    child: Builder(
      builder: (ctx) => UserFormPage(userService: ctx.read<UserService>()),
    ),
  ),

  // 🔐 Admin Tables
  '/admin/tables': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: TableListPage()),
  '/admin/tables/create': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: TableFormPage()),

  // 🔐 Admin Foods
  '/admin/foods': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: FoodListPage()),
  '/admin/foods/create': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: FoodFormPage()),

  // 🔐 Admin Orders
  '/admin/orders': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: OrderListPage()),

  // ==================== STAFF ====================

  // Staff shell
  '/staff': (_) => RoleGuard(
    allowed: const ['STAFF'],
    child: Builder(
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        final claims = _claimsFromJwt(auth.token);
        final userId = claims.userId;
        if (userId == null) {
          return const NotFoundPage(routeName: '/staff (missing userId)');
        }
        return StaffHome(userId: userId.toString());
      },
    ),
  ),

  // Staff Profile
  '/staff/profile': (_) => RoleGuard(
    allowed: const ['STAFF'],
    child: Builder(
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        final claims = _claimsFromJwt(auth.token);
        final userId = claims.userId;
        if (userId == null) {
          return const NotFoundPage(
            routeName: '/staff/profile (missing userId)',
          );
        }
        return UserDetailPage(userId: userId.toString());
      },
    ),
  ),
};

// ==================== DYNAMIC ROUTES (need arguments) ====================
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  final segments = uri.pathSegments;

  // Handle user detail routes
  if (segments.length == 3 &&
      segments[0] == 'admin' &&
      segments[1] == 'users') {
    final userId = segments[2];
    debugPrint('Handling user detail route for ID: $userId');

    // Validate userId format
    if (int.tryParse(userId) == null) {
      debugPrint('Invalid user ID format: $userId');
      return MaterialPageRoute(
        builder: (_) => const NotFoundPage(routeName: 'Invalid user ID format'),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => RoleGuard(
        allowed: const ['ADMIN'],
        child: UserDetailPage(userId: userId),
      ),
    );
  }

  // Handle other dynamic routes based on pattern
  final id = settings.arguments as String?;
  if (id == null || id.isEmpty) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => NotFoundPage(routeName: '${settings.name} (missing id)'),
    );
  }

  // Map routes to pages
  switch (settings.name) {
    case '/admin/users/edit':
      return MaterialPageRoute(
        settings: settings,
        builder: (ctx) => RoleGuard(
          allowed: const ['ADMIN'],
          child: Builder(
            builder: (ctx) {
              final service = ctx.read<UserService>();
              return FutureBuilder<UserModel>(
                future: service.getUserById(id),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return UserFormPage(
                    userService: service,
                    initialUser: snap.data!,
                  );
                },
              );
            },
          ),
        ),
      );

    case '/admin/orders/detail':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => RoleGuard(
          allowed: const ['ADMIN'],
          child: OrderDetailPage(orderId: id),
        ),
      );

    // Add other dynamic routes as needed...
  }

  return null;
}

// ==================== UNKNOWN ROUTE (safety net) ====================
Route<dynamic> onUnknownRoute(RouteSettings settings) => MaterialPageRoute(
  settings: settings,
  builder: (_) => NotFoundPage(routeName: settings.name),
);
