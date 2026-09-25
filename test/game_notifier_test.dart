import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tycoon_game/data/initial_game_state.dart';
import 'package:tycoon_game/services/save_repository.dart';
import 'package:tycoon_game/state/core_providers.dart';
import 'package:tycoon_game/state/game_notifier.dart';

Future<ProviderContainer> _container([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer.test(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
}

void main() {
  test('starts with three escalating default generators', () async {
    final container = await _container();
    final state = container.read(gameProvider);

    expect(state.currentCash, startingCash);
    expect(state.totalLifetimeCash, 0);
    expect(state.generators, hasLength(3));
    for (var i = 1; i < state.generators.length; i++) {
      expect(
        state.generators[i].baseCost,
        greaterThan(state.generators[i - 1].baseCost),
      );
      expect(
        state.generators[i].baseOutput,
        greaterThan(state.generators[i - 1].baseOutput),
      );
    }
  });

  test('upgrade deducts the exact cost and adds a level', () async {
    final container = await _container();
    final notifier = container.read(gameProvider.notifier);

    notifier.earn(100);
    final before = container.read(gameProvider);
    final cost = before.generators.first.currentCost;

    expect(notifier.upgrade('tier_1'), isTrue);

    final after = container.read(gameProvider);
    expect(after.currentCash, closeTo(before.currentCash - cost, 1e-9));
    expect(after.totalLifetimeCash, before.totalLifetimeCash);
    expect(after.generators.first.currentLevel, 1);
    expect(after.generators.first.currentCost, closeTo(cost * 1.07, 1e-9));
  });

  test('upgrade is refused when cash is below the cost', () async {
    final container = await _container();
    final before = container.read(gameProvider);

    expect(container.read(gameProvider.notifier).upgrade('tier_2'), isFalse);
    expect(container.read(gameProvider.notifier).upgrade('missing'), isFalse);
    expect(container.read(gameProvider), before);
  });

  test('restores saved progress', () async {
    final container = await _container({
      SaveRepository.gameStateKey:
          '{"currentCash":42.5,"totalLifetimeCash":80,'
          '"generators":[{"id":"tier_2","currentLevel":3,"isAutomated":true}]}',
    });
    final state = container.read(gameProvider);

    expect(state.currentCash, 42.5);
    expect(state.generators[1].currentLevel, 3);
  });

  test('falls back to a new game when the save is corrupt', () async {
    final container = await _container({
      SaveRepository.gameStateKey: 'not json',
    });

    expect(container.read(gameProvider), createInitialGameState());
  });
}
