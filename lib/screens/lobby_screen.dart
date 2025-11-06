import 'dart:math';
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

class _LobbyViewState extends State<_LobbyView>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  final List<_FloatingShape> _shapes = List.generate(
    12,
    (_) => _FloatingShape.random(),
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 36,
      color: Colors.orangeAccent,
      shadows: [
        const Shadow(blurRadius: 8, color: Colors.yellow, offset: Offset(2, 2)),
        Shadow(
          blurRadius: 12,
          color: Colors.purpleAccent,
          offset: const Offset(-2, -2),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        backgroundColor: Colors.deepPurpleAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ShapesPainter(_shapes, _animationController.value),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Finish Standoff', style: textStyle),
                    const SizedBox(height: 40),
                    BlocBuilder<MatchFinderBloc, MatchFinderState>(
                      builder: (context, state) {
                        if (state is MatchFinderLoading) {
                          return const CircularProgressIndicator();
                        }

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orangeAccent,
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  hintText: "Enter your name",
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 60),
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 12,
                                shadowColor: Colors.purpleAccent,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }
}

class _FloatingShape {
  final Color color;
  final double size;
  final Offset position;
  final double rotationSpeed;

  _FloatingShape({
    required this.color,
    required this.size,
    required this.position,
    required this.rotationSpeed,
  });

  factory _FloatingShape.random() {
    final rnd = Random();
    return _FloatingShape(
      color: Color.fromARGB(
        255,
        rnd.nextInt(256),
        rnd.nextInt(256),
        rnd.nextInt(256),
      ),
      size: 20 + rnd.nextDouble() * 40,
      position: Offset(rnd.nextDouble(), rnd.nextDouble()),
      rotationSpeed: rnd.nextDouble() * 2 - 1,
    );
  }
}

class _ShapesPainter extends CustomPainter {
  final List<_FloatingShape> shapes;
  final double progress;

  _ShapesPainter(this.shapes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var shape in shapes) {
      final dx =
          (shape.position.dx + progress * shape.rotationSpeed) %
          1.0 *
          size.width;
      final dy =
          (shape.position.dy + progress * shape.rotationSpeed) %
          1.0 *
          size.height;
      paint.color = shape.color.withValues(alpha: 0.7);
      canvas.drawCircle(Offset(dx, dy), shape.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapesPainter oldDelegate) => true;
}
