import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/scaffold_with_navbar.dart';
import '../pages/home_page.dart';
import '../pages/calendar_page.dart'; // Corrected import

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) { // Corrected: Use Capitalized Class Name 'ScaffoldWithNavBar'
        return ScaffoldWithNavBar(child: child); // Corrected: Use Capitalized Class Name 'ScaffoldWithNavBar'
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
        ),
      ],
    ),
  ],
);