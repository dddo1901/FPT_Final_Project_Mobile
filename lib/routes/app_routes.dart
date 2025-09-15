import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/models/claims.dart';

import 'package:fpt_final_project_mobile/admin/pages/admin_home.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/food_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/order_management_page.dart';

import 'package:fpt_final_project_mobile/admin/pages/user_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_form_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/user_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/profile_page.dart';

import 'package:fpt_final_project_mobile/admin/pages/table_list_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/table_detail_page.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';
import 'package:fpt_final_project_mobile/auths/login_page.dart';
import 'package:fpt_final_project_mobile/auths/not_found_page.dart';
import 'package:fpt_final_project_mobile/auths/role_guard.dart';
import 'package:fpt_final_project_mobile/auths/verify_otp_page.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_home.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_food_list_page.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_table_list_page.dart';
import 'package:fpt_final_project_mobile/staff/pages/staff_order_list_page.dart';
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
        final claims = Claims.fromJwt(auth.token);
        final email = claims.email;

        if (email == null) {
          debugPrint('Missing email in claims for /admin/profile');
          return const NotFoundPage(
            routeName: '/admin/profile (missing email)',
          );
        }

        // For profile, we don't need userId - ProfilePage will call /api/auth/me
        return const ProfilePage();
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

  // 🔐 Admin Foods
  '/admin/foods': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: FoodListPage()),

  // 🔐 Admin Orders
  '/admin/orders': (_) =>
      const RoleGuard(allowed: ['ADMIN'], child: OrderManagementPage()),

  // ==================== STAFF ====================

  // Staff shell
  '/staff': (_) => RoleGuard(
    allowed: const ['STAFF'],
    child: Builder(
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        final claims = Claims.fromJwt(auth.token);
        final email = claims.email;
        if (email == null) {
          return const NotFoundPage(routeName: '/staff (missing email)');
        }
        return StaffHome(userId: email); // Use email as user identifier
      },
    ),
  ),

  // Staff Profile
  '/staff/profile': (_) => RoleGuard(
    allowed: const ['STAFF'],
    child: Builder(
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        final claims = Claims.fromJwt(auth.token);
        final email = claims.email;
        if (email == null) {
          return const NotFoundPage(
            routeName: '/staff/profile (missing email)',
          );
        }
        // Staff profile should also use ProfilePage which calls /api/auth/me
        return const ProfilePage();
      },
    ),
  ),

  // Staff Foods
  '/staff/foods': (_) =>
      const RoleGuard(allowed: ['STAFF'], child: StaffFoodListPage()),

  // Staff Tables
  '/staff/tables': (_) =>
      const RoleGuard(allowed: ['STAFF'], child: StaffTableListPage()),

  // Staff Orders
  '/staff/orders': (_) =>
      const RoleGuard(allowed: ['STAFF'], child: StaffOrderListPage()),
};

// ==================== DYNAMIC ROUTES (need arguments) ====================
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  debugPrint('onGenerateRoute called with: ${settings.name}');

  // Skip if route is defined in static routes
  if (appRoutes.containsKey(settings.name)) {
    return null;
  }

  // Handle dynamic routes that require arguments
  final arguments = settings.arguments;

  switch (settings.name) {
    case '/admin/users/detail':
      final userId = arguments as String?;
      if (userId == null || userId.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const NotFoundPage(routeName: 'User detail - missing ID'),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => RoleGuard(
          allowed: const ['ADMIN'],
          child: UserDetailPage(userId: userId),
        ),
      );

    case '/admin/users/edit':
      final userId = arguments as String?;
      if (userId == null || userId.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const NotFoundPage(routeName: 'User edit - missing ID'),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (ctx) => RoleGuard(
          allowed: const ['ADMIN'],
          child: Builder(
            builder: (ctx) {
              final service = ctx.read<UserService>();
              return FutureBuilder<UserModel>(
                future: service.getUserById(userId),
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

    case '/admin/foods/detail':
      final foodId = arguments as String?;
      if (foodId == null || foodId.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const NotFoundPage(routeName: 'Food detail - missing ID'),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => RoleGuard(
          allowed: const ['ADMIN'],
          child: FoodDetailPage(foodId: foodId),
        ),
      );

    case '/admin/tables/detail':
      final tableId = arguments as String?;
      if (tableId == null || tableId.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const NotFoundPage(routeName: 'Table detail - missing ID'),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => RoleGuard(
          allowed: const ['ADMIN'],
          child: TableDetailPage(tableId: tableId),
        ),
      );

    case '/admin/orders/detail':
      final orderId = arguments as String?;
      if (orderId == null || orderId.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const NotFoundPage(routeName: 'Order detail - missing ID'),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => RoleGuard(
          allowed: const ['ADMIN'],
          child: OrderDetailPage(orderId: orderId),
        ),
      );
  }

  return null;
}

// ==================== UNKNOWN ROUTE (safety net) ====================
Route<dynamic> onUnknownRoute(RouteSettings settings) => MaterialPageRoute(
  settings: settings,
  builder: (_) => NotFoundPage(routeName: settings.name),
);
