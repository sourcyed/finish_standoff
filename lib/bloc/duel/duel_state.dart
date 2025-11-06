abstract class DuelState {}

class DuelInitial extends DuelState {}

class DuelWaiting extends DuelState {
  final int shootDelay;
  DuelWaiting(this.shootDelay);
}

class DuelCanShoot extends DuelState {}

class DuelShot extends DuelState {}
