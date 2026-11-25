import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jameel/models/request_model.dart';

class RequestsRepository {
  RequestsRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  /// Default page size for the "recent requests" list.
  static const int recentLimit = 30;

  CollectionReference<Map<String, dynamic>> get _requests =>
      (_firestoreOverride ?? FirebaseFirestore.instance).collection('requests');

  /// Live stream of one employee's requests mapped to [EmployeeRequestModel].
  Stream<List<EmployeeRequestModel>> getRequestsStream(
    String employeeId, {
    String? statusFilter,
    int limit = recentLimit,
  }) {
    Query<Map<String, dynamic>> query = _requests.where(
      'employeeId',
      isEqualTo: employeeId,
    );
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => EmployeeRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Live stream of pending team requests for managers and HR.
  Stream<List<EmployeeRequestModel>> getPendingApprovalsStream({
    int limit = 50,
  }) {
    return _requests
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => EmployeeRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Checks whether [start]..[end] overlaps an existing pending/approved leave.
  Future<bool> hasOverlappingLeave({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _requests
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    for (final doc in snap.docs) {
      final req = EmployeeRequestModel.fromFirestore(doc);
      if (req.type != 'leave') continue;
      if (req.status != 'pending' && req.status != 'approved') continue;
      if (req.startDate == null || req.endDate == null) continue;
      final existingStart = DateTime(
        req.startDate!.year,
        req.startDate!.month,
        req.startDate!.day,
      );
      final existingEnd = DateTime(
        req.endDate!.year,
        req.endDate!.month,
        req.endDate!.day,
      );
      if (!endDay.isBefore(existingStart) && !startDay.isAfter(existingEnd)) {
        return true;
      }
    }
    return false;
  }

  Future<void> submitRequest({
    required String type,
    required String description,
    required String employeeId,
    String? employeeName,
    String? leaveCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
  }) {
    return _requests.add({
      'type': type,
      'description': description,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveCategory': ?leaveCategory,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      'amount': ?amount,
    });
  }

  Future<void> cancelRequest(String requestId) {
    return _requests.doc(requestId).update({'status': 'cancelled'});
  }

  Future<void> reviewRequest({
    required String requestId,
    required String status,
    required String reviewerId,
    String? note,
  }) {
    return _requests.doc(requestId).update({
      'status': status,
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (note != null && note.trim().isNotEmpty) 'reviewNote': note.trim(),
    });
  }
}
