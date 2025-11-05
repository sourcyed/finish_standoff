import 'dart:async';

import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/models/match_model.dart';
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
          (data) {
            try {
              final match = MatchModel.fromMap(event.matchId, data);
              add(MatchUpdated(match));
            } catch (e) {
              emit(MatchError("Failed to parse match data"));
            }
          },
          onError: (error) {
            emit(MatchError(error.toString()));
          },
        );
  }

  void _onMatchUpdated(MatchUpdated event, Emitter<MatchState> emit) {
    emit(MatchLoaded(event.match));
  }

  Future<void> _onMatchReadyPlayer(
    MatchReadyPlayer event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    await api.readyPlayer(event.matchId, event.playerId);
  }

  @override
  Future<void> close() async {
    if (state is MatchLoaded) {
      final match = (state as MatchLoaded).match;
      final playerId = await PlayerIdService.getPlayerId();
      api.removePlayer(match.matchId, playerId);
    }
    _matchSub?.cancel();
    return super.close();
  }
}
