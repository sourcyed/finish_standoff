import 'package:finish_standoff/screens/credits_screen.dart';
import 'package:finish_standoff/screens/duel_screen.dart';
import 'package:finish_standoff/screens/main_screen.dart';
import 'package:finish_standoff/screens/result_creen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MainApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return Scaffold(body: child, backgroundColor: Colors.black);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const MainScreen(),
              transitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurveTween(
                    curve: Curves.easeInOut,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/duel',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const DuelScreen(),
              transitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurveTween(
                    curve: Curves.easeInOut,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/result',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ResultScreen(),
              transitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurveTween(
                    curve: Curves.easeInOut,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/credits',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const CreditsScreen(),
              transitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurveTween(
                    curve: Curves.easeInOut,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
