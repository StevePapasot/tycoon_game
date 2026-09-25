import '../models/game_state.dart';
import '../models/generator.dart';

/// Cash a new player starts with: exactly enough for the first Tier 1 level.
const double startingCash = 10;

/// The generator catalog. Each tier costs more, scales faster, and produces
/// more than the previous one.
const List<Generator> defaultGenerators = [
  Generator(
    id: 'tier_1',
    name: 'Tier 1: Lemonade Stand',
    baseCost: 10,
    costMultiplier: 1.07,
    baseOutput: 1,
    currentLevel: 0,
    isAutomated: true,
  ),
  Generator(
    id: 'tier_2',
    name: 'Tier 2: Food Truck',
    baseCost: 150,
    costMultiplier: 1.10,
    baseOutput: 10,
    currentLevel: 0,
    isAutomated: true,
  ),
  Generator(
    id: 'tier_3',
    name: 'Tier 3: Factory',
    baseCost: 2500,
    costMultiplier: 1.13,
    baseOutput: 90,
    currentLevel: 0,
    isAutomated: true,
  ),
];

GameState createInitialGameState() => const GameState(
  currentCash: startingCash,
  totalLifetimeCash: 0,
  generators: defaultGenerators,
);
