import 'package:flutter/material.dart';

import '../models/offline_earnings.dart';
import 'formatters.dart';

Future<void> showWelcomeBackDialog(
  BuildContext context,
  OfflineEarnings earnings,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Welcome Back!'),
      content: Text(
        'You were away for ${formatDuration(earnings.elapsed)}.\n'
        'Your generators earned ${formatCash(earnings.amount)} while you '
        'were gone.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Collect'),
        ),
      ],
    ),
  );
}
