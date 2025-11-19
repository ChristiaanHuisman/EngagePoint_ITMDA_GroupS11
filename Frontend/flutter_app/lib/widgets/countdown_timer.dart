import 'dart:async';
import 'package:flutter/material.dart';

class SpinCountdown extends StatefulWidget {
  final DateTime targetDate;
  final VoidCallback onTimerFinished;

  const SpinCountdown({
    super.key, 
    required this.targetDate, 
    required this.onTimerFinished
  });

  @override
  State<SpinCountdown> createState() => _SpinCountdownState();
}

class _SpinCountdownState extends State<SpinCountdown> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (now.isAfter(widget.targetDate)) {
      _timer.cancel();
      widget.onTimerFinished(); 
    } else {
      setState(() {
        _timeLeft = widget.targetDate.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "Next spin in: $hours:$minutes:$seconds",
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey
            ),
          ),
        ],
      ),
    );
  }
}