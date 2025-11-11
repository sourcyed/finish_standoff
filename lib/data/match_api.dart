import 'package:finish_standoff/data/models/match_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class MatchApi {
  final _db = FirebaseDatabase.instance.ref();
  final _uuid = const Uuid();

  Future<String> createMatch(String ownerId, String playerName) async {
    String matchId = _uuid.v4().substring(0, 8);
    await _db.child("matches/$matchId").set({
      "ownerId": ownerId,
      "winnerId": '',
      "state": "waiting",
      "players": {
        ownerId: {"name": playerName, "ready": false},
      },
      "createdAt": ServerValue.timestamp,
      "canShoot": false,
    });

    return matchId;
  }

  Future<void> joinMatch(
    String matchId,
    String playerId,
    String playerName,
  ) async {
    final playerRef = _db.child("matches/$matchId/players/$playerId");

    playerRef.onDisconnect().remove();

    await playerRef.set({"name": playerName, "ready": false});

    // Remove match if the user leaves as the last player in the lobby
    _db.child("matches/$matchId/players").onValue.listen((event) {
      final players = event.snapshot.value as Map?;
      if (players == null || players.isEmpty) {
        removeMatch(matchId);
      }
    });
  }

  Future<void> removeMatch(String matchId) {
    return _db.child("matches/$matchId").remove();
  }

  Future<void> readyPlayer(String matchId, String playerId, bool ready) {
    return _db.child("matches/$matchId/players/$playerId/ready").set(ready);
  }

  Future<void> removePlayer(String matchId, String playerId) async {
    final matchSnapshot = await _db.child("matches/$matchId").get();

    if (matchSnapshot.exists) {
      final match = MatchModel.fromMap(
        matchId,
        matchSnapshot.value as Map<dynamic, dynamic>,
      );
      if (match.ownerId == playerId) {
        removeMatch(matchId);
      } else {
        await _db.child("matches/$matchId/players/$playerId").remove();
        if (match.state != 'result') {
          setState(matchId, 'waiting');
        }
      }
    }
  }

  Stream<MatchModel?> listenToMatch(String matchId) {
    return _db.child("matches/$matchId").onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return null;
      }
      if (data is Map) {
        return MatchModel.fromMap(matchId, data);
      }
      return null;
    });
  }

  Future<void> setState(String matchId, String state) async {
    final snapshot = await _db.child("matches/$matchId").get();

    if (snapshot.exists) {
      final match = MatchModel.fromMap(
        snapshot.key!,
        snapshot.value as Map<dynamic, dynamic>,
      );
      final players = match.players;

      // Create a map of updates to set all players as not ready
      final Map<String, dynamic> updates = {};
      for (final key in players.map((p) => p.id)) {
        updates["$key/ready"] = false;
      }

      // Apply the updates
      await _db.child("matches/$matchId/players").update(updates);

      // Finally, set the match state
      await _db.child("matches/$matchId/state").set(state);
    }
  }

  Future<String> findOrCreateMatch(String playerId, String playerName) async {
    final snapshot =
        await _db
            .child("matches")
            .orderByChild("state")
            .equalTo("waiting")
            .get();

    if (snapshot.exists) {
      final matches = <MatchModel>[];

      for (final child in snapshot.children) {
        try {
          final match = MatchModel.fromMap(
            child.key!,
            child.value as Map<dynamic, dynamic>,
          );
          matches.add(match);
        } catch (e) {
          // Skip malformed entries
          continue;
        }
      }

      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final match in matches) {
        final players = match.players;
        final createdAt = match.createdAt;

        final ageMs = DateTime.now().millisecondsSinceEpoch - createdAt;

        // Skip inactive lobbies
        if (ageMs > 180000) {
          _db.child("matches/${match.matchId}").remove();
          continue;
        }

        // Skip empty lobbies (corrupy)
        if (players.isEmpty) {
          await _db.child("matches/${match.matchId}").remove();
          continue;
        }

        // Skip full lobbies
        if (players.length > 1) {
          await _db.child("matches/${match.matchId}").remove();
          continue;
        }

        // I am the player
        if (players.length == 1 && players.first.id == playerId) {
          await _db.child("matches/${match.matchId}").remove();
          continue;
        }

        await joinMatch(match.matchId, playerId, playerName);
        return match.matchId;
      }
    }
    return await createMatch(playerId, playerName);
  }

  Future<void> goSignal(String matchId) async {
    return _db.child("matches/$matchId/canShoot").set(true);
  }

  Future<void> finishDuel(String matchId, String playerId, bool win) async {
    final ref = _db.child("matches/$matchId");

    // get players
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final match = MatchModel.fromMap(
      matchId,
      snapshot.value as Map<dynamic, dynamic>,
    );

    final players = match.players;

    late String winnerUid;

    winnerUid = win ? playerId : players.firstWhere((p) => p.id != playerId).id;

    await ref.update({"winnerId": winnerUid});

    await setState(matchId, 'result');
  }
}
