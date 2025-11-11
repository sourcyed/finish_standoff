import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../bloc/match/match_bloc.dart';
import '../../bloc/match/match_event.dart';
import '../../data/models/match_model.dart';
import '../../data/player_id.dart';

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
            if (kIsWeb)
              ElevatedButton(
                onPressed: () {
                  if (_hasDrawn) return;
                  _hasDrawn = true;
                  context.read<MatchBloc>().add(
                    MatchShoot(widget.match.matchId, _myId!),
                  );
                },
                child: const Text('Shoot'),
              ),
          ],
        ),
      ),
    );
  }
}
