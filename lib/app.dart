import 'package:flutter/material.dart';

import 'ui/game_screen.dart';

class TycoonApp extends StatelessWidget {
  const TycoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idle Tycoon',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: const GameScreen(),
    );
  }
}
