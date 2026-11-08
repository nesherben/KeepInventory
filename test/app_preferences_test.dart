import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.privacyModeEnabled.value = false;
    AppPreferences.tutorialSeen = false;
  });

  test('loads the saved privacy mode preference', () async {
    SharedPreferences.setMockInitialValues({'privacy_mode_enabled': true});

    await AppPreferences.load();

    expect(AppPreferences.privacyModeEnabled.value, isTrue);
  });

  test('updates listeners and persists privacy mode changes', () async {
    var notifications = 0;
    void listener() => notifications++;
    AppPreferences.privacyModeEnabled.addListener(listener);

    await AppPreferences.setPrivacyModeEnabled(true);

    final preferences = await SharedPreferences.getInstance();
    expect(AppPreferences.privacyModeEnabled.value, isTrue);
    expect(preferences.getBool('privacy_mode_enabled'), isTrue);
    expect(notifications, 1);

    AppPreferences.privacyModeEnabled.removeListener(listener);
  });

  test('tutorial is pending on a fresh install', () async {
    await AppPreferences.load();

    expect(AppPreferences.tutorialSeen, isFalse);
  });

  test('marking the tutorial as seen persists across loads', () async {
    await AppPreferences.markTutorialSeen();
    AppPreferences.tutorialSeen = false;

    await AppPreferences.load();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('tutorial_seen'), isTrue);
    expect(AppPreferences.tutorialSeen, isTrue);
  });
}
