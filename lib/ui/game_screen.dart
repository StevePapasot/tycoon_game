import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offline_earnings.dart';
import '../services/game_lifecycle_controller.dart';
import '../state/game_notifier.dart';
import '../state/offline_earnings_notifier.dart';
import 'formatters.dart';
import 'generator_card.dart';
import 'welcome_back_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Starting can award offline earnings (a provider write) and open the
    // Welcome Back dialog; neither is allowed while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(gameLifecycleControllerProvider).start();
    });
  }

  Future<void> _showWelcomeBack(OfflineEarnings earnings) async {
    await showWelcomeBackDialog(context, earnings);
    if (mounted) ref.read(offlineEarningsProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OfflineEarnings?>(offlineEarningsProvider, (_, earnings) {
      if (earnings != null) _showWelcomeBack(earnings);
    });

    // The generator list only changes on upgrade, so ticks don't rebuild it.
    final generators = ref.watch(
      gameProvider.select((state) => state.generators),
    );

    return Scaffold(
      appBar: AppBar(title: const _CashDisplay()),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: generators.length,
        itemBuilder: (context, index) =>
            GeneratorCard(generator: generators[index]),
      ),
    );
  }
}

class _CashDisplay extends ConsumerWidget {
  const _CashDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = ref.watch(gameProvider.select((state) => state.currentCash));
    final incomePerSecond = ref.watch(
      gameProvider.select((state) => state.automatedIncomePerSecond),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatCash(cash), key: const ValueKey('current_cash')),
        Text(
          '+${formatCash(incomePerSecond)}/sec',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
