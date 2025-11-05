sealed class MatchFinderState {}

class MatchFinderInitial extends MatchFinderState {}

class MatchFinderLoading extends MatchFinderState {}

class MatchFound extends MatchFinderState {
  final String matchId;
  MatchFound(this.matchId);
}

class MatchFinderError extends MatchFinderState {
  final String message;
  MatchFinderError(this.message);
}
