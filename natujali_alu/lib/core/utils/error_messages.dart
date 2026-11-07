import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../services/cloudinary_service.dart';

/// Turns an error from a save action into a message that says what really
/// went wrong, instead of blaming the network for everything.
///
/// The full error is also printed to the debug console so it can be traced.
String describeError(Object error, {required String action}) {
  debugPrint('Failed to $action: $error');

  if (error is PhotoUploadException) {
    return "Your photo couldn't be uploaded (${error.message}). "
        'Try again, or remove the photo and submit without it.';
  }
  if (error is SocketException || error is TimeoutException) {
    return "Couldn't $action. Check your internet connection and try again.";
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        "Couldn't $action: the database refused it (permission denied). "
            'Make sure your email is verified and the latest Firestore '
            'rules are deployed.',
      'unauthenticated' => 'Your session has ended. Sign in again.',
      'unavailable' || 'deadline-exceeded' =>
        "Couldn't $action. Check your internet connection and try again.",
      _ => "Couldn't $action (${error.code}). Please try again.",
    };
  }
  return "Couldn't $action. Please try again.";
}
