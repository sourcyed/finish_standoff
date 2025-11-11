import 'package:finish_standoff/screens/duel_phases/duel_phase.dart';
import 'package:finish_standoff/screens/duel_phases/preparation_phase.dart';
import 'package:finish_standoff/screens/duel_phases/waiting_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../bloc/match/match_bloc.dart';
import '../bloc/match/match_state.dart';
import '../data/player_id.dart';

class DuelScreen extends StatefulWidget {
  final String matchId;
  final String myId;

  const DuelScreen({super.key, required this.matchId, required this.myId});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  bool hasVibratedSignal = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listener: (context, state) async {
        if (state is MatchLoaded) {
          if (state.match.state == 'result') {
            final win = state.match.winnerId == widget.myId;
            final match = state.match;
            final myId = await PlayerIdService.getPlayerId();
            if (!win && await Vibration.hasVibrator()) {
              Vibration.vibrate(duration: 400);
            }

            final Map<String, String> params = {
              'win': win.toString(),
              'opponentName':
                  match.players.firstWhere((p) => p.id != myId).name,
            };
            if (context.mounted) {
              context.go(
                Uri(path: '/result', queryParameters: params).toString(),
              );
            }
          } else if (!hasVibratedSignal &&
              state.match.canShoot == true &&
              await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 100);
            hasVibratedSignal = true;
          }
        }
      },
      child: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MatchError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is MatchLoaded) {
            final match = state.match;
            switch (match.state) {
              case 'waiting':
                return WaitingPhase(
                  players: match.players,
                  matchId: widget.matchId,
                );
              case 'preparing':
                return PreparationPhase(
                  matchId: widget.matchId,
                  myId: widget.myId,
                );
              case 'duel':
              case 'result':
                return DuelPhase(match: match);
              default:
                return const Center(child: Text("Unknown phase"));
            }
          }
          return const SizedBox();
        },
      ),
    );
  }
}
