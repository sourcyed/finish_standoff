class PlayerModel {
  final String id;
  final String name;
  final bool ready;

  PlayerModel({required this.id, required this.name, required this.ready});

  factory PlayerModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return PlayerModel(
      id: id,
      name: data['name'] ?? '',
      ready: data['ready'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'ready': ready};
  }
}
