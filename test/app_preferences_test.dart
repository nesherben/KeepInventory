import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.privacyModeEnabled.value = false;
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
}
