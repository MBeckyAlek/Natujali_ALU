import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';

/// Campus announcements posted by staff.
abstract class AnnouncementRepository {
  /// Announcements that haven't expired yet, newest first.
  Stream<List<Announcement>> watchActive();

  /// Staff only.
  Future<void> post({
    required String title,
    required String message,
    required String? building,
    required String postedBy,
    required Duration duration,
  });

  /// Staff only: takes an announcement down before it expires.
  Future<void> remove(String id);
}

/// Announcements stored in the Firestore `announcements` collection.
class FirestoreAnnouncementRepository implements AnnouncementRepository {
  FirestoreAnnouncementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  @override
  Stream<List<Announcement>> watchActive() {
    return _announcements
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_fromDoc).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Future<void> post({
    required String title,
    required String message,
    required String? building,
    required String postedBy,
    required Duration duration,
  }) {
    final now = DateTime.now();
    return _announcements.add({
      'title': title,
      'message': message,
      'building': building,
      'postedBy': postedBy,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(duration)),
    });
  }

  @override
  Future<void> remove(String id) => _announcements.doc(id).delete();

  Announcement _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Announcement(
      id: doc.id,
      title: data['title'] as String,
      message: data['message'] as String? ?? '',
      building: data['building'] as String?,
      postedBy: data['postedBy'] as String? ?? 'Campus operations',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }
}

/// In-memory announcements for tests and running without Firebase.
class FakeAnnouncementRepository implements AnnouncementRepository {
  final _items = <Announcement>[];
  final _controller = StreamController<List<Announcement>>.broadcast();
  int _nextId = 1;

  @override
  Stream<List<Announcement>> watchActive() async* {
    yield _active();
    yield* _controller.stream;
  }

  @override
  Future<void> post({
    required String title,
    required String message,
    required String? building,
    required String postedBy,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    _items.add(
      Announcement(
        id: 'announcement-${_nextId++}',
        title: title,
        message: message,
        building: building,
        postedBy: postedBy,
        createdAt: now,
        expiresAt: now.add(duration),
      ),
    );
    _controller.add(_active());
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
    _controller.add(_active());
  }

  List<Announcement> _active() {
    final now = DateTime.now();
    return _items.where((item) => item.isActive(now)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
