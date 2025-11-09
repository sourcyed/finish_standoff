import 'package:finish_standoff/data/models/player_model.dart';

class MatchModel {
  final String matchId;
  final String ownerId;
  final String state;
  final int shootDelay;
  final List<PlayerModel> players;

  MatchModel({
    required this.matchId,
    required this.ownerId,
    required this.state,
    required this.shootDelay,
    required this.players,
  });

  factory MatchModel.fromMap(String id, Map<dynamic, dynamic> data) {
    final playersRaw = data['players'] as Map<dynamic, dynamic>? ?? {};

    final players =
        playersRaw.entries
            .map((entry) => PlayerModel.fromMap(entry.key, entry.value))
            .toList();

    return MatchModel(
      matchId: id,
      ownerId: data['ownerId'],
      state: data['state'],
      shootDelay: data['shootDelay'],
      players: players,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'state': state,
      'shootDelay': shootDelay,
      'players': {for (final p in players) p.id: p.toMap()},
    };
  }
}
