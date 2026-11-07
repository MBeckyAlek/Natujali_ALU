import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'settings_providers.dart';

/// Which side of the app someone signed in to.
enum Portal {
  student('Student'),
  staff('Staff');

  const Portal(this.label);

  final String label;
}

/// How long the app can sit in the background before asking to sign in
/// again, unless "Keep me signed in" was ticked.
const idleTimeout = Duration(minutes: 15);

/// How long a "Keep me signed in" session lasts without being used.
const rememberedSessionLength = Duration(days: 14);

/// Tracks the sign-in session on top of Firebase Auth, which on its own
/// keeps people signed in forever. Sessions end when the app is closed or
/// left in the background past [idleTimeout], unless the person chose to
/// stay signed in. The state is the portal they signed in to.
class SessionNotifier extends Notifier<Portal> {
  static const _portalKey = 'session_portal';
  static const _rememberKey = 'session_remember';
  static const _lastActiveKey = 'session_last_active';

  @override
  Portal build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_portalKey);
    return Portal.values.asNameMap()[saved] ?? Portal.student;
  }

  /// Called just before signing in or registering.
  Future<void> start(Portal portal, {required bool remember}) async {
    state = portal;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_portalKey, portal.name);
    await prefs.setBool(_rememberKey, remember);
    await recordActivity();
  }

  Future<void> recordActivity() => ref
      .read(sharedPreferencesProvider)
      .setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);

  /// Run once at startup: a session that wasn't remembered, or one that has
  /// expired, is signed out so the app opens on the sign-in screen.
  Future<void> enforceOnLaunch() async {
    final remember =
        ref.read(sharedPreferencesProvider).getBool(_rememberKey) ?? false;
    if (!remember || _isIdleFor(rememberedSessionLength)) {
      await end();
    } else {
      await recordActivity();
    }
  }

  /// Run when the app comes back to the foreground.
  Future<void> checkOnResume() async {
    final remember =
        ref.read(sharedPreferencesProvider).getBool(_rememberKey) ?? false;
    final limit = remember ? rememberedSessionLength : idleTimeout;
    if (_isIdleFor(limit)) {
      await end();
    } else {
      await recordActivity();
    }
  }

  Future<void> end() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_rememberKey);
    await prefs.remove(_lastActiveKey);
    await ref.read(authRepositoryProvider).signOut();
  }

  bool _isIdleFor(Duration limit) {
    final saved = ref.read(sharedPreferencesProvider).getInt(_lastActiveKey);
    if (saved == null) return false;
    final lastActive = DateTime.fromMillisecondsSinceEpoch(saved);
    return DateTime.now().difference(lastActive) > limit;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Portal>(
  SessionNotifier.new,
);
