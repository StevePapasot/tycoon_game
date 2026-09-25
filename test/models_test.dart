import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tycoon_game/data/initial_game_state.dart';
import 'package:tycoon_game/models/game_state.dart';
import 'package:tycoon_game/models/generator.dart';
import 'package:tycoon_game/services/game_engine.dart';
import 'package:tycoon_game/ui/formatters.dart';

const _tier1 = Generator(
  id: 'a',
  name: 'A',
  baseCost: 10,
  costMultiplier: 1.07,
  baseOutput: 2,
  currentLevel: 0,
  isAutomated: true,
);

void main() {
  group('Generator', () {
    test('currentCost is baseCost * costMultiplier ^ currentLevel', () {
      expect(_tier1.currentCost, 10);
      expect(_tier1.copyWith(currentLevel: 1).currentCost, closeTo(10.7, 1e-9));
      expect(
        _tier1.copyWith(currentLevel: 25).currentCost,
        closeTo(10 * math.pow(1.07, 25), 1e-9),
      );
    });

    test('outputPerSecond is baseOutput * currentLevel', () {
      expect(_tier1.outputPerSecond, 0);
      expect(_tier1.copyWith(currentLevel: 4).outputPerSecond, 8);
    });
  });

  group('GameState', () {
    final state = GameState(
      currentCash: 0,
      totalLifetimeCash: 0,
      generators: [
        _tier1.copyWith(currentLevel: 3), // 6/sec
        _tier1.copyWith(currentLevel: 5, isAutomated: false), // ignored
      ],
    );

    test('automated income only counts automated generators', () {
      expect(state.automatedIncomePerSecond, 6);
    });

    test('a tick pays one tenth of per-second income', () {
      expect(GameEngine.ticksPerSecond, 10);
      expect(GameEngine.incomePerTick(state), closeTo(0.6, 1e-9));
    });

    test('offline earnings are whole seconds times income per second', () {
      expect(state.offlineEarningsFor(const Duration(seconds: 90)), 540);
      expect(state.offlineEarningsFor(const Duration(milliseconds: 1999)), 6);
      expect(state.offlineEarningsFor(const Duration(seconds: -30)), 0);
    });

    test('earn adds to both current and lifetime cash', () {
      final earned = state.earn(5);
      expect(earned.currentCash, 5);
      expect(earned.totalLifetimeCash, 5);
    });

    test('save json round-trips through the catalog', () {
      final progressed = createInitialGameState().copyWith(
        currentCash: 123.45,
        totalLifetimeCash: 999,
        generators: [
          defaultGenerators[0].copyWith(currentLevel: 7),
          defaultGenerators[1].copyWith(currentLevel: 2, isAutomated: false),
          defaultGenerators[2],
        ],
      );
      final restored = GameState.fromSaveJson(
        jsonDecode(jsonEncode(progressed.toSaveJson())) as Map<String, Object?>,
        catalog: defaultGenerators,
      );
      expect(restored, progressed);
    });

    test('loading merges saved progress onto the current catalog', () {
      final restored = GameState.fromSaveJson({
        'currentCash': 1,
        'totalLifetimeCash': 2,
        'generators': [
          {'id': 'tier_1', 'currentLevel': 4, 'isAutomated': true},
          {'id': 'removed_tier', 'currentLevel': 9, 'isAutomated': true},
        ],
      }, catalog: defaultGenerators);

      expect(restored.generators.map((g) => g.id), [
        'tier_1',
        'tier_2',
        'tier_3',
      ]);
      expect(restored.generators[0].currentLevel, 4);
      expect(restored.generators[1], defaultGenerators[1]);
    });
  });

  group('formatCash', () {
    test('groups thousands and shows two decimals', () {
      expect(formatCash(0), r'$0.00');
      expect(formatCash(10.7), r'$10.70');
      expect(formatCash(1234567.891), r'$1,234,567.89');
      expect(formatCash(999.999), r'$1,000.00');
      expect(formatCash(-1500), r'-$1,500.00');
    });
  });
}
