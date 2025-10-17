import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rewards_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/reward_wheel.dart';

// class to define a level in the progression system.
class Level {
  final int level;
  final String name;
  final int pointsRequired;

  Level(
      {required this.level, required this.name, required this.pointsRequired});
}

class RewardsAndProgressionPage extends StatefulWidget {
  const RewardsAndProgressionPage({super.key});

  @override
  State<RewardsAndProgressionPage> createState() =>
      _RewardsAndProgressionPageState();
}

class _RewardsAndProgressionPageState extends State<RewardsAndProgressionPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Define level progression data
  final List<Level> _levels = [
    Level(level: 1, name: 'Bronze', pointsRequired: 0),
    Level(level: 2, name: 'Silver', pointsRequired: 500),
    Level(level: 3, name: 'Gold', pointsRequired: 1500),
    Level(level: 4, name: 'Platinum', pointsRequired: 3000),
    Level(level: 5, name: 'Diamond', pointsRequired: 5000),
  ];

  // This function handles all levels, including the max level
  Map<String, dynamic> _getLevelData(int points) {
    Level currentLevel = _levels.first;
    for (var level in _levels.reversed) {
      if (points >= level.pointsRequired) {
        currentLevel = level;
        break;
      }
    }

    int nextLevelIndex = currentLevel.level;
    Level? nextLevel =
        (nextLevelIndex < _levels.length) ? _levels[nextLevelIndex] : null;

    if (nextLevel == null) {
      return {
        'currentLevel': currentLevel,
        'nextLevel': null,
        'progress': 1.0,
        'pointsToNextLevel': 0,
      };
    }

    final int pointsInCurrentLevel = points - currentLevel.pointsRequired;
    final int pointsForNextLevel =
        nextLevel.pointsRequired - currentLevel.pointsRequired;
    final double progress = (pointsForNextLevel == 0)
        ? 1.0
        : (pointsInCurrentLevel / pointsForNextLevel);

    return {
      'currentLevel': currentLevel,
      'nextLevel': nextLevel,
      'progress': progress.clamp(0.0, 1.0),
      'pointsToNextLevel': nextLevel.pointsRequired - points,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RewardsData>(
      create: (BuildContext context) => RewardsData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rewards & Progression"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: StreamBuilder<UserModel?>(
          stream: _firestoreService.getUserStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;
            if (user == null) {
              return const Center(child: Text("Could not load user data."));
            }

            // Access data directly from the model
            final int currentPoints = user.points;
            final int spinsAvailable = user.spinsAvailable;

            final levelData = _getLevelData(currentPoints);
            final Level currentLevel = levelData['currentLevel'];
            final int pointsToNextLevel = levelData['pointsToNextLevel'];
            final double progress = levelData['progress'];

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    LevelProgressBar(
                      levelName: currentLevel.name,
                      levelNumber: currentLevel.level,
                      progress: progress,
                      pointsToNextLevel: pointsToNextLevel,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "You have $spinsAvailable spin(s) available. Good luck!",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    RewardWheel(spinsAvailable: spinsAvailable),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// This widget displays the level, rank, and XP bar
class LevelProgressBar extends StatelessWidget {
  final String levelName;
  final int levelNumber;
  final double progress;
  final int pointsToNextLevel;

  const LevelProgressBar({
    super.key,
    required this.levelName,
    required this.levelNumber,
    required this.progress,
    required this.pointsToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  levelName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Level $levelNumber',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                pointsToNextLevel > 0
                    ? '$pointsToNextLevel points to next level'
                    : 'Max Level Reached!',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
