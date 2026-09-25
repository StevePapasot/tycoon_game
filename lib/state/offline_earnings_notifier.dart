import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offline_earnings.dart';

final offlineEarningsProvider =
    NotifierProvider<OfflineEarningsNotifier, OfflineEarnings?>(
      OfflineEarningsNotifier.new,
    );

/// Holds the latest offline-earnings award until the UI has shown it in the
/// Welcome Back dialog. The cash itself is already in [GameState] by then.
class OfflineEarningsNotifier extends Notifier<OfflineEarnings?> {
  @override
  OfflineEarnings? build() => null;

  void report(OfflineEarnings earnings) => state = earnings;

  void clear() => state = null;
}
