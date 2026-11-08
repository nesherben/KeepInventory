import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _privacyModeKey = 'privacy_mode_enabled';
  static const _tutorialSeenKey = 'tutorial_seen';
  static final ValueNotifier<bool> privacyModeEnabled = ValueNotifier(false);

  /// Si el usuario ya ha visto (o saltado) el tutorial de bienvenida.
  static bool tutorialSeen = false;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    privacyModeEnabled.value = preferences.getBool(_privacyModeKey) ?? false;
    tutorialSeen = preferences.getBool(_tutorialSeenKey) ?? false;
  }

  static Future<void> setPrivacyModeEnabled(bool enabled) async {
    privacyModeEnabled.value = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyModeKey, enabled);
  }

  static Future<void> markTutorialSeen() async {
    tutorialSeen = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_tutorialSeenKey, true);
  }
}
