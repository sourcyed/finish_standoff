import 'package:finish_standoff/bloc/match_finder/match_finder_bloc.dart';
import 'package:finish_standoff/bloc/match_finder/match_finder_event.dart';
import 'package:finish_standoff/bloc/match_finder/match_finder_state.dart';
import 'package:finish_standoff/data/match_api.dart';
import 'package:finish_standoff/data/player_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MatchFinderBloc(api: MatchApi()),
      child: BlocListener<MatchFinderBloc, MatchFinderState>(
        listener: (context, state) {
          if (state is MatchFound) {
            context.push('/duel/${state.matchId}');
          }
        },
        child: _LobbyView(),
      ),
    );
  }
}

class _LobbyView extends StatefulWidget {
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
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.displayMedium!;

    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text('Finish Standoff', style: textStyle),
                BlocBuilder<MatchFinderBloc, MatchFinderState>(
                  builder: (context, state) {
                    if (state is MatchFinderLoading) {
                      return const CircularProgressIndicator();
                    }

                    return Column(
                      children: [
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                            border: InputBorder.none,
                            hintTextDirection: TextDirection.ltr,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final playerId =
                                await PlayerIdService.getPlayerId();

                            if (context.mounted) {
                              context.read<MatchFinderBloc>().add(
                                FindOpponentPressed(
                                  playerName:
                                      _controller.text == ''
                                          ? playerId.substring(0, 6)
                                          : _controller.text,
                                  playerId: playerId,
                                ),
                              );
                            }
                          },
                          child: Text('Find opponent'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
