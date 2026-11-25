import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeRequestModel {
  const EmployeeRequestModel({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.employeeId,
    this.employeeName,
    this.leaveCategory,
    this.startDate,
    this.endDate,
    this.amount,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String type;
  final String description;
  final String status;
  final DateTime timestamp;
  final String employeeId;
  final String? employeeName;
  final String? leaveCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? amount;
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';

  factory EmployeeRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['timestamp'];
    final revTs = data['reviewedAt'];
    final rawStart = data['startDate'] as String?;
    final rawEnd = data['endDate'] as String?;

    return EmployeeRequestModel(
      id: doc.id,
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      leaveCategory: data['leaveCategory'] as String?,
      startDate: rawStart != null ? DateTime.tryParse(rawStart) : null,
      endDate: rawEnd != null ? DateTime.tryParse(rawEnd) : null,
      amount: (data['amount'] as num?)?.toDouble(),
      reviewNote: data['reviewNote'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: revTs is Timestamp ? revTs.toDate() : null,
    );
  }
}
