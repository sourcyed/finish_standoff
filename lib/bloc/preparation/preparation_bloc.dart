import 'package:flutter_bloc/flutter_bloc.dart';
import 'preparation_event.dart';
import 'preparation_state.dart';

class PreparationBloc extends Bloc<PreparationEvent, PreparationState> {
  DateTime? _start;
  final Duration hold = Duration(seconds: 3);

  PreparationBloc() : super(PrepIdle()) {
    on<PrepSensorTick>(_onTick);
    on<PrepSkip>(_onSkip);
  }

  void _onTick(PrepSensorTick event, Emitter<PreparationState> emit) {
    if (event.faceDown) {
      _start ??= DateTime.now();
      final elapsed = DateTime.now().difference(_start!).inMilliseconds;
      final progress = (elapsed / hold.inMilliseconds).clamp(0.0, 1.0);

      if (progress >= 1.0) {
        emit(PrepComplete());
      } else {
        emit(PrepCounting(progress));
      }
    } else if (state is! PrepInterrupted) {
      _start = null;
      emit(PrepInterrupted());
    }
  }

  void _onSkip(PrepSkip event, Emitter<PreparationState> emit) {
    emit(PrepComplete());
  }
}
