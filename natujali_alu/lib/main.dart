import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/session_providers.dart';
import 'providers/settings_providers.dart';

Future<void> main() async {
  // Firebase must be ready before any screen talks to Auth or Firestore.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final preferences = await SharedPreferences.getInstance();

  // Use Android's own photo picker (Photos and Albums tabs) for "Choose photo".
  final imagePicker = ImagePickerPlatform.instance;
  if (imagePicker is ImagePickerAndroid) {
    imagePicker.useAndroidPhotoPicker = true;
  }

  // The container holds the state of every Riverpod provider in the app.
  // It is created here so the session can be checked before the first frame.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  await container.read(sessionProvider.notifier).enforceOnLaunch();

  runApp(
    UncontrolledProviderScope(container: container, child: const NatujaliApp()),
  );
}
