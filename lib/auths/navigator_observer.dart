import 'package:flutter/material.dart';

class LogObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('➡️ push: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint('🔁 replace: ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint('🗑 remove: ${route.settings.name}');
  }
}
