import 'dart:async';
import 'dart:math';

import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:finish_standoff/bloc/match/match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchApi api;

  StreamSubscription? _matchSub;
  bool _delayScheduled = false; // prevents scheduling GO! twice

  MatchBloc({required this.api}) : super(MatchInitial()) {
    on<MatchStartListening>(_onStartedListening);
    on<MatchUpdated>(_onMatchUpdated);
    on<MatchReadyPlayer>(_onMatchReadyPlayer);
    on<MatchPlayerPrepared>(_onMatchPlayerPrepared);
    on<MatchShoot>(_onShoot);
    on<MatchUpdatedError>((event, emit) async {
      emit(MatchError(event.message));
    });
  }

  void _onStartedListening(
    MatchStartListening event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    await _matchSub?.cancel();

    _matchSub = api
        .listenToMatch(event.matchId)
        .listen(
          (match) {
            if (match != null) {
              add(MatchUpdated(match));
            }
          },
          onError: (error) {
            add(MatchUpdatedError(error.toString()));
          },
        );
  }

  Future<void> _onMatchUpdated(
    MatchUpdated event,
    Emitter<MatchState> emit,
  ) async {
    final match = event.match;
    emit(MatchLoaded(match));
    final players = match.players;
    final allReady = players.length == 2 && players.every((p) => p.ready);
    if (match.state == 'waiting' && allReady) {
      await api.setState(match.matchId, 'preparing');
    }
    if (match.state == 'preparing' && allReady) {
      await api.setState(match.matchId, 'duel');
    }
    if (match.state == 'duel' && !_delayScheduled) {
      final myId = await PlayerIdService.getPlayerId();

      if (myId == match.ownerId) {
        _delayScheduled = true;

        final randomDelay = 3000 + Random().nextInt(7000);

        Future.delayed(Duration(milliseconds: randomDelay), () async {
          await api.goSignal(match.matchId);
        });
      }
    }
  }

  Future<void> _onMatchReadyPlayer(
    MatchReadyPlayer event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    await api.readyPlayer(event.matchId, event.playerId, true);
  }

  Future<void> _onMatchPlayerPrepared(
    MatchPlayerPrepared event,
    Emitter<MatchState> emit,
  ) async {
    await api.readyPlayer(event.matchId, event.playerId, event.prepared);
  }

  Future<void> _onShoot(MatchShoot event, Emitter<MatchState> emit) async {
    final match = state is MatchLoaded ? (state as MatchLoaded).match : null;
    if (match == null) return;

    final bool win = match.canShoot;

    await api.finishDuel(event.matchId, event.playerId, win);
  }

  @override
  Future<void> close() async {
    if (state is MatchLoaded) {
      final match = (state as MatchLoaded).match;
      final playerId = await PlayerIdService.getPlayerId();
      api.removePlayer(match.matchId, playerId);
      print('Removing player...');
    }
    _matchSub?.cancel();
    return super.close();
  }
}
