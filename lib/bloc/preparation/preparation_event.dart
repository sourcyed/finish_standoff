sealed class PreparationEvent {}

class PrepSensorTick extends PreparationEvent {
  final bool faceDown;
  PrepSensorTick(this.faceDown);
}

class PrepSkip extends PreparationEvent {}
