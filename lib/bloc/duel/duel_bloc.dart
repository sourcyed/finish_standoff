import 'package:flutter_bloc/flutter_bloc.dart';
import 'duel_event.dart';
import 'duel_state.dart';
import '../../data/match_api.dart';
import '../../data/player_id.dart';

class DuelBloc extends Bloc<DuelEvent, DuelState> {
  final MatchApi api;

  DuelBloc({required this.api}) : super(DuelInitial()) {
    on<DuelStart>(_onStart);
    on<DuelShoot>(_onShoot);
  }

  Future<void> _onStart(DuelStart event, Emitter<DuelState> emit) async {
    if (event.shootDelay > 0) {
      await Future.delayed(Duration(milliseconds: event.shootDelay));
      emit(DuelCanShoot());
    }
  }

  Future<void> _onShoot(DuelShoot event, Emitter<DuelState> emit) async {
    final playerId = await PlayerIdService.getPlayerId();

    await api.readyPlayer(event.matchId, playerId, true);

    emit(DuelShot());
  }
}
