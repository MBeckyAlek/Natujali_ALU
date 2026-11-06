import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/report.dart';
import '../services/cloudinary_service.dart';
import 'report_repository.dart';

/// Incident reports stored in the Firestore `reports` collection.
///
/// Photos are uploaded to Cloudinary first; only their URL is saved here.
class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinary,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cloudinary = cloudinary ?? CloudinaryService();

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  @override
  Stream<List<Report>> watchReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<Report> createReport(
    ReportInput input, {
    required AppUser reporter,
  }) async {
    final doc = _reports.doc();
    final photoUrl = await _uploadIfNeeded(input.photoPath);
    final now = DateTime.now();
    final report = Report(
      id: doc.id,
      // Short code students can quote, taken from the unique document ID.
      reference: 'NJ-${doc.id.substring(0, 6).toUpperCase()}',
      title: input.title,
      description: input.description,
      category: input.category,
      building: input.building,
      landmark: input.landmark,
      photoPath: photoUrl,
      status: ReportStatus.submitted,
      reporterId: reporter.uid,
      createdAt: now,
      updatedAt: now,
      history: [
        StatusUpdate(
          status: ReportStatus.submitted,
          note: 'Your report is safely submitted. We will keep you updated.',
          updatedBy: 'Natujali',
          at: now,
        ),
      ],
    );
    await doc.set(_toMap(report));
    return report;
  }

  @override
  Future<void> updateReport(String reportId, ReportInput input) async {
    final photoUrl = await _uploadIfNeeded(input.photoPath);
    await _reports.doc(reportId).update({
      'title': input.title,
      'description': input.description,
      'category': input.category.name,
      'building': input.building,
      'landmark': input.landmark,
      'photoUrl': photoUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  /// A photo just picked on this device is uploaded and its URL returned.
  /// One that is already a URL (an unchanged photo on an edit) is kept.
  Future<String?> _uploadIfNeeded(String? photoPath) async {
    if (photoPath == null || photoPath.startsWith('http')) return photoPath;
    return _cloudinary.uploadImage(File(photoPath));
  }

  @override
  Future<void> deleteReport(String reportId) => _reports.doc(reportId).delete();

  @override
  Future<void> updateStatus(
    String reportId, {
    required ReportStatus status,
    required String note,
    String? assignedTeam,
  }) async {
    final doc = _reports.doc(reportId);
    final current = await doc.get();
    final team = assignedTeam ?? current.data()?['assignedTeam'] as String?;
    final now = Timestamp.now();
    await doc.update({
      'status': status.name,
      'assignedTeam': team,
      'updatedAt': now,
      // arrayUnion appends without rewriting the existing history.
      'history': FieldValue.arrayUnion([
        {
          'status': status.name,
          'note': note,
          'updatedBy': team ?? campusOperationsName,
          'at': now,
        },
      ]),
    });
  }

  Map<String, dynamic> _toMap(Report report) {
    return {
      'reference': report.reference,
      'title': report.title,
      'description': report.description,
      'category': report.category.name,
      'building': report.building,
      'landmark': report.landmark,
      'photoUrl': report.photoPath,
      'status': report.status.name,
      'reporterId': report.reporterId,
      'assignedTeam': report.assignedTeam,
      'createdAt': Timestamp.fromDate(report.createdAt),
      'updatedAt': Timestamp.fromDate(report.updatedAt),
      'history': [
        for (final update in report.history)
          {
            'status': update.status.name,
            'note': update.note,
            'updatedBy': update.updatedBy,
            'at': Timestamp.fromDate(update.at),
          },
      ],
    };
  }

  Report _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Report(
      id: doc.id,
      reference: data['reference'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: ReportCategory.values.byName(data['category'] as String),
      building: data['building'] as String,
      landmark: data['landmark'] as String? ?? '',
      photoPath: data['photoUrl'] as String?,
      status: ReportStatus.values.byName(data['status'] as String),
      reporterId: data['reporterId'] as String,
      assignedTeam: data['assignedTeam'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      history: [
        for (final entry in data['history'] as List<dynamic>)
          StatusUpdate(
            status: ReportStatus.values.byName(entry['status'] as String),
            note: entry['note'] as String,
            updatedBy: entry['updatedBy'] as String,
            at: (entry['at'] as Timestamp).toDate(),
          ),
      ],
    );
  }
}
