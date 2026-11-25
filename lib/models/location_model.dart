import 'package:cloud_firestore/cloud_firestore.dart';

class LocationCheckInModel {
  const LocationCheckInModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.type = 'check_in',
    this.address,
    this.siteName,
    this.isSynced = true,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String type;
  final String? address;
  final String? siteName;
  final bool isSynced;

  bool get isCheckOut => type == 'check_out';

  factory LocationCheckInModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final capturedRaw = data['capturedAt'] as String?;
    final capturedTs =
        capturedRaw != null ? DateTime.tryParse(capturedRaw)?.toLocal() : null;
    final ts = data['timestamp'];
    return LocationCheckInModel(
      id: doc.id,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: capturedTs ?? (ts is Timestamp ? ts.toDate() : DateTime.now()),
      type: data['type'] as String? ?? 'check_in',
      address: data['address'] as String?,
      siteName: data['siteName'] as String?,
      isSynced: true,
    );
  }

  factory LocationCheckInModel.fromLocalMap(String id, Map<String, dynamic> map) {
    final rawTs = map['capturedAt'] as String?;
    return LocationCheckInModel(
      id: id,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp:
          (rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null) ??
              DateTime.now(),
      type: map['type'] as String? ?? 'check_in',
      address: map['address'] as String?,
      siteName: map['siteName'] as String?,
      isSynced: false,
    );
  }
}
