# tycoon_game

An idle tycoon game built with Flutter, using `flutter_riverpod` for state
and `shared_preferences` for local saves. The UI is deliberately plain for
now; the focus is the game state, math and loop.

## Architecture

```
lib/
  main.dart                 Loads SharedPreferences, wraps the app in a ProviderScope
  app.dart                  MaterialApp
  models/
    generator.dart          Generator + currentCost / outputPerSecond formulas
    game_state.dart         Cash, lifetime cash, generators; income + offline math
    offline_earnings.dart   Payload for the Welcome Back dialog
  data/
    initial_game_state.dart Generator catalog (3 tiers) and starting cash
  state/
    core_providers.dart     SharedPreferences, SaveRepository, clock providers
    game_notifier.dart      gameProvider: all state mutations (earn, upgrade)
    offline_earnings_notifier.dart  Pending Welcome Back award for the UI
  services/
    game_engine.dart        100ms periodic tick that pays out automated income
    save_repository.dart    JSON save/load + last_played_timestamp
    game_lifecycle_controller.dart  Pause/resume state machine, offline earnings
  ui/
    game_screen.dart        App bar cash display + generator list
    generator_card.dart     Name, level, output/sec, upgrade button
    welcome_back_dialog.dart
    formatters.dart
```

## Game math

| Quantity | Formula |
| --- | --- |
| Upgrade cost | `baseCost * costMultiplier ^ currentLevel` |
| Generator output/sec | `baseOutput * currentLevel` |
| Income/sec | sum of output/sec over generators where `isAutomated` |
| Income per tick (100ms) | income/sec ÷ 10 |
| Offline earnings | whole seconds away × income/sec |

## Lifecycle

- **Start:** load the save, pay out any earnings since the last saved pause
  (covers the OS killing the app in the background), start the tick.
- **Hidden** (app backgrounded, window minimized, browser tab switched or
  closed): stop the tick (so time is never counted twice), save the game
  and `last_played_timestamp`.
- **Shown again:** pay out seconds elapsed × income/sec, show the Welcome
  Back dialog, restart the tick. The timestamp is consumed so one absence
  is never paid twice.

These hook Flutter's `hidden` state rather than `paused`, because `paused`
is only reported on iOS and Android. On phones `hidden` fires immediately
before `paused`, so behaviour there is the same.

Saves store only progress (cash and each generator's level and automation
flag). Costs and outputs always come from the catalog in
`initial_game_state.dart`, so balance changes apply to existing saves.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
