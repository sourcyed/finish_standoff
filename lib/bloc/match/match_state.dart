import 'package:finish_standoff/data/models/match_model.dart';

sealed class MatchState {}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchLoaded extends MatchState {
  final MatchModel match;
  MatchLoaded(this.match);
}

class MatchError extends MatchState {
  final String message;
  MatchError(this.message);
}

class MatchReady extends MatchState {}
