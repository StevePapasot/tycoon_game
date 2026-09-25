import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/initial_game_state.dart';
import '../models/game_state.dart';

/// Local persistence for game progress, backed by SharedPreferences.
class SaveRepository {
  SaveRepository(this._preferences);

  static const String gameStateKey = 'game_state';
  static const String lastPlayedTimestampKey = 'last_played_timestamp';

  final SharedPreferences _preferences;

  /// Returns the saved game, or null if there is no save or it can't be read.
  GameState? loadGameState() {
    final raw = _preferences.getString(gameStateKey);
    if (raw == null) return null;
    try {
      return GameState.fromSaveJson(
        jsonDecode(raw) as Map<String, Object?>,
        catalog: defaultGenerators,
      );
    } catch (error) {
      debugPrint('Ignoring unreadable save data: $error');
      return null;
    }
  }

  Future<void> saveGameState(GameState state) =>
      _preferences.setString(gameStateKey, jsonEncode(state.toSaveJson()));

  DateTime? loadLastPlayedTimestamp() {
    final millis = _preferences.getInt(lastPlayedTimestampKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> saveLastPlayedTimestamp(DateTime timestamp) => _preferences
      .setInt(lastPlayedTimestampKey, timestamp.millisecondsSinceEpoch);

  Future<void> clearLastPlayedTimestamp() =>
      _preferences.remove(lastPlayedTimestampKey);
}
