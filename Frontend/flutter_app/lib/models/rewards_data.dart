import 'package:flutter/material.dart';

class RewardItem {
  final String name;
  final IconData icon;
  final Color color;

  RewardItem({required this.name, required this.icon, required this.color});
}

class RewardsData extends ChangeNotifier {
  final List<RewardItem> _rewards = <RewardItem>[
    RewardItem(name: "50 Points", icon: Icons.control_point, color: Colors.blue),
    RewardItem(name: "Free Coffee", icon: Icons.coffee, color: Colors.green),
    RewardItem(name: "100 Points", icon: Icons.control_point_duplicate, color: Colors.orange),
    RewardItem(name: "Discount Coupon", icon: Icons.local_offer, color: Colors.purple),
    RewardItem(name: "No Reward", icon: Icons.close, color: Colors.grey),
    RewardItem(name: "200 Points", icon: Icons.add_circle, color: Colors.red),
    RewardItem(name: "Exclusive Access", icon: Icons.vpn_key, color: Colors.teal),
    RewardItem(name: "Small Gift", icon: Icons.card_giftcard, color: Colors.pink),
  ];

  RewardItem? _currentReward;
  bool _isSpinning = false;
  double _currentRotation = 0.0;

  List<RewardItem> get rewards => _rewards;
  RewardItem? get currentReward => _currentReward;
  bool get isSpinning => _isSpinning;
  double get currentRotation => _currentRotation;

  void updateRotation(double rotation) {
    _currentRotation = rotation;
    notifyListeners();
  }

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
    notifyListeners();
  }
}