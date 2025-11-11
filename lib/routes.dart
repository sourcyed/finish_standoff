import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'data/match_api.dart';
import 'data/player_id.dart';
import 'screens/main_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/duel_screen.dart';
import 'screens/result_screen.dart';
import 'screens/credits_screen.dart';
import 'bloc/match/match_bloc.dart';
import 'bloc/match/match_event.dart';
import 'bloc/match_finder/match_finder_bloc.dart';
import 'bloc/preparation/preparation_bloc.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder:
          (context, state, child) =>
              Scaffold(body: child, backgroundColor: Colors.black),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder:
              (context, state) =>
                  _fadePage(child: const MainScreen(), state: state),
        ),
        GoRoute(
          path: '/lobby',
          pageBuilder:
              (context, state) => _fadePage(
                child: BlocProvider(
                  create: (_) => MatchFinderBloc(api: MatchApi()),
                  child: const LobbyScreen(),
                ),
                state: state,
              ),
        ),
        GoRoute(
          path: '/duel/:matchId',
          pageBuilder: (context, state) {
            final matchId = state.pathParameters['matchId']!;
            return _fadePage(
              child: FutureBuilder(
                future: PlayerIdService.getPlayerId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final myId = snapshot.data!;
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
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/result',
          pageBuilder: (_, state) {
            final win = state.uri.queryParameters['win'] == 'true';
            final opponentName =
                state.uri.queryParameters['opponentName'] ?? '';
            return _fadePage(
              child: ResultScreen(win: win, opponentName: opponentName),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/credits',
          pageBuilder:
              (context, state) =>
                  _fadePage(child: const CreditsScreen(), state: state),
        ),
      ],
    ),
  ],
);

CustomTransitionPage _fadePage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
