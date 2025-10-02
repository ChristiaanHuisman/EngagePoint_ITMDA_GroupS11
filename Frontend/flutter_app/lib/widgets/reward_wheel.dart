import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rewards_data.dart';
import 'wheel_painter.dart';

class RewardWheel extends StatefulWidget {
  const RewardWheel({super.key});

  @override
  State<RewardWheel> createState() => _RewardWheelState();
}

class _RewardWheelState extends State<RewardWheel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final Random _random = Random();
  int? _selectedIndexForSpin;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        Provider.of<RewardsData>(context, listen: false).updateRotation(
          _rotationAnimation.value,
        );
      });

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (_selectedIndexForSpin != null) {
          final RewardsData rewardsData = Provider.of<RewardsData>(context, listen: false);
          rewardsData.endSpin(rewardsData.rewards[_selectedIndexForSpin!]);
          _selectedIndexForSpin = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _spinTheWheel() {
    final RewardsData rewardsData = Provider.of<RewardsData>(context, listen: false);
    if (rewardsData.isSpinning) return;

    rewardsData.startSpin();

    final int numRewards = rewardsData.rewards.length;
    final int selectedIndex = _random.nextInt(numRewards);
    _selectedIndexForSpin = selectedIndex;

    final double segmentAngle = 2 * pi / numRewards;
    final double targetRelativeRotation = selectedIndex * segmentAngle;
    final double fullSpins = (_random.nextInt(5) + 5) * (2 * pi).toDouble();
    final double finalRotation = fullSpins + targetRelativeRotation;

    _rotationAnimation = Tween<double>(
      begin: rewardsData.currentRotation,
      end: rewardsData.currentRotation + finalRotation,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Consumer<RewardsData>(
                  builder: (BuildContext context, RewardsData rewards, Widget? child) {
                    return Transform.rotate(
                      angle: rewards.currentRotation,
                      child: CustomPaint(
                        painter: WheelPainter(rewards.rewards),
                        child: Container(),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: -40.0,
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<RewardsData>(
          builder: (BuildContext context, RewardsData rewards, Widget? child) {
            return ElevatedButton.icon(
              icon: rewards.isSpinning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: Text(rewards.isSpinning ? "Spinning..." : "Spin for Reward"),
              onPressed: rewards.isSpinning ? null : _spinTheWheel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Consumer<RewardsData>(
          builder: (BuildContext context, RewardsData rewards, Widget? child) {
            if (rewards.currentReward != null && !rewards.isSpinning) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        rewards.currentReward!.icon,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "You won: ${rewards.currentReward!.name}!",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }
}