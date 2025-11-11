import 'package:finish_standoff/bloc/match/match_bloc.dart';
import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:finish_standoff/bloc/match_finder/match_finder_bloc.dart';
import 'package:finish_standoff/bloc/preparation/preparation_bloc.dart';
import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:finish_standoff/screens/credits_screen.dart';
import 'package:finish_standoff/screens/duel_screen.dart';
import 'package:finish_standoff/screens/lobby_screen.dart';
import 'package:finish_standoff/screens/main_screen.dart';
import 'package:finish_standoff/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          path: '/lobby',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) => MatchFinderBloc(api: MatchApi()),
                child: const LobbyScreen(),
              ),
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
          path: '/duel/:matchId',
          pageBuilder: (BuildContext context, GoRouterState state) {
            final matchId = state.pathParameters['matchId']!;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: FutureBuilder(
                future: PlayerIdService.getPlayerId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final myId = snapshot.data!;

                  // Provide blocs here
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create:
                            (_) =>
                                MatchBloc(api: MatchApi())
                                  ..add(MatchStartListening(matchId)),
                      ),
                      BlocProvider(create: (_) => PreparationBloc()),
                    ],
                    child: DuelScreen(matchId: matchId, myId: myId),
                  );
                },
              ),
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
          pageBuilder: (_, state) {
            final win = state.uri.queryParameters['win'] == 'true';
            final opponentName =
                state.uri.queryParameters['opponentName'] ?? '';
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: ResultScreen(win: win, opponentName: opponentName),
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
