sealed class PreparationState {}

class PrepIdle extends PreparationState {}

class PrepCounting extends PreparationState {
  final double progress;
  PrepCounting(this.progress);
}

class PrepComplete extends PreparationState {}

class PrepInterrupted extends PreparationState {}
