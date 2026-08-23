// Unit tests for the persisted theme choice (Profile → Theme).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:klear/core/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ThemeController.prefs = null;
  });

  test('Defaults to system mode when nothing is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    ThemeController.prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), ThemeMode.system);
  });

  test('setMode persists the choice and restores it in a fresh container',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ThemeController.prefs = prefs;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeControllerProvider.notifier)
        .setMode(ThemeMode.dark);
    expect(container.read(themeControllerProvider), ThemeMode.dark);
    expect(prefs.getString('app_theme'), 'dark');

    // A brand-new container (simulating app restart) picks up the value.
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(container2.read(themeControllerProvider), ThemeMode.dark);

    await container2
        .read(themeControllerProvider.notifier)
        .setMode(ThemeMode.light);
    expect(prefs.getString('app_theme'), 'light');
  });
}
