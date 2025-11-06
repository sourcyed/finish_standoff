sealed class DuelEvent {}

class DuelStart extends DuelEvent {
  final int shootDelay;
  DuelStart(this.shootDelay);
}

class DuelSignalReceived extends DuelEvent {}

class DuelShoot extends DuelEvent {
  final String matchId;
  DuelShoot(this.matchId);
}
