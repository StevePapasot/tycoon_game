import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offline_earnings.dart';
import '../state/core_providers.dart';
import '../state/game_notifier.dart';
import '../state/offline_earnings_notifier.dart';
import 'game_engine.dart';

final gameLifecycleControllerProvider = Provider<GameLifecycleController>((
  ref,
) {
  final controller = GameLifecycleController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Moves the game between running and paused as the app is foregrounded and
/// backgrounded:
///
/// * [start]: award earnings since the last saved pause (covers cold starts
///   after the OS killed the app), then start the engine.
/// * App paused: stop the engine so time is never counted twice, then save
///   the game and `last_played_timestamp`.
/// * App resumed: award earnings for the time away, then restart the engine.
class GameLifecycleController {
  GameLifecycleController(this._ref);

  final Ref _ref;
  AppLifecycleListener? _listener;

  void start() {
    if (_listener != null) return;
    _listener = AppLifecycleListener(
      onPause: _handlePause,
      onResume: _handleResume,
    );
    _collectOfflineEarnings();
    _ref.read(gameEngineProvider).start();
  }

  void dispose() {
    _listener?.dispose();
    _listener = null;
  }

  void _handlePause() {
    _ref.read(gameEngineProvider).stop();
    final repository = _ref.read(saveRepositoryProvider);
    unawaited(repository.saveGameState(_ref.read(gameProvider)));
    unawaited(repository.saveLastPlayedTimestamp(_ref.read(clockProvider)()));
  }

  void _handleResume() {
    _collectOfflineEarnings();
    _ref.read(gameEngineProvider).start();
  }

  void _collectOfflineEarnings() {
    final repository = _ref.read(saveRepositoryProvider);
    final lastPlayed = repository.loadLastPlayedTimestamp();
    // No timestamp: the app was only briefly inactive (never paused), or
    // this pause has already been paid out.
    if (lastPlayed == null) return;
    // Consume the timestamp so the same absence is never paid twice.
    unawaited(repository.clearLastPlayedTimestamp());

    final elapsed = _ref.read(clockProvider)().difference(lastPlayed);
    final amount = _ref.read(gameProvider).offlineEarningsFor(elapsed);
    if (amount <= 0) return;

    _ref.read(gameProvider.notifier).earn(amount);
    unawaited(repository.saveGameState(_ref.read(gameProvider)));
    _ref
        .read(offlineEarningsProvider.notifier)
        .report(OfflineEarnings(elapsed: elapsed, amount: amount));
  }
}
