import 'package:flutter/material.dart';

class GlobalState with ChangeNotifier {
  bool _isApplianceOn = false;

  bool get isApplianceOn => _isApplianceOn;

  set isApplianceOn(bool newValue) {
    _isApplianceOn = newValue;
    notifyListeners();
  }
}
