import 'dart:async';

import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:finish_standoff/bloc/match/match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchApi api;

  StreamSubscription? _matchSub;

  MatchBloc({required this.api}) : super(MatchInitial()) {
    on<MatchStartListening>(_onStartedListening);
    on<MatchUpdated>(_onMatchUpdated);
    on<MatchReadyPlayer>(_onMatchReadyPlayer);
    on<MatchPlayerPrepared>(_onMatchPlayerPrepared);
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
            add(MatchUpdated(match));
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
    emit(MatchLoaded(event.match));
    final players = event.match.players;
    final allReady = players.length == 2 && players.every((p) => p.ready);
    if (event.match.state == 'waiting' && allReady) {
      await api.setState(event.match.matchId, 'preparing');
    }
    if (event.match.state == 'preparing' && allReady) {
      await api.setState(event.match.matchId, 'duel');
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
