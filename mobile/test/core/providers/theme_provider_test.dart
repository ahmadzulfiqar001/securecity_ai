import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securecity_ai/core/providers/app_providers.dart';
import 'package:securecity_ai/core/providers/theme_provider.dart';

void main() {
  group('ThemeModeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
    });

    test('defaults to ThemeMode.dark when no preference is saved', () {
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode updates state and persists through StorageService', () async {
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);

      // A fresh notifier reading from the same persisted prefs should see
      // the saved value, not the ThemeMode.dark default.
      final storageService = container.read(storageServiceProvider);
      expect(storageService.getThemeMode(), ThemeMode.light);
    });
  });
}
