import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/generator.dart';
import '../state/game_notifier.dart';
import 'formatters.dart';

class GeneratorCard extends ConsumerWidget {
  const GeneratorCard({super.key, required this.generator});

  final Generator generator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selecting a bool means the card rebuilds only when affordability
    // flips, not on every 100ms tick.
    final canAfford = ref.watch(
      gameProvider.select((state) => state.canAfford(generator)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    generator.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Level ${generator.currentLevel}'),
                  Text(
                    'Output: ${formatCash(generator.outputPerSecond)}/sec'
                    '${generator.isAutomated ? '' : ' (not automated)'}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: ValueKey('upgrade_${generator.id}'),
              // A null callback renders the button disabled and ignores taps.
              onPressed: canAfford
                  ? () => ref.read(gameProvider.notifier).upgrade(generator.id)
                  : null,
              child: Text(
                'Upgrade\n${formatCash(generator.currentCost)}',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
