import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/initial_game_state.dart';
import '../models/game_state.dart';
import 'core_providers.dart';

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);

/// The single source of truth for game state. All mutations go through here.
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    return ref.watch(saveRepositoryProvider).loadGameState() ??
        createInitialGameState();
  }

  /// Adds [amount] to current and lifetime cash.
  void earn(double amount) {
    if (amount <= 0) return;
    state = state.earn(amount);
  }

  /// Buys one level of the generator with [generatorId]. Returns false (and
  /// changes nothing) if the generator is unknown or unaffordable.
  bool upgrade(String generatorId) {
    final index = state.generators.indexWhere((g) => g.id == generatorId);
    if (index == -1) return false;

    final generator = state.generators[index];
    final cost = generator.currentCost;
    if (state.currentCash < cost) return false;

    final generators = [...state.generators];
    generators[index] = generator.copyWith(
      currentLevel: generator.currentLevel + 1,
    );
    state = state.copyWith(
      currentCash: state.currentCash - cost,
      generators: List.unmodifiable(generators),
    );
    return true;
  }
}
