import 'package:finish_standoff/bloc/match_finder/match_finder_bloc.dart';
import 'package:finish_standoff/bloc/match_finder/match_finder_event.dart';
import 'package:finish_standoff/bloc/match_finder/match_finder_state.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchFinderBloc, MatchFinderState>(
      listener: (context, state) {
        if (state is MatchFound) {
          context.push('/duel/${state.matchId}');
        }
      },
      child: const _LobbyView(),
    );
  }
}

class _LobbyView extends StatefulWidget {
  const _LobbyView();

  @override
  State<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<_LobbyView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Finish Standoff'),
              const SizedBox(height: 20),
              BlocBuilder<MatchFinderBloc, MatchFinderState>(
                builder: (context, state) {
                  if (state is MatchFinderLoading) {
                    return const CircularProgressIndicator();
                  }

                  return Column(
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Enter name",
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final playerId = await PlayerIdService.getPlayerId();
                          if (context.mounted) {
                            context.read<MatchFinderBloc>().add(
                              FindOpponentPressed(
                                playerName:
                                    _controller.text.isEmpty
                                        ? playerId.substring(0, 6)
                                        : _controller.text,
                                playerId: playerId,
                              ),
                            );
                          }
                        },
                        child: const Text('Find Opponent'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
