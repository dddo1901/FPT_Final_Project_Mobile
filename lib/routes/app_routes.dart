import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';

import 'package:fpt_final_project_mobile/admin/pages/admin_home.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_form_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/table_detail_page.dart';

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
import 'package:provider/provider.dart';

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
        if (userId == null || userId.isEmpty) {
          return const NotFoundPage(
            routeName: '/admin/profile (missing userId)',
          );
        }
        return UserDetailPage(userId: userId);
      },
    ),
  ),

  // 🔐 Admin Users
  '/admin/users': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: UserListPage()),
  '/admin/users/create': (_) => RoleGuard(
    allowed: const ['ADMIN'],
    child: Builder(
      builder: (ctx) => UserFormPage(
        userService: ctx.read<UserService>(), // ✅ inject từ Provider
        initialUser: null, // tạo mới
      ),
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
        if (userId == null || userId.isEmpty) {
          return const NotFoundPage(routeName: '/staff (missing userId)');
        }
        return StaffHome(userId: userId);
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
        if (userId == null || userId.isEmpty) {
          return const NotFoundPage(
            routeName: '/staff/profile (missing userId)',
          );
        }
        return UserDetailPage(userId: userId);
      },
    ),
  ),
};

// ==================== DYNAMIC ROUTES (need arguments) ====================
Route<dynamic>? onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    // ----- Users -----
    case '/admin/users/detail':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundPage(
              routeName: '/admin/users/detail (missing id)',
            ),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: UserDetailPage(userId: id),
          ),
          settings: s,
        );
      }

    case '/admin/users/edit':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) =>
                const NotFoundPage(routeName: '/admin/users/edit (missing id)'),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (ctx) => RoleGuard(
            allowed: const ['ADMIN'],
            child: Builder(
              builder: (ctx2) {
                final svc = ctx2.read<UserService>(); // ✅ lấy service
                return FutureBuilder<UserModel>(
                  future: svc.getUserById(id), // tải user để edit
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError || !snap.hasData) {
                      return Scaffold(
                        body: Center(
                          child: Text(
                            'Load user failed: ${snap.error ?? "No data"}',
                          ),
                        ),
                      );
                    }
                    return UserFormPage(
                      userService: svc, // ✅ truyền service
                      initialUser: snap.data!, // ✅ truyền user cho form
                    );
                  },
                );
              },
            ),
          ),
          settings: s,
        );
      }

    // ----- Tables -----
    case '/admin/tables/edit':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundPage(
              routeName: '/admin/tables/edit (missing id)',
            ),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: TableFormPage(tableId: id),
          ),
          settings: s,
        );
      }

    case '/admin/tables/detail':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundPage(
              routeName: '/admin/tables/detail (missing id)',
            ),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: TableDetailPage(tableId: id),
          ),
          settings: s,
        );
      }

    // ----- Foods -----
    case '/admin/foods/edit':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) =>
                const NotFoundPage(routeName: '/admin/foods/edit (missing id)'),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: FoodFormPage(foodId: id),
          ),
          settings: s,
        );
      }

    case '/admin/foods/detail':
      {
        final id = s.arguments as String?;
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundPage(
              routeName: '/admin/foods/detail (missing id)',
            ),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: FoodDetailPage(foodId: id),
          ),
          settings: s,
        );
      }

    // ----- Order -----
    case '/admin/orders/detail':
      {
        final id = s.arguments as String?;
        debugPrint('➡️ onGenerateRoute /admin/orders/detail id=$id'); // debug
        if (id == null || id.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundPage(
              routeName: '/admin/orders/detail (missing id)',
            ),
            settings: s,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            allowed: const ['ADMIN'],
            child: OrderDetailPage(orderId: id), // ✅ không phải SizedBox
          ),
          settings: s,
        );
      }
  }
  return null; // rơi xuống onUnknownRoute
}

// ==================== UNKNOWN ROUTE (safety net) ====================
Route<dynamic> onUnknownRoute(RouteSettings s) => MaterialPageRoute(
  builder: (_) => NotFoundPage(routeName: s.name),
  settings: s,
);

class _Claims {
  final String? userId;
  final String? role;
  final String? name;
  final String? avatarUrl;
  const _Claims({this.userId, this.role, this.name, this.avatarUrl});
}

_Claims _claimsFromJwt(String? token) {
  if (token == null || token.isEmpty) return const _Claims();
  try {
    final parts = token.split('.');
    if (parts.length != 3) return const _Claims();
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    String? _pick(List<String> keys) {
      for (final k in keys) {
        final v = payload[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    // role có thể là 'role', 'roles' (array), 'authorities', 'scope'...
    String? role = _pick(['role', 'ROLE', 'authority']);
    role ??= (payload['roles'] is List && (payload['roles'] as List).isNotEmpty)
        ? (payload['roles'] as List).first.toString()
        : null;
    role ??=
        (payload['authorities'] is List &&
            (payload['authorities'] as List).isNotEmpty)
        ? (payload['authorities'] as List).first.toString()
        : null;

    return _Claims(
      userId: _pick(['sub', 'userId', 'id']),
      role: role,
      name: _pick(['name', 'fullName', 'username', 'email', 'sub']),
      avatarUrl: _pick(['avatar', 'avatarUrl', 'image', 'imageUrl', 'picture']),
    );
  } catch (_) {
    return const _Claims();
  }
}
