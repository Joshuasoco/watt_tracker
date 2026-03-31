import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/calculator/view/calculator_page.dart';
import '../features/calculator/view/config_page.dart';
import '../features/history/view/history_page.dart';
import '../features/settings/view/settings_page.dart';
import '../shared/widgets/app_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (BuildContext context, GoRouterState state) {
                  return const CalculatorPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/config',
                name: 'config',
                builder: (BuildContext context, GoRouterState state) {
                  return const ConfigPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (BuildContext context, GoRouterState state) {
                  return const HistoryPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (BuildContext context, GoRouterState state) {
                  return const SettingsPage();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
