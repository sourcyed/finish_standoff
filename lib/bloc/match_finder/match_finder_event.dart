sealed class MatchFinderEvent {}

class FindOpponentPressed extends MatchFinderEvent {
  final String playerName;
  final String playerId;

  FindOpponentPressed({required this.playerName, required this.playerId});
}
