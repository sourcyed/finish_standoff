import 'dart:async';
import 'package:finish_standoff/data/models/match_model.dart';
import 'package:finish_standoff/data/models/player_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../bloc/match/match_bloc.dart';
import '../bloc/match/match_state.dart';
import '../bloc/match/match_event.dart';
import '../bloc/preparation/preparation_bloc.dart';
import '../bloc/preparation/preparation_event.dart';
import '../bloc/preparation/preparation_state.dart';
import '../data/player_id.dart';

class DuelScreen extends StatefulWidget {
  final String matchId;
  final String myId;

  const DuelScreen({super.key, required this.matchId, required this.myId});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  bool hasVibratedSignal = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listener: (context, state) async {
        if (state is MatchLoaded) {
          if (state.match.state == 'result') {
            final win = state.match.winnerId == widget.myId;
            final match = state.match;
            final myId = await PlayerIdService.getPlayerId();
            if (!win && await Vibration.hasVibrator()) {
              Vibration.vibrate(duration: 400);
            }

            final Map<String, String> params = {
              'win': win.toString(),
              'opponentName':
                  match.players.firstWhere((p) => p.id != myId).name,
            };

            context.go(
              Uri(path: '/result', queryParameters: params).toString(),
            );
          } else if (!hasVibratedSignal &&
              state.match.canShoot == true &&
              await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 100);
            hasVibratedSignal = true;
          }
        }
      },
      child: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MatchError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is MatchLoaded) {
            final match = state.match;
            switch (match.state) {
              case 'waiting':
                return WaitingPhase(
                  players: match.players,
                  matchId: widget.matchId,
                );
              case 'preparing':
                return PreparationPhase(
                  matchId: widget.matchId,
                  myId: widget.myId,
                );
              case 'duel':
              case 'result':
                return DuelPhase(match: match);
              default:
                return const Center(child: Text("Unknown phase"));
            }
          }
          return const SizedBox();
        },
      ),
    );
  }
}

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

class PreparationPhase extends StatefulWidget {
  final String matchId;
  final String myId;

  const PreparationPhase({
    super.key,
    required this.matchId,
    required this.myId,
  });

  @override
  State<PreparationPhase> createState() => _PreparationPhaseState();
}

class _PreparationPhaseState extends State<PreparationPhase> {
  StreamSubscription? _sensorSub;
  String? _lastSent;

  @override
  void initState() {
    super.initState();
    _sensorSub = accelerometerEventStream().listen((event) {
      final holstered = event.x.abs() < 3 && event.y < -7 && event.z.abs() < 3;
      context.read<PreparationBloc>().add(PrepSensorTick(holstered));
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreparationBloc, PreparationState>(
      listener: (context, state) {
        if (state is PrepComplete && _lastSent != 'complete') {
          _lastSent = 'complete';
          context.read<MatchBloc>().add(
            MatchPlayerPrepared(widget.matchId, widget.myId, true),
          );
        }
        if (state is PrepInterrupted && _lastSent != 'interrupted') {
          _lastSent = 'interrupted';
          context.read<MatchBloc>().add(
            MatchPlayerPrepared(widget.matchId, widget.myId, false),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Preparation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Place phone down (like you would into your pocket)'),
              const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed:
              //       () => context.read<PreparationBloc>().add(PrepSkip()),
              //   child: const Text('Instant Ready'),
              // ),
              const SizedBox(height: 20),
              BlocBuilder<PreparationBloc, PreparationState>(
                builder: (context, state) {
                  if (state is PrepIdle || state is PrepInterrupted) {
                    return const Text('Waiting...');
                  }
                  if (state is PrepCounting) {
                    return Column(
                      children: [
                        LinearProgressIndicator(value: state.progress),
                        const SizedBox(height: 8),
                        Text('${(state.progress * 100).toInt()}%'),
                      ],
                    );
                  }
                  if (state is PrepComplete) {
                    return const Text('Ready!');
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 20),
              const Text('Do not lift your phone until your phone vibrates'),
            ],
          ),
        ),
      ),
    );
  }
}

class DuelPhase extends StatefulWidget {
  final MatchModel match;

  const DuelPhase({super.key, required this.match});

  @override
  State<DuelPhase> createState() => _DuelPhaseState();
}

class _DuelPhaseState extends State<DuelPhase> {
  StreamSubscription? _sensorSub;
  bool _hasDrawn = false;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _loadPlayerId();
    _sensorSub = accelerometerEventStream().listen(_onSensorEvent);
  }

  Future<void> _loadPlayerId() async {
    final id = await PlayerIdService.getPlayerId();
    setState(() => _myId = id);
  }

  void _onSensorEvent(AccelerometerEvent event) {
    if (_hasDrawn) return;
    if (event.x.abs() > 7 && event.y.abs() < 3 && event.z.abs() < 3) {
      _hasDrawn = true;
      context.read<MatchBloc>().add(MatchShoot(widget.match.matchId, _myId!));
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duel")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              !widget.match.canShoot
                  ? "Wait for signal"
                  : _hasDrawn
                  ? "You fired"
                  : "Draw",
            ),
            const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     if (_hasDrawn) return;
            //     _hasDrawn = true;
            //     context.read<MatchBloc>().add(
            //       MatchShoot(widget.match.matchId, _myId!),
            //     );
            //   },
            //   child: const Text('Shoot'),
            // ),
          ],
        ),
      ),
    );
  }
}
