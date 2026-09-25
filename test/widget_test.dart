import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tycoon_game/app.dart';
import 'package:tycoon_game/services/save_repository.dart';
import 'package:tycoon_game/state/core_providers.dart';

late SharedPreferences preferences;
late DateTime now;

Future<void> pumpGame(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const TycoonApp(),
    ),
  );
  // Let the post-frame lifecycle start (and any Welcome Back dialog) run.
  await tester.pump();
}

Future<void> sendLifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states,
) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Future<void> backgroundApp(WidgetTester tester) => sendLifecycle(tester, [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
]);

Future<void> foregroundApp(WidgetTester tester) => sendLifecycle(tester, [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
]);

String cashText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('current_cash'))).data!;

Finder inDialog(String text) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.textContaining(text),
);

FilledButton upgradeButton(WidgetTester tester, String id) =>
    tester.widget<FilledButton>(find.byKey(ValueKey('upgrade_$id')));

void main() {
  setUp(() => now = DateTime(2026, 1, 1, 12));

  testWidgets('shows cash in the app bar and a card per generator', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(cashText(tester), r'$10.00');
    expect(find.text('Tier 1: Lemonade Stand'), findsOneWidget);
    expect(find.text('Tier 2: Food Truck'), findsOneWidget);
    expect(find.text('Tier 3: Factory'), findsOneWidget);
    expect(find.text('Level 0'), findsNWidgets(3));
    expect(find.text(r'Output: $0.00/sec'), findsNWidgets(3));
  });

  testWidgets('upgrade buttons show the exact cost and disable when '
      'unaffordable', (tester) async {
    await pumpGame(tester);

    expect(find.text('Upgrade\n\$10.00'), findsOneWidget);
    expect(find.text('Upgrade\n\$150.00'), findsOneWidget);
    expect(find.text('Upgrade\n\$2,500.00'), findsOneWidget);

    expect(upgradeButton(tester, 'tier_1').enabled, isTrue);
    expect(upgradeButton(tester, 'tier_2').enabled, isFalse);
    expect(upgradeButton(tester, 'tier_3').enabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('upgrade_tier_2')));
    await tester.pump();
    expect(find.text('Level 0'), findsNWidgets(3));
    expect(cashText(tester), r'$10.00');
  });

  testWidgets('upgrading starts automated income on the 100ms tick', (
    tester,
  ) async {
    await pumpGame(tester);

    await tester.tap(find.byKey(const ValueKey('upgrade_tier_1')));
    await tester.pump();

    expect(cashText(tester), r'$0.00');
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text(r'Output: $1.00/sec'), findsOneWidget);
    expect(find.text('Upgrade\n\$10.70'), findsOneWidget);
    expect(upgradeButton(tester, 'tier_1').enabled, isFalse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(cashText(tester), r'$0.10');

    await tester.pump(const Duration(milliseconds: 900));
    expect(cashText(tester), r'$1.00');

    await tester.pump(const Duration(seconds: 10));
    expect(cashText(tester), r'$11.00');
    expect(upgradeButton(tester, 'tier_1').enabled, isTrue);
  });

  testWidgets('pausing saves; resuming awards offline earnings and shows '
      'Welcome Back', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byKey(const ValueKey('upgrade_tier_1')));
    await tester.pump();

    await backgroundApp(tester);
    expect(
      preferences.getInt(SaveRepository.lastPlayedTimestampKey),
      now.millisecondsSinceEpoch,
    );
    final saved =
        jsonDecode(preferences.getString(SaveRepository.gameStateKey)!)
            as Map<String, Object?>;
    expect((saved['generators'] as List).first, {
      'id': 'tier_1',
      'currentLevel': 1,
      'isAutomated': true,
    });

    // The tick engine is stopped while paused, so time isn't counted twice.
    await tester.pump(const Duration(seconds: 5));
    expect(cashText(tester), r'$0.00');

    now = now.add(const Duration(hours: 1));
    await foregroundApp(tester);

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(inDialog('1h 0m 0s'), findsOneWidget);
    expect(inDialog(r'$3,600.00'), findsOneWidget);
    expect(cashText(tester), r'$3,600.00');
    expect(preferences.getInt(SaveRepository.lastPlayedTimestampKey), isNull);

    await tester.tap(find.text('Collect'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsNothing);

    // Ticking resumed after returning (it also ran during the dialog's
    // closing animation, so compare against the post-dismiss balance).
    double cash() =>
        double.parse(cashText(tester).replaceAll(RegExp(r'[$,]'), ''));
    final afterDismiss = cash();
    expect(afterDismiss, greaterThan(3600));
    await tester.pump(const Duration(seconds: 1));
    expect(cash(), closeTo(afterDismiss + 1, 0.001));
  });

  testWidgets('cold start after being killed in the background awards '
      'offline earnings', (tester) async {
    await pumpGame(
      tester,
      saved: {
        SaveRepository.gameStateKey: jsonEncode({
          'currentCash': 5,
          'totalLifetimeCash': 50,
          'generators': [
            {'id': 'tier_1', 'currentLevel': 2, 'isAutomated': true},
          ],
        }),
        SaveRepository.lastPlayedTimestampKey: now
            .subtract(const Duration(seconds: 90))
            .millisecondsSinceEpoch,
      },
    );

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(inDialog('1m 30s'), findsOneWidget);
    expect(inDialog(r'$180.00'), findsOneWidget);
    expect(cashText(tester), r'$185.00');
  });

  testWidgets('resuming without a pause awards nothing', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byKey(const ValueKey('upgrade_tier_1')));
    await tester.pump();

    now = now.add(const Duration(hours: 1));
    await sendLifecycle(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    expect(find.text('Welcome Back!'), findsNothing);
    expect(cashText(tester), r'$0.00');
  });
}
