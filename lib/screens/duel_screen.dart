import 'package:finish_standoff/bloc/match/match_bloc.dart';
import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:finish_standoff/bloc/match/match_state.dart';
import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class DuelScreen extends StatelessWidget {
  final String matchId;

  const DuelScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => MatchBloc(api: MatchApi())..add(MatchStartListening(matchId)),
      child: Scaffold(
        appBar: AppBar(title: Text("Duel $matchId")),
        body: FutureBuilder<String>(
          future: PlayerIdService.getPlayerId(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final myId = snapshot.data!;

            return BlocBuilder<MatchBloc, MatchState>(
              builder: (context, state) {
                if (state is MatchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MatchError) {
                  return Center(child: Text("Error: ${state.message}"));
                }

                if (state is MatchLoaded) {
                  final myPlayer = state.match.players[myId];
                  final iAmReady = myPlayer?["ready"] == true;

                  final entries = state.match.players.entries;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children:
                              entries.map((entry) {
                                final playerId = entry.key;
                                final data = entry.value;
                                final isMe = playerId == myId;

                                final displayName =
                                    isMe
                                        ? "${data["name"]} (You)"
                                        : data["name"];

                                return ListTile(
                                  title: Text(displayName),
                                  subtitle: Text("Ready: ${data["ready"]}"),
                                );
                              }).toList(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            () =>
                                !iAmReady
                                    ? context.read<MatchBloc>().add(
                                      MatchReadyPlayer(matchId, myId),
                                    )
                                    : null,
                        child: Text('Ready'),
                      ),
                    ],
                  );
                }

                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
  }
}
