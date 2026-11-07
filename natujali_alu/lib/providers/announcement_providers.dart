import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcement_repository.dart';
import '../models/announcement.dart';
import 'auth_providers.dart';

/// Use FakeAnnouncementRepository() here instead to run without Firebase.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => FirestoreAnnouncementRepository(),
);

/// Announcements that haven't expired, kept live. Like reports, they can only
/// be read once someone is signed in and verified.
final activeAnnouncementsProvider = StreamProvider<List<Announcement>>((ref) {
  final user = ref.watch(
    currentUserProvider.select(
      (u) => (uid: u?.uid, verified: u?.emailVerified),
    ),
  );
  if (user.uid == null || user.verified != true) return Stream.value(const []);
  return ref.watch(announcementRepositoryProvider).watchActive();
});

/// Active announcements for one building, including whole-campus ones.
final announcementsForBuildingProvider =
    Provider.family<List<Announcement>, String?>((ref, building) {
      final now = DateTime.now();
      return (ref.watch(activeAnnouncementsProvider).value ?? const [])
          .where((a) => a.isActive(now) && a.appliesTo(building))
          .toList();
    });
