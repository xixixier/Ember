import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/throw_in/throw_in_screen.dart';
import '../../features/transform/collection_screen.dart';
import '../../features/destroy/screens/to_destroy_screen.dart';
import '../../features/review/screens/calendar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/theme_screen.dart';
import '../../features/settings/screens/reminder_screen.dart';
import 'ember_navigation_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/throw',
    navigatorKey: _rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/throw',
              pageBuilder: (context, state) => _fadeSlide(
                const ThrowInScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/collection',
              pageBuilder: (context, state) => _fadeSlide(
                const CollectionScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/to-destroy',
              pageBuilder: (context, state) => _fadeSlide(
                const ToDestroyScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/review',
              pageBuilder: (context, state) => _fadeSlide(
                const CalendarScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => _fadeSlide(
                const SettingsScreen(),
                state,
              ),
            ),
          ]),
        ],
      ),
      // 全屏路由（淡入淡出，无位移）
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeOnly(
          const PrivacyPolicyScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/theme',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeOnly(
          const ThemeScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/reminder',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeOnly(
          const ReminderScreen(),
          state,
        ),
      ),
    ],
  );

  /// Tab 切换：淡入淡出 + 轻微向上位移 (offset 0.02)
  static Page<void> _fadeSlide(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// 全屏路由：纯淡入淡出
  static Page<void> _fadeOnly(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: EmberNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
