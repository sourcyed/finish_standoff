class MatchModel {
  final String matchId;
  final String ownerId;
  final String state; // waiting, countdown, active, finished
  final int shootDelay;
  final Map<String, dynamic> players;

  MatchModel({
    required this.matchId,
    required this.ownerId,
    required this.state,
    required this.shootDelay,
    required this.players,
  });

  factory MatchModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return MatchModel(
      matchId: id,
      ownerId: data['ownerId'],
      state: data['state'],
      shootDelay: data['shootDelay'],
      players: Map<String, dynamic>.from(data['players'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'state': state,
      'shootDelay': shootDelay,
      'players': players,
    };
  }
}
