
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class RewardItem {
  final String name;
  final IconData icon;
  final Color color;
  final int points;

  RewardItem({required this.name, required this.icon, required this.color, this.points = 0});
}

class RewardsData extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  final List<RewardItem> _rewards = <RewardItem>[
    RewardItem(name: "50 Points", icon: Icons.control_point, color: Colors.blue, points: 50),
    RewardItem(name: "100 Points", icon: Icons.control_point_duplicate, color: Colors.orange, points: 100),
    RewardItem(name: "No Reward", icon: Icons.close, color: Colors.grey),
    RewardItem(name: "200 Points", icon: Icons.add_circle, color: Colors.red, points: 200),
    RewardItem(name: "25 Points", icon: Icons.star, color: Colors.teal, points: 25),
    RewardItem(name: "Spin Again", icon: Icons.replay, color: Colors.purple),
    RewardItem(name: "150 Points", icon: Icons.emoji_events, color: Colors.amber, points: 150),
  ];

  RewardItem? _currentReward;
  bool _isSpinning = false;
  

  List<RewardItem> get rewards => _rewards;
  RewardItem? get currentReward => _currentReward;
  bool get isSpinning => _isSpinning;

  void startSpin() {
    if (!_isSpinning) {
      _isSpinning = true;
      _currentReward = null;
      notifyListeners();
    }
  }

  void endSpin(RewardItem selectedReward) {
    _currentReward = selectedReward;
    _isSpinning = false;

    if (selectedReward.points > 0) {
      _firestoreService.updateUserPoints(selectedReward.points);
    }
    
    notifyListeners();
  }
}