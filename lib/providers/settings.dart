import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderSettings with ChangeNotifier {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<bool> toggleBool(String toToggleName, bool defaultSetting) async {
    // get an up-to-date version of prefs...
    final SharedPreferences prefs = await _prefs;

    // get state of specific setting
    final bool tmpBool = (prefs.getBool(toToggleName) ?? defaultSetting);

    return await prefs.setBool(toToggleName, !tmpBool).then((bool success) {
      return !tmpBool;
    });
  }

  bool showQueue = true;
  void toggleShowQueue() async {
    showQueue = await toggleBool('showQueue', showQueue);
    notifyListeners();
  }

  bool darkMode = false;
  void toggledarkMode() async {
    darkMode = await toggleBool('darkMode', darkMode);
    notifyListeners();
  }

  void init() async {
    showQueue = await _prefs.then((SharedPreferences prefs) {
      return prefs.getBool('showQueue') ?? showQueue;
    });

    darkMode = await _prefs.then((SharedPreferences prefs) {
      return prefs.getBool('darkMode') ?? darkMode;
    });

    notifyListeners();
  }
}
