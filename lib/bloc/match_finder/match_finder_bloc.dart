import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/match_api.dart';
import 'match_finder_event.dart';
import 'match_finder_state.dart';

class MatchFinderBloc extends Bloc<MatchFinderEvent, MatchFinderState> {
  final MatchApi api;

  MatchFinderBloc({required this.api}) : super(MatchFinderInitial()) {
    on<FindOpponentPressed>(_onFindOpponent);
  }

  Future<void> _onFindOpponent(
    FindOpponentPressed event,
    Emitter<MatchFinderState> emit,
  ) async {
    emit(MatchFinderLoading());

    try {
      final matchId = await api.findOrCreateMatch(
        event.playerId,
        event.playerName,
      );

      emit(MatchFound(matchId));
    } catch (e) {
      emit(MatchFinderError("Failed to find opponent: $e"));
    }
  }
}
