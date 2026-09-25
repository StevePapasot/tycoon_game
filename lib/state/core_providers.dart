import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/save_repository.dart';

/// Loaded asynchronously in `main()` and injected through a ProviderScope
/// override so everything downstream can read saves synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in the ProviderScope.',
  ),
);

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => SaveRepository(ref.watch(sharedPreferencesProvider)),
);

/// Current wall-clock time. Overridable so offline earnings can be tested
/// without waiting for real time to pass.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
