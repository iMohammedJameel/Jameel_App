import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jameel/models/notification_model.dart';

class NotificationsRepository {
  static const int fetchLimit = 50;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      FirebaseFirestore.instance.collection('notifications');

  Stream<List<String>> unreadTypesStream(String employeeId) {
    return _notifications
        .where('employeeId', isEqualTo: employeeId)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => doc.data()['type'] as String? ?? '')
              .toList(),
        );
  }

  Future<List<NotificationModel>> fetchForEmployee(String employeeId) async {
    final snapshot = await _notifications
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .limit(fetchLimit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final rawDate = data['date'];
      return NotificationModel(
        id: doc.id,
        title: data['title'] as String? ?? '',
        message: data['message'] as String? ?? '',
        type: data['type'] as String? ?? '',
        date: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
        isRead: data['isRead'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> markAsRead(String id) =>
      _notifications.doc(id).update({'isRead': true});

  /// Marks all the given notifications as read in one atomic batch (a single
  /// network round-trip instead of one `update` per document).
  Future<void> markManyAsRead(Iterable<String> ids) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.update(_notifications.doc(id), {'isRead': true});
    }
    await batch.commit();
  }
}
