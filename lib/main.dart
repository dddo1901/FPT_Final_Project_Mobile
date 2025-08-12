import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpt_final_project_mobile/admin/services/food_service.dart';
import 'package:fpt_final_project_mobile/middleware/token_client.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'auths/auth_provider.dart';
import 'auths/api_service.dart';
import 'routes/app_routes.dart';
import 'auths/navigator_observer.dart';

import 'admin/services/user_service.dart';
import 'admin/services/table_service.dart';

const kBaseUrl = 'http://10.0.2.2:8080';

final _navKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Auth state
        ChangeNotifierProvider(
          create: (_) => AuthProvider(const FlutterSecureStorage())..load(),
        ),

        // ApiService dùng TokenClient (middleware gắn token)
        ProxyProvider<AuthProvider, ApiService>(
          update: (ctx, auth, prev) {
            final client = TokenClient(
              inner: http.Client(),
              getAccessToken: () => auth.token, // sync getter
              shouldSkip: (uri) =>
                  uri.path == '/api/auth/login', // chỉ skip login
              onUnauthorized: () async {
                await auth.logout();
                _navKey.currentState?.pushNamedAndRemoveUntil(
                  '/',
                  (_) => false,
                );
              },
            );
            return ApiService(baseUrl: kBaseUrl, client: client);
          },
        ),

        // UserService & TableService reuse client từ ApiService
        ProxyProvider<ApiService, UserService>(
          update: (ctx, api, prev) =>
              UserService(baseUrl: kBaseUrl, client: api.client),
        ),
        ProxyProvider<ApiService, TableService>(
          update: (ctx, api, prev) =>
              TableService(baseUrl: kBaseUrl, client: api.client),
        ),
        ProxyProvider<ApiService, FoodService>(
          update: (_, api, __) =>
              FoodService(baseUrl: kBaseUrl, client: api.client),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      initialRoute: '/', // '/' -> Login
      routes: appRoutes, // từ app_routes.dart
      onGenerateRoute: onGenerateRoute, // routes có arguments
      onUnknownRoute: onUnknownRoute, // 404 fallback
      navigatorObservers: [LogObserver()],
    );
  }
}
