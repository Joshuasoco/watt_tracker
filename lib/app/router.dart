import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/calculator/view/calculator_page.dart';
import '../features/history/view/history_page.dart';
import '../features/settings/view/settings_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/calculator',
    routes: <RouteBase>[
      GoRoute(
        path: '/calculator',
        name: 'calculator',
        builder: (BuildContext context, GoRouterState state) {
          return const CalculatorPage();
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (BuildContext context, GoRouterState state) {
          return const HistoryPage();
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsPage();
        },
      ),
    ],
  );
}
