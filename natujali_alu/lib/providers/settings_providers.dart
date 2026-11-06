import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in main() and passed in with an override, so settings can be
/// read synchronously and the app opens with the right theme straight away.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override this in main()'),
);

/// The light/dark choice from Profile → Appearance, saved on the device.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
