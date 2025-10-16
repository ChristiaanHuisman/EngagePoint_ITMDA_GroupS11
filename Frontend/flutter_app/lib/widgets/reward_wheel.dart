import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rewards_model.dart';
import 'wheel_painter.dart';

class RewardWheel extends StatefulWidget {
  final int spinsAvailable;
  const RewardWheel({super.key, this.spinsAvailable = 0});

  @override
  State<RewardWheel> createState() => _RewardWheelState();
}

class _RewardWheelState extends State<RewardWheel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final Random _random = Random();
  
  // THE FIX: The widget now manages its own angle state locally.
  double _currentAngle = 0.0;
  int? _selectedIndexForSpin;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // A slightly longer, smoother spin
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.decelerate),
    );

    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (_selectedIndexForSpin != null) {
          final rewardsData = Provider.of<RewardsData>(context, listen: false);
          rewardsData.endSpin(rewardsData.rewards[_selectedIndexForSpin!]);
          // Save the final angle for the next spin and normalize it
          setState(() {
            _currentAngle = _rotationAnimation.value % (2 * pi);
          });
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
    final rewardsData = Provider.of<RewardsData>(context, listen: false);
    if (rewardsData.isSpinning || widget.spinsAvailable <= 0) return;

    rewardsData.startSpin();

    final int numRewards = rewardsData.rewards.length;
    final int selectedIndex = _random.nextInt(numRewards);
    _selectedIndexForSpin = selectedIndex;

    // 1. Calculate the final absolute angle for the middle of the winning segment.
    final double targetAngle = (2 * pi * selectedIndex / numRewards);

    // 2. Add a random number of full spins for effect.
    final double randomSpins = (_random.nextInt(4) + 5) * 2 * pi;
    
    // 3. The final angle is the combination of spins and the target offset.
    // We subtract the target so it lands under the top pointer.
    final double endAngle = randomSpins - targetAngle;
    
    // Ensure the wheel always spins forward from its current position
    final double beginAngle = _currentAngle;

    _rotationAnimation = Tween<double>(
      begin: beginAngle,
      end: beginAngle + endAngle,
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
               // Using AnimatedBuilder to handle the rotation directly.
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    );
                  },
                  child: CustomPaint(
                    painter: WheelPainter(context.read<RewardsData>().rewards),
                    child: Container(),
                  ),
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
            final bool canSpin = !rewards.isSpinning && widget.spinsAvailable > 0;
            return ElevatedButton.icon(
              icon: rewards.isSpinning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: Text(rewards.isSpinning ? "Spinning..." : "Spin for Reward"),
              onPressed: canSpin ? _spinTheWheel : null,
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