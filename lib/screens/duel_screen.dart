import 'dart:async';
import 'dart:math';
import 'package:finish_standoff/bloc/duel/duel_bloc.dart';
import 'package:finish_standoff/bloc/duel/duel_event.dart';
import 'package:finish_standoff/bloc/duel/duel_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../bloc/match/match_bloc.dart';
import '../bloc/match/match_state.dart';
import '../bloc/match/match_event.dart';
import '../bloc/preparation/preparation_bloc.dart';
import '../bloc/preparation/preparation_event.dart';
import '../bloc/preparation/preparation_state.dart';
import '../data/player_id.dart';

class DuelScreen extends StatelessWidget {
  final String matchId;
  final String myId;

  const DuelScreen({super.key, required this.matchId, required this.myId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
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
                entries: match.players.entries,
                matchId: matchId,
              );
            case 'preparing':
              return PreparationPhase(matchId: matchId, myId: myId);
            case 'duel':
              return BlocBuilder<MatchBloc, MatchState>(
                builder: (context, state) {
                  if (state is MatchLoaded) {
                    final match = state.match;
                    final shootDelay = match.shootDelay; // in ms

                    return BlocProvider(
                      create:
                          (_) =>
                              DuelBloc(api: context.read<MatchBloc>().api)
                                ..add(DuelStart(shootDelay)),
                      child: DuelPhase(matchId: match.matchId),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            // case 'result':
            //   return const ResultPhasePlaceholder();
            default:
              return const Center(child: Text("Unknown phase"));
          }
        }
        return const SizedBox();
      },
    );
  }
}

class WaitingPhase extends StatefulWidget {
  final Iterable<MapEntry<String, dynamic>> entries;
  final String matchId;

  const WaitingPhase({super.key, required this.entries, required this.matchId});

  @override
  State<WaitingPhase> createState() => _WaitingPhaseState();
}

class _WaitingPhaseState extends State<WaitingPhase>
    with TickerProviderStateMixin {
  String? _myId;
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_EmojiParticle> _emojis = List.generate(
    25,
    (_) => _EmojiParticle.random(),
  );

  @override
  void initState() {
    super.initState();
    _loadPlayerId();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadPlayerId() async {
    final id = await PlayerIdService.getPlayerId();
    setState(() => _myId = id);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_myId == null) return const Center(child: CircularProgressIndicator());

    final entries = widget.entries;

    return Scaffold(
      appBar: AppBar(title: const Text("Waiting for players")),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _EmojiPainter(_emojis, _controller.value),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎯 Waiting for players...',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  shadows: [
                    Shadow(
                      color: Colors.yellow,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                    Shadow(
                      color: Colors.pinkAccent,
                      blurRadius: 10,
                      offset: Offset(-2, -2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children:
                      entries.map((entry) {
                        final playerId = entry.key;
                        final data = entry.value;
                        final isMe = playerId == _myId;
                        final displayName =
                            isMe ? "${data["name"]} (You)" : data["name"];
                        final ready = data["ready"] == true;
                        return ListTile(
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text("Ready: $ready"),
                          trailing: Text(
                            ready ? '✅' : '❌',
                            style: const TextStyle(fontSize: 36),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final myData =
                      entries.firstWhere((e) => e.key == _myId!).value;
                  if (!(myData["ready"] ?? false)) {
                    context.read<MatchBloc>().add(
                      MatchReadyPlayer(widget.matchId, _myId!),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                  shadowColor: Colors.yellowAccent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Text('😂', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiParticle {
  final String emoji;
  final double x, y;
  final double speedX, speedY;

  _EmojiParticle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
  });

  factory _EmojiParticle.random() {
    final rnd = Random();
    const emojiOptions = [
      '😎',
      '🤠',
      '🔥',
      '💥',
      '💀',
      '💫',
      '🎯',
      '⚡',
      '🤖',
      '👀',
    ];
    return _EmojiParticle(
      emoji: emojiOptions[rnd.nextInt(emojiOptions.length)],
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      speedX: 0.1 + rnd.nextDouble() * 0.3,
      speedY: 0.1 + rnd.nextDouble() * 0.3,
    );
  }
}

class _EmojiPainter extends CustomPainter {
  final List<_EmojiParticle> emojis;
  final double progress;

  _EmojiPainter(this.emojis, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var e in emojis) {
      final dx = ((e.x + progress * e.speedX) % 1.0) * size.width;
      final dy = ((e.y + progress * e.speedY) % 1.0) * size.height;

      textPainter.text = TextSpan(
        text: e.emoji,
        style: const TextStyle(fontSize: 32),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiPainter oldDelegate) => true;
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
  String? _lastSentPreparedState;

  @override
  void initState() {
    super.initState();
    _sensorSub = accelerometerEventStream().listen((event) {
      final holstered =
          event.x.abs() < 1.5 && event.y < -9 && event.z.abs() < 1.5;
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
        if (state is PrepComplete && _lastSentPreparedState != 'complete') {
          _lastSentPreparedState = 'complete';
          context.read<MatchBloc>().add(
            MatchPlayerPrepared(widget.matchId, widget.myId, true),
          );
        }
        if (state is PrepInterrupted &&
            _lastSentPreparedState != 'interrupted') {
          _lastSentPreparedState = 'interrupted';
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Preparation')),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.pink,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SparklePainter(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Place your phone face-down!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.yellow,
                          offset: Offset(2, 2),
                        ),
                        Shadow(
                          blurRadius: 6,
                          color: Colors.pink,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed:
                        () => context.read<PreparationBloc>().add(PrepSkip()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      elevation: 12,
                      shadowColor: Colors.pinkAccent,
                    ),
                    child: const Text(
                      'Instant Ready',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  BlocBuilder<PreparationBloc, PreparationState>(
                    builder: (context, state) {
                      if (state is PrepIdle || state is PrepInterrupted) {
                        return const Text(
                          'Waiting for you to place phone face-down',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        );
                      }
                      if (state is PrepCounting) {
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: state.progress,
                              minHeight: 20,
                              backgroundColor: Colors.white24,
                              color: Colors.yellowAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${(state.progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      }
                      if (state is PrepComplete) {
                        return const Text(
                          'Ready!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Do not lift your phone until the duel starts!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final List<Offset> _points = List.generate(
    50,
    (_) => Offset(Random().nextDouble(), Random().nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (var p in _points) {
      final dx = p.dx * size.width;
      final dy = p.dy * size.height;
      canvas.drawCircle(Offset(dx, dy), 3 + Random().nextDouble() * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DuelPhase extends StatefulWidget {
  final String matchId;

  const DuelPhase({super.key, required this.matchId});

  @override
  State<DuelPhase> createState() => _DuelPhaseState();
}

class _DuelPhaseState extends State<DuelPhase> {
  StreamSubscription? _sensorSub;
  bool _canShoot = false;
  bool _hasDrawn = false;

  @override
  void initState() {
    super.initState();

    _sensorSub = accelerometerEventStream().listen(_onSensorEvent);
  }

  void _onSensorEvent(AccelerometerEvent event) {
    if (!_canShoot || _hasDrawn) return;

    // Detect upward z-axis movement (draw gun)
    if (event.z > 7.0 && event.x.abs() < 3.0 && event.y.abs() < 3.0) {
      _hasDrawn = true;
      context.read<DuelBloc>().add(DuelShoot(widget.matchId));
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DuelBloc, DuelState>(
      listener: (context, state) async {
        if (state is DuelCanShoot) {
          _canShoot = true;
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 100); // signal that player can draw
          }
        }

        if (state is DuelShot) {
          // feedback for shooting
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 300);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text("Duel")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  !_canShoot
                      ? "Wait for the signal..."
                      : _hasDrawn
                      ? "You drew your gun!"
                      : "Draw when ready!",
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 40),
                LinearProgressIndicator(
                  value: _hasDrawn ? 1 : (_canShoot ? 0.5 : 0),
                  minHeight: 20,
                ),
                const SizedBox(height: 16),
                if (state is DuelShot)
                  const Text(
                    "Waiting for opponent...",
                    style: TextStyle(fontSize: 18),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
