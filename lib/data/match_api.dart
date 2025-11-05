import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class MatchApi {
  final _db = FirebaseDatabase.instance.ref();
  final _uuid = const Uuid();

  Future<String> createMatch(String ownerId, String playerName) async {
    String matchId = _uuid.v4().substring(0, 4);
    print("Creating match...");
    await _db.child("matches/$matchId").set({
      "ownerId": ownerId,
      "state": "waiting",
      "players": {
        ownerId: {"name": playerName, "ready": false},
      },
      "createdAt": ServerValue.timestamp,
    });

    print("Created match $matchId");

    return matchId;
  }

  Future<void> joinMatch(
    String matchId,
    String playerId,
    String playerName,
  ) async {
    print("Joining match $matchId");
    final playerRef = _db.child("matches/$matchId/players/$playerId");

    playerRef.onDisconnect().remove();

    await playerRef.set({"name": playerName, "ready": false});
    print("Set player $playerId for match $matchId");

    print("Joined match");

    // Remove match if the user leaves as the last player in the lobby
    _db.child("matches/$matchId/players").onValue.listen((event) {
      final players = event.snapshot.value as Map?;
      if (players == null || players.isEmpty) {
        _db.child("matches/$matchId").remove();
      }
    });
  }

  Future<void> readyPlayer(String matchId, String playerId) {
    return _db.child("matches/$matchId/players/$playerId/ready").set(true);
  }

  Future<void> removePlayer(String matchId, String playerId) {
    return _db.child("matches/$matchId/players/$playerId").remove();
  }

  Stream<Map<dynamic, dynamic>> listenToMatch(String matchId) {
    return _db.child("matches/$matchId").onValue.map((event) {
      return event.snapshot.value as Map<dynamic, dynamic>;
    });
  }

  Future<String> findOrCreateMatch(String userId, String playerName) async {
    final snapshot =
        await _db
            .child("matches")
            .orderByChild("state")
            .equalTo("waiting")
            .limitToFirst(5)
            .get();

    print("Found ${snapshot.children.length} lobbies:");
    for (var child in snapshot.children) {
      print(child.value);
    }

    print("Snapshot exists: ${snapshot.exists}");

    if (snapshot.exists) {
      for (final child in snapshot.children) {
        final data = child.value as Map;
        final createdAt = (data["createdAt"] ?? 0) as int;

        final ageMs = DateTime.now().millisecondsSinceEpoch - createdAt;

        // Skip inactive lobbies
        if (ageMs > 60000) {
          _db.child("matches/${child.key}").remove();
          print("${child.key} is inactive");
          continue;
        }

        // Skip empty lobbies (corrupy)
        if ((data["players"] as Map).isEmpty) {
          print("${child.key} is corrupt");
          _db.child("matches/${child.key}").remove();
          continue;
        }
        print("Gonna join match");
        await joinMatch(child.key!, userId, playerName);
        return child.key!;
      }
    }

    return await createMatch(userId, playerName);
  }
}
