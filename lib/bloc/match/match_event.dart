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

class MatchSensorTick extends MatchEvent {
  final bool condition;
  MatchSensorTick(this.condition);
}

class MatchPlayerPrepared extends MatchEvent {
  final String matchId;
  final String playerId;
  final bool prepared;
  MatchPlayerPrepared(this.matchId, this.playerId, this.prepared);
}

class MatchUpdatedError extends MatchEvent {
  final String message;
  MatchUpdatedError(this.message);
}
