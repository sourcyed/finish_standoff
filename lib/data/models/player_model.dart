class PlayerModel {
  final String id;
  final String name;
  final bool ready;
  final int reactionTimeMs;

  PlayerModel({
    required this.id,
    required this.name,
    required this.ready,
    required this.reactionTimeMs,
  });

  factory PlayerModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return PlayerModel(
      id: id,
      name: data['name'] ?? '',
      ready: data['ready'] ?? false,
      reactionTimeMs: data['reactionTimeMs'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'ready': ready, 'reactionTimeMs': reactionTimeMs};
  }
}
