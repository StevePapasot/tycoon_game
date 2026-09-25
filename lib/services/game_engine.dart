import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../state/game_notifier.dart';

final gameEngineProvider = Provider<GameEngine>((ref) {
  final engine = GameEngine(ref);
  ref.onDispose(engine.stop);
  return engine;
});

/// The game loop: a periodic timer that pays out automated income in
/// fixed slices while the app is in the foreground.
class GameEngine {
  GameEngine(this._ref);

  static const int tickMilliseconds = 100;
  static const Duration tickInterval = Duration(milliseconds: tickMilliseconds);

  /// 10 ticks per second at a 100ms interval.
  static const int ticksPerSecond =
      Duration.millisecondsPerSecond ~/ tickMilliseconds;

  final Ref _ref;
  Timer? _timer;

  bool get isRunning => _timer != null;

  /// Cash paid out by one tick: automated income per second / ticks per second.
  static double incomePerTick(GameState state) =>
      state.automatedIncomePerSecond / ticksPerSecond;

  void start() {
    if (isRunning) return;
    _timer = Timer.periodic(tickInterval, (_) => tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void tick() {
    _ref
        .read(gameProvider.notifier)
        .earn(incomePerTick(_ref.read(gameProvider)));
  }
}
