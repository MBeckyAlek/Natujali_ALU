/// A notice from campus operations, e.g. "Water off in Social Commons
/// 2–4 pm". Shown to students so they don't report known issues.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.postedBy,
    required this.createdAt,
    required this.expiresAt,
    this.building,
  });

  final String id;
  final String title;
  final String message;

  /// One of `campusBuildings`, or null for the whole campus.
  final String? building;
  final String postedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isActive(DateTime now) => now.isBefore(expiresAt);

  /// Whether this applies to [building], counting whole-campus notices.
  bool appliesTo(String? building) =>
      this.building == null || this.building == building;

  String get audience => building ?? 'Whole campus';
}

/// How long a new announcement stays up.
enum AnnouncementDuration {
  twoHours('2 hours', Duration(hours: 2)),
  sixHours('6 hours', Duration(hours: 6)),
  oneDay('1 day', Duration(days: 1)),
  threeDays('3 days', Duration(days: 3)),
  oneWeek('1 week', Duration(days: 7));

  const AnnouncementDuration(this.label, this.duration);

  final String label;
  final Duration duration;
}
