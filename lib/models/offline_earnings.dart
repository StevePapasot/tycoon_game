import 'package:flutter/foundation.dart';

/// Cash awarded for time spent away from the game.
@immutable
class OfflineEarnings {
  const OfflineEarnings({required this.elapsed, required this.amount});

  final Duration elapsed;
  final double amount;
}
