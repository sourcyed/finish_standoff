import 'package:finish_standoff/data/models/match_model.dart';

sealed class MatchEvent {}

class MatchStartListening extends MatchEvent {
  final String matchId;
  MatchStartListening(this.matchId);
}

class MatchUpdated extends MatchEvent {
  final MatchModel match;
  MatchUpdated(this.match);
}

class MatchReadyPlayer extends MatchEvent {
  final String matchId;
  final String playerId;
  MatchReadyPlayer(this.matchId, this.playerId);
}
