import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _privacyModeKey = 'privacy_mode_enabled';
  static final ValueNotifier<bool> privacyModeEnabled = ValueNotifier(false);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    privacyModeEnabled.value = preferences.getBool(_privacyModeKey) ?? false;
  }

  static Future<void> setPrivacyModeEnabled(bool enabled) async {
    privacyModeEnabled.value = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyModeKey, enabled);
  }
}
