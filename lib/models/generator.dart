import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// A purchasable income source. Static tuning values (costs, outputs) come
/// from the generator catalog; [currentLevel] and [isAutomated] are the
/// player's progress.
@immutable
class Generator {
  const Generator({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.costMultiplier,
    required this.baseOutput,
    required this.currentLevel,
    required this.isAutomated,
  });

  final String id;
  final String name;

  /// Cost of the first level (level 0 -> 1).
  final double baseCost;

  /// Growth factor applied to the cost for every level already owned.
  final double costMultiplier;

  /// Cash produced per second, per level.
  final double baseOutput;

  final int currentLevel;

  /// Only automated generators produce income on ticks and while offline.
  final bool isAutomated;

  /// Price of the next level: baseCost * (costMultiplier ^ currentLevel).
  double get currentCost =>
      baseCost * math.pow(costMultiplier, currentLevel).toDouble();

  /// Cash per second this generator produces at its current level.
  double get outputPerSecond => baseOutput * currentLevel;

  Generator copyWith({int? currentLevel, bool? isAutomated}) {
    return Generator(
      id: id,
      name: name,
      baseCost: baseCost,
      costMultiplier: costMultiplier,
      baseOutput: baseOutput,
      currentLevel: currentLevel ?? this.currentLevel,
      isAutomated: isAutomated ?? this.isAutomated,
    );
  }

  /// Only progress is persisted; tuning values always come from the catalog
  /// so balance changes apply to existing saves.
  Map<String, Object?> toSaveJson() => {
    'id': id,
    'currentLevel': currentLevel,
    'isAutomated': isAutomated,
  };

  /// Applies saved progress (from [toSaveJson]) onto this catalog entry.
  Generator withSavedProgress(Map<String, Object?> json) {
    return copyWith(
      currentLevel: json['currentLevel'] as int,
      isAutomated: json['isAutomated'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Generator &&
      other.id == id &&
      other.name == name &&
      other.baseCost == baseCost &&
      other.costMultiplier == costMultiplier &&
      other.baseOutput == baseOutput &&
      other.currentLevel == currentLevel &&
      other.isAutomated == isAutomated;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseCost,
    costMultiplier,
    baseOutput,
    currentLevel,
    isAutomated,
  );

  @override
  String toString() => 'Generator($id, level $currentLevel)';
}
