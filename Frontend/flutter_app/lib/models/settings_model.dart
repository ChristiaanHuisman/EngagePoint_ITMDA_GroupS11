import 'package:flutter/material.dart';

class SettingsData extends ChangeNotifier {
  bool _receiveNotifications;
  bool _contextNotificationsEnabled;
  bool _suggestedAccountsNotifications;
  bool _rewardsNotifications;
  bool _privateProfile;
  bool _anonymousRewards;
  bool _trackAnalytics;
  bool _darkModeEnabled;

  SettingsData({
    bool receiveNotifications = true,
    bool contextNotificationsEnabled = true,
    bool suggestedAccountsNotifications = true,
    bool rewardsNotifications = true,
    bool privateProfile = false,
    bool anonymousRewards = false,
    bool trackAnalytics = true,
    bool darkModeEnabled = false,
  })  : _receiveNotifications = receiveNotifications,
        _contextNotificationsEnabled = contextNotificationsEnabled,
        _suggestedAccountsNotifications = suggestedAccountsNotifications,
        _rewardsNotifications = rewardsNotifications,
        _privateProfile = privateProfile,
        _anonymousRewards = anonymousRewards,
        _trackAnalytics = trackAnalytics,
        _darkModeEnabled = darkModeEnabled;

  // Getters
  bool get receiveNotifications => _receiveNotifications;
  bool get contextNotificationsEnabled => _contextNotificationsEnabled;
  bool get suggestedAccountsNotifications => _suggestedAccountsNotifications;
  bool get rewardsNotifications => _rewardsNotifications;
  bool get privateProfile => _privateProfile;
  bool get anonymousRewards => _anonymousRewards;
  bool get trackAnalytics => _trackAnalytics;
  bool get darkModeEnabled => _darkModeEnabled;

  // Setters
  set receiveNotifications(bool value) {
    if (_receiveNotifications != value) {
      _receiveNotifications = value;
      notifyListeners();
    }
  }

  set contextNotificationsEnabled(bool value) {
    if (_contextNotificationsEnabled != value) {
      _contextNotificationsEnabled = value;
      notifyListeners();
    }
  }

  set suggestedAccountsNotifications(bool value) {
    if (_suggestedAccountsNotifications != value) {
      _suggestedAccountsNotifications = value;
      notifyListeners();
    }
  }

  set rewardsNotifications(bool value) {
    if (_rewardsNotifications != value) {
      _rewardsNotifications = value;
      notifyListeners();
    }
  }

  set privateProfile(bool value) {
    if (_privateProfile != value) {
      _privateProfile = value;
      notifyListeners();
    }
  }

  set anonymousRewards(bool value) {
    if (_anonymousRewards != value) {
      _anonymousRewards = value;
      notifyListeners();
    }
  }

  set trackAnalytics(bool value) {
    if (_trackAnalytics != value) {
      _trackAnalytics = value;
      notifyListeners();
    }
  }

  set darkModeEnabled(bool value) {
    if (_darkModeEnabled != value) {
      _darkModeEnabled = value;
      notifyListeners();
    }
  }
}