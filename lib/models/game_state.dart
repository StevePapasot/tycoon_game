import 'package:flutter/foundation.dart';

import 'generator.dart';

/// Immutable snapshot of the whole game. Every change produces a new
/// instance via [copyWith] so Riverpod can notify listeners.
@immutable
class GameState {
  const GameState({
    required this.currentCash,
    required this.totalLifetimeCash,
    required this.generators,
  });

  final double currentCash;

  /// Every unit of cash ever earned (spending does not reduce it).
  final double totalLifetimeCash;

  final List<Generator> generators;

  /// Sum of (baseOutput * currentLevel) over all automated generators.
  double get automatedIncomePerSecond => generators
      .where((generator) => generator.isAutomated)
      .fold(0.0, (sum, generator) => sum + generator.outputPerSecond);

  /// Whole seconds away multiplied by automated production per second.
  double offlineEarningsFor(Duration elapsed) {
    final seconds = elapsed.inSeconds;
    if (seconds <= 0) return 0;
    return seconds * automatedIncomePerSecond;
  }

  bool canAfford(Generator generator) => currentCash >= generator.currentCost;

  /// Returns a copy with [amount] added to both current and lifetime cash.
  GameState earn(double amount) => copyWith(
    currentCash: currentCash + amount,
    totalLifetimeCash: totalLifetimeCash + amount,
  );

  GameState copyWith({
    double? currentCash,
    double? totalLifetimeCash,
    List<Generator>? generators,
  }) {
    return GameState(
      currentCash: currentCash ?? this.currentCash,
      totalLifetimeCash: totalLifetimeCash ?? this.totalLifetimeCash,
      generators: generators ?? this.generators,
    );
  }

  Map<String, Object?> toSaveJson() => {
    'currentCash': currentCash,
    'totalLifetimeCash': totalLifetimeCash,
    'generators': [for (final generator in generators) generator.toSaveJson()],
  };

  /// Rebuilds a state from [toSaveJson] output. Generators are taken from
  /// [catalog] (in catalog order) with saved progress applied on top, so
  /// generators added to the catalog after the save start fresh and ones
  /// removed from it are dropped.
  factory GameState.fromSaveJson(
    Map<String, Object?> json, {
    required List<Generator> catalog,
  }) {
    final savedProgress = <String, Map<String, Object?>>{
      for (final entry in json['generators'] as List<Object?>)
        (entry as Map<String, Object?>)['id'] as String: entry,
    };
    return GameState(
      currentCash: (json['currentCash'] as num).toDouble(),
      totalLifetimeCash: (json['totalLifetimeCash'] as num).toDouble(),
      generators: List.unmodifiable([
        for (final generator in catalog)
          if (savedProgress[generator.id] case final progress?)
            generator.withSavedProgress(progress)
          else
            generator,
      ]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.currentCash == currentCash &&
      other.totalLifetimeCash == totalLifetimeCash &&
      listEquals(other.generators, generators);

  @override
  int get hashCode =>
      Object.hash(currentCash, totalLifetimeCash, Object.hashAll(generators));
}
