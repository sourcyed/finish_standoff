import 'dart:async';
import 'package:finish_standoff/bloc/match/match_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../bloc/preparation/preparation_bloc.dart';
import '../../bloc/preparation/preparation_event.dart';
import '../../bloc/preparation/preparation_state.dart';
import '../../bloc/match/match_bloc.dart';

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
      if (mounted) {
        context.read<PreparationBloc>().add(PrepSensorTick(holstered));
      }
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
              if (kIsWeb)
                ElevatedButton(
                  onPressed:
                      () => context.read<PreparationBloc>().add(PrepSkip()),
                  child: const Text('Instant Ready'),
                ),
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
