import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/settings_providers.dart';
import 'screens/auth/auth_gate.dart';

class NatujaliApp extends ConsumerWidget {
  const NatujaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Natujali',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const AuthGate(),
    );
  }
}
