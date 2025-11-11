import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/match/match_bloc.dart';
import '../../data/models/player_model.dart';
import '../../data/player_id.dart';

class WaitingPhase extends StatefulWidget {
  final List<PlayerModel> players;
  final String matchId;

  const WaitingPhase({super.key, required this.players, required this.matchId});

  @override
  State<WaitingPhase> createState() => _WaitingPhaseState();
}

class _WaitingPhaseState extends State<WaitingPhase> {
  String? _myId;

  @override
  void initState() {
    super.initState();
    _loadPlayerId();
  }

  Future<void> _loadPlayerId() async {
    final id = await PlayerIdService.getPlayerId();
    setState(() => _myId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (_myId == null) return const Center(child: CircularProgressIndicator());

    final players = widget.players;

    return Scaffold(
      appBar: AppBar(title: const Text("Waiting")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text('Waiting for players...'),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children:
                  players.map((player) {
                    final isMe = player.id == _myId;
                    final displayName =
                        isMe ? "${player.name} (You)" : player.name;
                    final ready = player.ready == true;
                    return ListTile(
                      title: Text(displayName),
                      subtitle: Text("Ready: $ready"),
                    );
                  }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final player = players.firstWhere((p) => p.id == _myId!);
              if (!player.ready) {
                context.read<MatchBloc>().add(
                  MatchReadyPlayer(widget.matchId, _myId!),
                );
              }
            },
            child: const Text('Ready'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
