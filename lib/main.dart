import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/auths/navigator_observer.dart';
import 'package:fpt_final_project_mobile/auths/not_found_page.dart';
import 'package:fpt_final_project_mobile/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      initialRoute: '/',
      routes: appRoutes,
      onUnknownRoute: (settings) {
        debugPrint('🚨 Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => NotFoundPage(routeName: settings.name),
        );
      },

      // (tuỳ chọn) Quan sát navigation để debug
      navigatorObservers: [LogObserver()],
    );
  }
}
