import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rewards_data.dart';
import '../widgets/reward_wheel.dart';

class RewardsAndProgressionPage extends StatelessWidget {
  const RewardsAndProgressionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RewardsData>(
      create: (BuildContext context) => RewardsData(),
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Rewards & Progression")),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.leaderboard,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Your Achievements & Rewards",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Track your journey, celebrate milestones, and claim your well-deserved rewards here!",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  const RewardWheel(),
                  const SizedBox(height: 30),
                  const ListTile(
                    leading: Icon(Icons.military_tech),
                    title: Text("Current Rank: Gold I"),
                    subtitle: Text("Next rank in 250 points"),
                  ),
                  const ListTile(
                    leading: Icon(Icons.star),
                    title: Text("Total Rewards Earned: 15"),
                    subtitle: Text("View your collection"),
                  ),
                  const ListTile(
                    leading: Icon(Icons.trending_up),
                    title: Text("Weekly Progress: +12%"),
                    subtitle: Text("Keep up the great work!"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}